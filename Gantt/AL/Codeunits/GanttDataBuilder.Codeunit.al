codeunit 71891733 "DGOG Gantt Data Builder"
{
    procedure BuildPayload(SetupId: Integer; RequestedViewCode: Code[20]; ContextKey: Text): Text
    var
        GanttSetup: Record "DGOG Gantt Setup";
        GanttView: Record "DGOG Gantt View";
        RootJson: JsonObject;
        SetupJson: JsonObject;
        ActiveViewJson: JsonObject;
        ViewsJson: JsonArray;
        RowsJson: JsonArray;
        BarsJson: JsonArray;
        DependenciesJson: JsonArray;
        AggregatesJson: JsonArray;
        MappingLinesJson: JsonArray;
        PayloadText: Text;
        RangeStart: DateTime;
        RangeEnd: DateTime;
        EffectiveViewCode: Code[20];
    begin
        GanttSetup.Get(SetupId);
        ValidationHelper.ValidateSetup(GanttSetup);

        EffectiveViewCode := ValidationHelper.ResolveViewCode(SetupId, RequestedViewCode);
        if EffectiveViewCode = '' then
            Error('No view is configured for setup %1.', SetupId);

        GanttView.Get(SetupId, EffectiveViewCode);

        BuildSetupJson(GanttSetup, GanttView, ContextKey, SetupJson, ActiveViewJson);
        BuildViewsJson(SetupId, ViewsJson);
        BuildMappingLinesJson(SetupId, EffectiveViewCode, MappingLinesJson);
        BuildRuntimeArrays(GanttSetup, GanttView, RowsJson, BarsJson, DependenciesJson, AggregatesJson, RangeStart, RangeEnd);

        RootJson.Add('setup', SetupJson);
        RootJson.Add('activeView', ActiveViewJson);
        RootJson.Add('views', ViewsJson);
        RootJson.Add('mappingLines', MappingLinesJson);
        RootJson.Add('rows', RowsJson);
        RootJson.Add('bars', BarsJson);
        RootJson.Add('dependencies', DependenciesJson);
        RootJson.Add('aggregates', AggregatesJson);
        RootJson.Add('rangeStart', Format(RangeStart, 0, 9));
        RootJson.Add('rangeEnd', Format(RangeEnd, 0, 9));
        RootJson.WriteTo(PayloadText);

        exit(PayloadText);
    end;

    var
        ValidationHelper: Codeunit "DGOG Gantt Validation Helper";

    local procedure BuildSetupJson(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View"; ContextKey: Text; var SetupJson: JsonObject; var ActiveViewJson: JsonObject)
    begin
        SetupJson.Add('setupId', GanttSetup."ID");
        SetupJson.Add('name', GanttSetup."Name");
        SetupJson.Add('description', GanttSetup."Description");
        SetupJson.Add('defaultZoom', GanttSetup."Default Zoom %");
        SetupJson.Add('defaultTimeGrain', Format(GanttSetup."Default Time Grain"));
        SetupJson.Add('allowEdit', GanttSetup."Allow Edit");
        SetupJson.Add('allowSave', GanttSetup."Allow Save");
        SetupJson.Add('enableDependencies', GanttSetup."Enable Dependencies");
        SetupJson.Add('enableAggregation', GanttSetup."Enable Aggregation");
        SetupJson.Add('enableConflictDetection', GanttSetup."Enable Conflict Detection");
        SetupJson.Add('enableViewSwitching', GanttSetup."Enable View Switching");
        SetupJson.Add('highestParentCardPageId', GanttSetup."Highest Parent Card Page ID");
        SetupJson.Add('focusContextKey', ContextKey);

        ActiveViewJson.Add('viewCode', GanttView."View Code");
        ActiveViewJson.Add('name', GanttView."Name");
        ActiveViewJson.Add('aggregationEnabled', GanttView."Aggregation Enabled");
        ActiveViewJson.Add('dependencyEnabled', GanttView."Dependency Enabled");
        ActiveViewJson.Add('conflictDetectionEnabled', GanttView."Conflict Detection Enabled");
    end;

    local procedure BuildViewsJson(SetupId: Integer; var ViewsJson: JsonArray)
    var
        GanttView: Record "DGOG Gantt View";
        ViewJson: JsonObject;
    begin
        GanttView.SetRange("Setup ID", SetupId);
        GanttView.SetCurrentKey("Setup ID", Sequence);
        if not GanttView.FindSet() then
            exit;

        repeat
            Clear(ViewJson);
            ViewJson.Add('viewCode', GanttView."View Code");
            ViewJson.Add('name', GanttView."Name");
            ViewJson.Add('isDefault', GanttView."Is Default");
            ViewJson.Add('sequence', GanttView.Sequence);
            ViewsJson.Add(ViewJson);
        until GanttView.Next() = 0;
    end;

    local procedure BuildMappingLinesJson(SetupId: Integer; ViewCode: Code[20]; var MappingLinesJson: JsonArray)
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
        MappingLineJson: JsonObject;
        GroupingLinesJson: JsonArray;
    begin
        MappingLine.SetRange("Setup ID", SetupId);
        MappingLine.SetRange("View Code", ViewCode);
        if not MappingLine.FindSet() then
            exit;

        repeat
            Clear(MappingLineJson);
            Clear(GroupingLinesJson);
            BuildGroupingLinesJson(MappingLine, GroupingLinesJson);
            MappingLineJson.Add('lineNo', MappingLine."Line No.");
            MappingLineJson.Add('startDateFieldId', MappingLine."Start Date Field ID");
            MappingLineJson.Add('endDateFieldId', MappingLine."End Date Field ID");
            MappingLineJson.Add('groupingLines', GroupingLinesJson);
            MappingLinesJson.Add(MappingLineJson);
        until MappingLine.Next() = 0;
    end;

    local procedure BuildRuntimeArrays(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View"; var RowsJson: JsonArray; var BarsJson: JsonArray; var DependenciesJson: JsonArray; var AggregatesJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime)
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
        AddedDependencyIds: Dictionary of [Text, Boolean];
        VisibleBarKeys: Dictionary of [Text, Boolean];
        DummyParentSourceRef: RecordRef;
    begin
        RangeStart := CreateDateTime(CalcDate('<-7D>', WorkDate()), 0T);
        RangeEnd := CreateDateTime(CalcDate('<+30D>', WorkDate()), 235959T);

        if GanttView."Root Mapping Line No." <> 0 then begin
            if MappingLine.Get(GanttSetup."ID", GanttView."View Code", GanttView."Root Mapping Line No.") then
                AppendRecordsForMapping(GanttSetup, GanttView, MappingLine, DummyParentSourceRef, '', 0, RowsJson, BarsJson, RangeStart, RangeEnd, VisibleBarKeys);
            BuildDependenciesForView(GanttView, DependenciesJson, AddedDependencyIds, VisibleBarKeys);
            exit;
        end;

        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        MappingLine.SetRange("View Code", GanttView."View Code");
        MappingLine.SetRange("Parent Line No.", 0);
        if not MappingLine.FindSet() then
            exit;

        repeat
            AppendRecordsForMapping(GanttSetup, GanttView, MappingLine, DummyParentSourceRef, '', 0, RowsJson, BarsJson, RangeStart, RangeEnd, VisibleBarKeys);
        until MappingLine.Next() = 0;

        BuildDependenciesForView(GanttView, DependenciesJson, AddedDependencyIds, VisibleBarKeys);
    end;

    local procedure AppendRecordsForMapping(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View"; MappingLine: Record "DGOG Gantt Mapping Line"; ParentSourceRef: RecordRef; ParentRowId: Text; Level: Integer; var RowsJson: JsonArray; var BarsJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime; var VisibleBarKeys: Dictionary of [Text, Boolean])
    var
        SourceRef: RecordRef;
        RowJson: JsonObject;
        BarJson: JsonObject;
        CurrentRowId: Text;
        CurrentDependencyKey: Text;
        HasChildren: Boolean;
        StartValue: DateTime;
        EndValue: DateTime;
    begin
        SourceRef.Open(MappingLine."Source Table ID");
        if not ApplyParentFieldFilters(SourceRef, MappingLine, ParentSourceRef) then
            exit;

        if not SourceRef.FindSet() then
            exit;

        HasChildren := HasChildMapping(GanttSetup."ID", GanttView."View Code", MappingLine."Line No.");

        repeat
            Clear(RowJson);
            CurrentRowId := GetStableRowId(GanttView."View Code", MappingLine."Line No.", SourceRef.RecordId);
            BuildRowJson(SourceRef, MappingLine, GanttView."View Code", CurrentRowId, ParentRowId, Level, HasChildren, RowJson);
            RowsJson.Add(RowJson);

            if HasBar(MappingLine) then begin
                Clear(BarJson);
                BuildBarJson(SourceRef, MappingLine, CurrentRowId, Level, BarJson, StartValue, EndValue);
                if StartValue <> 0DT then begin
                    BarsJson.Add(BarJson);
                    UpdateRange(StartValue, EndValue, RangeStart, RangeEnd);
                    CurrentDependencyKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID");
                    if CurrentDependencyKey <> '' then
                        if not VisibleBarKeys.ContainsKey(GetVisibleDependencyKey(MappingLine."Line No.", CurrentDependencyKey)) then
                            VisibleBarKeys.Add(GetVisibleDependencyKey(MappingLine."Line No.", CurrentDependencyKey), true);
                end;
            end;

            if HasChildren then
                AppendChildMappings(GanttSetup, GanttView, MappingLine."Line No.", SourceRef, CurrentRowId, Level + 1, RowsJson, BarsJson, RangeStart, RangeEnd, VisibleBarKeys);
        until SourceRef.Next() = 0;
    end;

    local procedure AppendChildMappings(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View"; ParentLineNo: Integer; ParentSourceRef: RecordRef; ParentRowId: Text; Level: Integer; var RowsJson: JsonArray; var BarsJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime; var VisibleBarKeys: Dictionary of [Text, Boolean])
    var
        ChildMapping: Record "DGOG Gantt Mapping Line";
    begin
        ChildMapping.SetRange("Setup ID", GanttSetup."ID");
        ChildMapping.SetRange("View Code", GanttView."View Code");
        ChildMapping.SetRange("Parent Line No.", ParentLineNo);
        if not ChildMapping.FindSet() then
            exit;

        repeat
            AppendRecordsForMapping(GanttSetup, GanttView, ChildMapping, ParentSourceRef, ParentRowId, Level, RowsJson, BarsJson, RangeStart, RangeEnd, VisibleBarKeys);
        until ChildMapping.Next() = 0;
    end;

    local procedure BuildRowJson(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"; ViewCode: Code[20]; RowId: Text; ParentRowId: Text; Level: Integer; HasChildren: Boolean; var RowJson: JsonObject)
    var
        TooltipFields: JsonArray;
        TooltipTitle: Text;
        GroupingPathJson: JsonArray;
    begin
        TooltipTitle := ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Tooltip Title Field ID");

        RowJson.Add('rowId', RowId);
        RowJson.Add('parentRowId', ParentRowId);
        RowJson.Add('viewCode', ViewCode);
        RowJson.Add('mappingLineNo', MappingLine."Line No.");
        RowJson.Add('sourceTableId', MappingLine."Source Table ID");
        RowJson.Add('sourceRecordId', Format(SourceRef.RecordId));
        RowJson.Add('keyText', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID"));
        RowJson.Add('descriptionText', ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Description Field ID"));
        RowJson.Add('level', Level);
        RowJson.Add('hasChildren', HasChildren and MappingLine."Is Expandable");
        RowJson.Add('isExpanded', false);
        RowJson.Add('isEditable', MappingLine."Is Editable");
        RowJson.Add('statusValue', ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Status Field ID"));
        RowJson.Add('colorValue', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Color Override Field ID"));
        RowJson.Add('conflictGroupKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Conflict Group Field ID"));
        RowJson.Add('resourceKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Resource Group Field ID"));
        RowJson.Add('contextKey', GetContextKey(SourceRef, MappingLine));
        RowJson.Add('sequenceValue', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Sequence Field ID"));
        RowJson.Add('tooltipTitle', TooltipTitle);

        BuildGroupingPathJson(SourceRef, MappingLine, GroupingPathJson);
        RowJson.Add('groupingPath', GroupingPathJson);

        BuildTooltipFields(SourceRef, MappingLine, TooltipFields);
        RowJson.Add('tooltipFields', TooltipFields);
    end;

    local procedure BuildGroupingLinesJson(MappingLine: Record "DGOG Gantt Mapping Line"; var GroupingLinesJson: JsonArray)
    var
        GroupingLine: Record "DGOG Gantt Grouping Line";
        GroupingLineJson: JsonObject;
    begin
        GroupingLine.SetRange("Setup ID", MappingLine."Setup ID");
        GroupingLine.SetRange("View Code", MappingLine."View Code");
        GroupingLine.SetRange("Mapping Line No.", MappingLine."Line No.");
        GroupingLine.SetCurrentKey("Setup ID", "View Code", "Mapping Line No.", "Line No.");
        if not GroupingLine.FindSet() then
            exit;

        repeat
            Clear(GroupingLineJson);
            GroupingLineJson.Add('lineNo', GroupingLine."Line No.");
            GroupingLineJson.Add('fieldId', GroupingLine."Group Field ID");
            GroupingLineJson.Add('fieldCaption', ValidationHelper.GetFieldCaption(MappingLine."Source Table ID", GroupingLine."Group Field ID"));
            GroupingLinesJson.Add(GroupingLineJson);
        until GroupingLine.Next() = 0;
    end;

    local procedure BuildGroupingPathJson(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"; var GroupingPathJson: JsonArray)
    var
        GroupingLine: Record "DGOG Gantt Grouping Line";
        GroupJson: JsonObject;
        GroupValueText: Text;
        GroupDisplayText: Text;
    begin
        GroupingLine.SetRange("Setup ID", MappingLine."Setup ID");
        GroupingLine.SetRange("View Code", MappingLine."View Code");
        GroupingLine.SetRange("Mapping Line No.", MappingLine."Line No.");
        GroupingLine.SetCurrentKey("Setup ID", "View Code", "Mapping Line No.", "Line No.");
        if not GroupingLine.FindSet() then
            exit;

        repeat
            GroupValueText := ValidationHelper.GetFieldValueAsText(SourceRef, GroupingLine."Group Field ID");
            GroupDisplayText := ValidationHelper.GetFieldValueAsDisplayText(SourceRef, GroupingLine."Group Field ID");
            if GroupDisplayText = '' then
                GroupDisplayText := '(Blank)';

            Clear(GroupJson);
            GroupJson.Add('lineNo', GroupingLine."Line No.");
            GroupJson.Add('fieldId', GroupingLine."Group Field ID");
            GroupJson.Add('fieldCaption', ValidationHelper.GetFieldCaption(MappingLine."Source Table ID", GroupingLine."Group Field ID"));
            GroupJson.Add('value', GroupValueText);
            GroupJson.Add('displayValue', GroupDisplayText);
            GroupJson.Add('key', StrSubstNo('%1|%2', GroupingLine."Group Field ID", GroupValueText));
            GroupingPathJson.Add(GroupJson);
        until GroupingLine.Next() = 0;
    end;

    local procedure BuildBarJson(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"; RowId: Text; Level: Integer; var BarJson: JsonObject; var StartValue: DateTime; var EndValue: DateTime)
    var
        LabelText: Text;
        StatusText: Text;
        ColorText: Text;
        TrackColorText: Text;
        DueValue: DateTime;
        ProgressPercent: Decimal;
    begin
        StartValue := ValidationHelper.GetFieldDateTime(SourceRef, MappingLine."Start Date Field ID");
        EndValue := ValidationHelper.GetFieldDateTime(SourceRef, MappingLine."End Date Field ID");
        if (StartValue = 0DT) or (EndValue = 0DT) then
            exit;

        StatusText := ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Status Field ID");
        ColorText := ResolveBarColor(StatusText, ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Color Override Field ID"));
        TrackColorText := ResolveTrackColor(StatusText);
        LabelText := ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Label Override Field ID");
        if LabelText = '' then
            LabelText := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID");
        DueValue := ValidationHelper.GetFieldDateTime(SourceRef, MappingLine."Due Date Field ID");
        ProgressPercent := ResolveProgressPercent(SourceRef, MappingLine);

        BarJson.Add('barId', GetStableBarId(MappingLine."Line No.", SourceRef.RecordId));
        BarJson.Add('rowId', RowId);
        BarJson.Add('mappingLineNo', MappingLine."Line No.");
        BarJson.Add('sourceTableId', MappingLine."Source Table ID");
        BarJson.Add('sourceRecordId', Format(SourceRef.RecordId));
        BarJson.Add('pageId', MappingLine."Card Page ID");
        BarJson.Add('start', Format(StartValue, 0, 9));
        BarJson.Add('end', Format(EndValue, 0, 9));
        BarJson.Add('due', Format(DueValue, 0, 9));
        BarJson.Add('progressPercent', ProgressPercent);
        BarJson.Add('status', StatusText);
        BarJson.Add('color', ColorText);
        BarJson.Add('trackColor', TrackColorText);
        BarJson.Add('label', LabelText);
        BarJson.Add('tooltipTitle', ValidationHelper.GetFieldValueAsDisplayText(SourceRef, MappingLine."Tooltip Title Field ID"));
        BarJson.Add('isEditable', MappingLine."Is Editable");
        BarJson.Add('resourceKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Resource Group Field ID"));
        BarJson.Add('conflictGroupKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Conflict Group Field ID"));
        BarJson.Add('contextKey', GetContextKey(SourceRef, MappingLine));
        BarJson.Add('dependencyKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID"));
        BarJson.Add('aggregationValue', ValidationHelper.GetFieldDecimal(SourceRef, MappingLine."Aggregation Value Field ID"));
        BarJson.Add('capacityValue', ValidationHelper.GetFieldDecimal(SourceRef, MappingLine."Aggregation Capacity Field ID"));
        BarJson.Add('bucketMode', Format(MappingLine."Aggregation Bucket Mode"));
        BarJson.Add('depth', Level);
    end;

    local procedure BuildDependenciesForView(GanttView: Record "DGOG Gantt View"; var DependenciesJson: JsonArray; var AddedDependencyIds: Dictionary of [Text, Boolean]; VisibleBarKeys: Dictionary of [Text, Boolean])
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        MappingLine.SetRange("Setup ID", GanttView."Setup ID");
        MappingLine.SetRange("View Code", GanttView."View Code");
        if not MappingLine.FindSet() then
            exit;

        repeat
            if HasDependency(MappingLine) then
                BuildDependenciesForMapping(GanttView."View Code", MappingLine, DependenciesJson, AddedDependencyIds, VisibleBarKeys);
        until MappingLine.Next() = 0;
    end;

    local procedure BuildDependenciesForMapping(ViewCode: Code[20]; MappingLine: Record "DGOG Gantt Mapping Line"; var DependenciesJson: JsonArray; var AddedDependencyIds: Dictionary of [Text, Boolean]; VisibleBarKeys: Dictionary of [Text, Boolean])
    var
        SourceRef: RecordRef;
        DependencyJson: JsonObject;
        DependencyId: Text;
        CurrentKey: Text;
        GroupValue: Text;
        OrderValue: Text;
        NextKey: Text;
    begin
        SourceRef.Open(MappingLine."Source Table ID");
        if not SourceRef.FindSet() then
            exit;

        repeat
            CurrentKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID");
            if IsVisibleDependencyKey(MappingLine."Line No.", CurrentKey, VisibleBarKeys) then begin
                GroupValue := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Dependency Target Field ID");
                OrderValue := ValidationHelper.GetFieldValueAsIso(SourceRef, MappingLine."Dependency Order Field ID");
                if (GroupValue <> '') and (OrderValue <> '') then
                    if IsUniqueDependencyOrder(MappingLine, GroupValue, OrderValue, VisibleBarKeys) then
                        if FindImmediateNextDependencyKey(MappingLine, GroupValue, OrderValue, SourceRef.RecordId, VisibleBarKeys, NextKey) then
                            if (NextKey <> '') and (CurrentKey <> NextKey) then begin
                                Clear(DependencyJson);
                                DependencyId := StrSubstNo('%1|%2|%3', MappingLine."Line No.", CurrentKey, NextKey);
                                if not AddedDependencyIds.ContainsKey(DependencyId) then begin
                                    DependencyJson.Add('dependencyId', DependencyId);
                                    DependencyJson.Add('rowId', GetStableRowId(ViewCode, MappingLine."Line No.", SourceRef.RecordId));
                                    DependencyJson.Add('mappingLineNo', MappingLine."Line No.");
                                    DependencyJson.Add('sourceKey', CurrentKey);
                                    DependencyJson.Add('targetKey', NextKey);
                                    DependencyJson.Add('type', 'FS');
                                    DependencyJson.Add('sourceRecordId', Format(SourceRef.RecordId));
                                    DependenciesJson.Add(DependencyJson);
                                    AddedDependencyIds.Add(DependencyId, true);
                                end;
                            end;
            end;
        until SourceRef.Next() = 0;
    end;

    local procedure FindImmediateNextDependencyKey(MappingLine: Record "DGOG Gantt Mapping Line"; GroupValue: Text; OrderValue: Text; CurrentRecordId: RecordId; VisibleBarKeys: Dictionary of [Text, Boolean]; var NextKey: Text): Boolean
    var
        SearchRef: RecordRef;
        CandidateKey: Text;
        CandidateGroupValue: Text;
        CandidateOrderValue: Text;
        BestOrderValue: Text;
    begin
        Clear(NextKey);
        SearchRef.Open(MappingLine."Source Table ID");
        if not SearchRef.FindSet() then
            exit(false);

        repeat
            CandidateKey := ValidationHelper.GetFieldValueAsText(SearchRef, MappingLine."Key Field ID");
            if (SearchRef.RecordId <> CurrentRecordId) and IsVisibleDependencyKey(MappingLine."Line No.", CandidateKey, VisibleBarKeys) then begin
                CandidateGroupValue := ValidationHelper.GetFieldValueAsText(SearchRef, MappingLine."Dependency Target Field ID");
                CandidateOrderValue := ValidationHelper.GetFieldValueAsIso(SearchRef, MappingLine."Dependency Order Field ID");
                if (CandidateGroupValue = GroupValue) and (CandidateOrderValue <> '') and (CandidateKey <> '') then
                    if CompareSortableValues(OrderValue, CandidateOrderValue) < 0 then
                        if IsUniqueDependencyOrder(MappingLine, GroupValue, CandidateOrderValue, VisibleBarKeys) then
                            if (BestOrderValue = '') or (CompareSortableValues(CandidateOrderValue, BestOrderValue) < 0) then begin
                                BestOrderValue := CandidateOrderValue;
                                NextKey := CandidateKey;
                            end;
            end;
        until SearchRef.Next() = 0;

        exit(NextKey <> '');
    end;

    local procedure IsUniqueDependencyOrder(MappingLine: Record "DGOG Gantt Mapping Line"; GroupValue: Text; OrderValue: Text; VisibleBarKeys: Dictionary of [Text, Boolean]): Boolean
    var
        SearchRef: RecordRef;
        CandidateKey: Text;
        MatchCount: Integer;
    begin
        SearchRef.Open(MappingLine."Source Table ID");
        if not SearchRef.FindSet() then
            exit(false);

        repeat
            CandidateKey := ValidationHelper.GetFieldValueAsText(SearchRef, MappingLine."Key Field ID");
            if IsVisibleDependencyKey(MappingLine."Line No.", CandidateKey, VisibleBarKeys) then
                if ValidationHelper.GetFieldValueAsText(SearchRef, MappingLine."Dependency Target Field ID") = GroupValue then
                    if ValidationHelper.GetFieldValueAsIso(SearchRef, MappingLine."Dependency Order Field ID") = OrderValue then begin
                        MatchCount += 1;
                        if MatchCount > 1 then
                            exit(false);
                    end;
        until SearchRef.Next() = 0;

        exit(MatchCount = 1);
    end;

    local procedure CompareSortableValues(FirstValue: Text; SecondValue: Text): Integer
    var
        FirstNumber: Decimal;
        SecondNumber: Decimal;
        FirstComparableValue: Text;
        SecondComparableValue: Text;
    begin
        if Evaluate(FirstNumber, FirstValue) and Evaluate(SecondNumber, SecondValue) then begin
            if FirstNumber < SecondNumber then
                exit(-1);
            if FirstNumber > SecondNumber then
                exit(1);
            exit(0);
        end;

        FirstComparableValue := UpperCase(FirstValue);
        SecondComparableValue := UpperCase(SecondValue);
        if FirstComparableValue < SecondComparableValue then
            exit(-1);
        if FirstComparableValue > SecondComparableValue then
            exit(1);
        exit(0);
    end;

    local procedure ApplyParentFieldFilters(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"; ParentSourceRef: RecordRef): Boolean
    var
        MappingRelation: Record "DGOG Gantt Mapping Relation";
        ParentValue: Text;
    begin
        if MappingLine."Parent Line No." = 0 then
            exit(true);

        MappingRelation.SetRange("Setup ID", MappingLine."Setup ID");
        MappingRelation.SetRange("View Code", MappingLine."View Code");
        MappingRelation.SetRange("Child Line No.", MappingLine."Line No.");
        if not MappingRelation.FindSet() then
            exit(false);

        repeat
            ParentValue := ValidationHelper.GetFieldValueAsText(ParentSourceRef, MappingRelation."Parent Field ID");
            if ParentValue = '' then
                exit(false);
            ValidationHelper.SetFieldFilterFromText(SourceRef, MappingRelation."Child Field ID", ParentValue);
        until MappingRelation.Next() = 0;

        exit(true);
    end;

    local procedure GetVisibleDependencyKey(MappingLineNo: Integer; DependencyKey: Text): Text
    begin
        exit(StrSubstNo('%1|%2', MappingLineNo, DependencyKey));
    end;

    local procedure IsVisibleDependencyKey(MappingLineNo: Integer; DependencyKey: Text; VisibleBarKeys: Dictionary of [Text, Boolean]): Boolean
    begin
        if DependencyKey = '' then
            exit(false);

        exit(VisibleBarKeys.ContainsKey(GetVisibleDependencyKey(MappingLineNo, DependencyKey)));
    end;

    local procedure BuildTooltipFields(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"; var TooltipFields: JsonArray)
    var
        DetailLine: Record "DGOG Gantt Detail Line";
        TooltipFieldJson: JsonObject;
        CaptionText: Text;
    begin
        DetailLine.SetRange("Setup ID", MappingLine."Setup ID");
        DetailLine.SetRange("View Code", MappingLine."View Code");
        DetailLine.SetRange("Mapping Line No.", MappingLine."Line No.");
        DetailLine.SetRange("Is Visible", true);
        DetailLine.SetCurrentKey("Setup ID", "View Code", "Mapping Line No.", Sequence);
        if not DetailLine.FindSet() then
            exit;

        repeat
            Clear(TooltipFieldJson);
            CaptionText := DetailLine."Caption Override";
            if CaptionText = '' then
                CaptionText := ValidationHelper.GetFieldCaption(MappingLine."Source Table ID", DetailLine."Field ID");
            TooltipFieldJson.Add('caption', CaptionText);
            TooltipFieldJson.Add('value', ValidationHelper.GetFieldValueAsDisplayText(SourceRef, DetailLine."Field ID"));
            TooltipFields.Add(TooltipFieldJson);
        until DetailLine.Next() = 0;
    end;

    local procedure ResolveProgressPercent(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"): Decimal
    var
        Numerator: Decimal;
        Denominator: Decimal;
        OverridePercent: Decimal;
    begin
        if MappingLine."Progress Override Field ID" <> 0 then begin
            OverridePercent := ValidationHelper.GetFieldDecimal(SourceRef, MappingLine."Progress Override Field ID");
            exit(OverridePercent);
        end;

        Numerator := ValidationHelper.GetFieldDecimal(SourceRef, MappingLine."Start Decimal Field ID");
        Denominator := ValidationHelper.GetFieldDecimal(SourceRef, MappingLine."End Decimal Field ID");
        if Denominator = 0 then
            exit(0);

        exit(Round((Numerator / Denominator) * 100, 0.01));
    end;

    local procedure ResolveBarColor(StatusText: Text; OverrideColor: Text): Text
    begin
        if OverrideColor <> '' then
            exit(OverrideColor);

        case UpperCase(StatusText) of
            'PLANNED':
                exit('#4A90D9');
            'FIRM PLANNED':
                exit('#E8922E');
            'RELEASED':
                exit('#3AAB5C');
            'FINISHED':
                exit('#8A8F99');
            else
                exit('#3C78D8');
        end;
    end;

    local procedure ResolveTrackColor(StatusText: Text): Text
    begin
        case UpperCase(StatusText) of
            'PLANNED':
                exit('#A3C4E9');
            'FIRM PLANNED':
                exit('#F0C68A');
            'RELEASED':
                exit('#8ED4A4');
            'FINISHED':
                exit('#C2C5CC');
            else
                exit('#C8D6F0');
        end;
    end;

    local procedure GetContextKey(var SourceRef: RecordRef; MappingLine: Record "DGOG Gantt Mapping Line"): Text
    var
        ContextKey: Text;
    begin
        ContextKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Context Identity Field ID");
        if ContextKey = '' then
            ContextKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID");
        exit(ContextKey);
    end;

    local procedure HasChildMapping(SetupId: Integer; ViewCode: Code[20]; ParentLineNo: Integer): Boolean
    var
        ChildMapping: Record "DGOG Gantt Mapping Line";
    begin
        ChildMapping.SetRange("Setup ID", SetupId);
        ChildMapping.SetRange("View Code", ViewCode);
        ChildMapping.SetRange("Parent Line No.", ParentLineNo);
        exit(ChildMapping.FindFirst());
    end;

    local procedure HasBar(MappingLine: Record "DGOG Gantt Mapping Line"): Boolean
    begin
        exit((MappingLine."Start Date Field ID" <> 0) and (MappingLine."End Date Field ID" <> 0));
    end;

    local procedure HasDependency(MappingLine: Record "DGOG Gantt Mapping Line"): Boolean
    begin
        exit((MappingLine."Dependency Target Field ID" <> 0) and (MappingLine."Dependency Order Field ID" <> 0));
    end;

    local procedure UpdateRange(StartValue: DateTime; EndValue: DateTime; var RangeStart: DateTime; var RangeEnd: DateTime)
    begin
        if (RangeStart = 0DT) or (StartValue < RangeStart) then
            RangeStart := StartValue;
        if (RangeEnd = 0DT) or (EndValue > RangeEnd) then
            RangeEnd := EndValue;
    end;

    local procedure GetStableRowId(ViewCode: Code[20]; MappingLineNo: Integer; SourceRecordId: RecordId): Text
    begin
        exit(StrSubstNo('%1|%2|%3', ViewCode, MappingLineNo, Format(SourceRecordId)));
    end;

    local procedure GetStableBarId(MappingLineNo: Integer; SourceRecordId: RecordId): Text
    begin
        exit(StrSubstNo('BAR|%1|%2', MappingLineNo, Format(SourceRecordId)));
    end;
}