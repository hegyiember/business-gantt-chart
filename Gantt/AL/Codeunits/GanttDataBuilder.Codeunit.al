codeunit 71891733 "LVE Gantt Data Builder"
{
    procedure BuildPayload(SetupId: Integer; RequestedViewCode: Code[20]; ContextKey: Text): Text
    var
        GanttSetup: Record "LVE Gantt Setup";
        GanttView: Record "LVE Gantt View";
        RootJson: JsonObject;
        SetupJson: JsonObject;
        ActiveViewJson: JsonObject;
        ViewsJson: JsonArray;
        RowsJson: JsonArray;
        BarsJson: JsonArray;
        DependenciesJson: JsonArray;
        AggregatesJson: JsonArray;
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
        BuildRuntimeArrays(GanttSetup, GanttView, RowsJson, BarsJson, DependenciesJson, AggregatesJson, RangeStart, RangeEnd);

        RootJson.Add('setup', SetupJson);
        RootJson.Add('activeView', ActiveViewJson);
        RootJson.Add('views', ViewsJson);
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
        ValidationHelper: Codeunit "LVE Gantt Validation Helper";

    local procedure BuildSetupJson(GanttSetup: Record "LVE Gantt Setup"; GanttView: Record "LVE Gantt View"; ContextKey: Text; var SetupJson: JsonObject; var ActiveViewJson: JsonObject)
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
        GanttView: Record "LVE Gantt View";
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

    local procedure BuildRuntimeArrays(GanttSetup: Record "LVE Gantt Setup"; GanttView: Record "LVE Gantt View"; var RowsJson: JsonArray; var BarsJson: JsonArray; var DependenciesJson: JsonArray; var AggregatesJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime)
    var
        MappingLine: Record "LVE Gantt Mapping Line";
    begin
        RangeStart := CreateDateTime(CalcDate('<-7D>', WorkDate()), 0T);
        RangeEnd := CreateDateTime(CalcDate('<+30D>', WorkDate()), 235959T);

        if GanttView."Root Mapping Line No." <> 0 then begin
            if MappingLine.Get(GanttSetup."ID", GanttView."View Code", GanttView."Root Mapping Line No.") then
                AppendRecordsForMapping(GanttSetup, GanttView, MappingLine, '', '', 0, RowsJson, BarsJson, DependenciesJson, RangeStart, RangeEnd);
            exit;
        end;

        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        MappingLine.SetRange("View Code", GanttView."View Code");
        MappingLine.SetRange("Parent Line No.", 0);
        if not MappingLine.FindSet() then
            exit;

        repeat
            AppendRecordsForMapping(GanttSetup, GanttView, MappingLine, '', '', 0, RowsJson, BarsJson, DependenciesJson, RangeStart, RangeEnd);
        until MappingLine.Next() = 0;
    end;

    local procedure AppendRecordsForMapping(GanttSetup: Record "LVE Gantt Setup"; GanttView: Record "LVE Gantt View"; MappingLine: Record "LVE Gantt Mapping Line"; ParentJoinValue: Text; ParentRowId: Text; Level: Integer; var RowsJson: JsonArray; var BarsJson: JsonArray; var DependenciesJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime)
    var
        SourceRef: RecordRef;
        RowJson: JsonObject;
        BarJson: JsonObject;
        DependencyJson: JsonObject;
        CurrentRowId: Text;
        CurrentJoinValue: Text;
        HasChildren: Boolean;
        StartValue: DateTime;
        EndValue: DateTime;
    begin
        SourceRef.Open(MappingLine."Source Table ID");
        if (ParentJoinValue <> '') and (MappingLine."Relation Field ID" <> 0) then
            ValidationHelper.SetFieldFilterFromText(SourceRef, MappingLine."Relation Field ID", ParentJoinValue);

        if not SourceRef.FindSet() then
            exit;

        HasChildren := HasChildMapping(GanttSetup."ID", GanttView."View Code", MappingLine."Line No.");

        repeat
            Clear(RowJson);
            CurrentRowId := GetStableRowId(GanttView."View Code", MappingLine."Line No.", SourceRef.RecordId);
            CurrentJoinValue := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID");
            BuildRowJson(SourceRef, MappingLine, GanttView."View Code", CurrentRowId, ParentRowId, Level, HasChildren, RowJson);
            RowsJson.Add(RowJson);

            if HasBar(MappingLine) then begin
                Clear(BarJson);
                BuildBarJson(SourceRef, MappingLine, CurrentRowId, Level, BarJson, StartValue, EndValue);
                if StartValue <> 0DT then begin
                    BarsJson.Add(BarJson);
                    UpdateRange(StartValue, EndValue, RangeStart, RangeEnd);
                end;
            end;

            if HasDependency(MappingLine) then begin
                Clear(DependencyJson);
                BuildDependencyJson(SourceRef, MappingLine, CurrentRowId, DependencyJson);
                if DependencyJson.Keys.Count > 0 then
                    DependenciesJson.Add(DependencyJson);
            end;

            if HasChildren then
                AppendChildMappings(GanttSetup, GanttView, MappingLine."Line No.", CurrentJoinValue, CurrentRowId, Level + 1, RowsJson, BarsJson, DependenciesJson, RangeStart, RangeEnd);
        until SourceRef.Next() = 0;
    end;

    local procedure AppendChildMappings(GanttSetup: Record "LVE Gantt Setup"; GanttView: Record "LVE Gantt View"; ParentLineNo: Integer; ParentJoinValue: Text; ParentRowId: Text; Level: Integer; var RowsJson: JsonArray; var BarsJson: JsonArray; var DependenciesJson: JsonArray; var RangeStart: DateTime; var RangeEnd: DateTime)
    var
        ChildMapping: Record "LVE Gantt Mapping Line";
    begin
        ChildMapping.SetRange("Setup ID", GanttSetup."ID");
        ChildMapping.SetRange("View Code", GanttView."View Code");
        ChildMapping.SetRange("Parent Line No.", ParentLineNo);
        if not ChildMapping.FindSet() then
            exit;

        repeat
            AppendRecordsForMapping(GanttSetup, GanttView, ChildMapping, ParentJoinValue, ParentRowId, Level, RowsJson, BarsJson, DependenciesJson, RangeStart, RangeEnd);
        until ChildMapping.Next() = 0;
    end;

    local procedure BuildRowJson(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"; ViewCode: Code[20]; RowId: Text; ParentRowId: Text; Level: Integer; HasChildren: Boolean; var RowJson: JsonObject)
    var
        TooltipFields: JsonArray;
        TooltipTitle: Text;
    begin
        TooltipTitle := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Tooltip Title Field ID");

        RowJson.Add('rowId', RowId);
        RowJson.Add('parentRowId', ParentRowId);
        RowJson.Add('viewCode', ViewCode);
        RowJson.Add('mappingLineNo', MappingLine."Line No.");
        RowJson.Add('sourceTableId', MappingLine."Source Table ID");
        RowJson.Add('sourceRecordId', Format(SourceRef.RecordId));
        RowJson.Add('keyText', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Key Field ID"));
        RowJson.Add('descriptionText', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Description Field ID"));
        RowJson.Add('level', Level);
        RowJson.Add('hasChildren', HasChildren and MappingLine."Is Expandable");
        RowJson.Add('isExpanded', Level < 2);
        RowJson.Add('isEditable', MappingLine."Is Editable");
        RowJson.Add('statusValue', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Status Field ID"));
        RowJson.Add('colorValue', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Color Override Field ID"));
        RowJson.Add('conflictGroupKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Conflict Group Field ID"));
        RowJson.Add('resourceKey', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Resource Group Field ID"));
        RowJson.Add('contextKey', GetContextKey(SourceRef, MappingLine));
        RowJson.Add('sequenceValue', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Sequence Field ID"));
        RowJson.Add('tooltipTitle', TooltipTitle);

        BuildTooltipFields(SourceRef, MappingLine, TooltipFields);
        RowJson.Add('tooltipFields', TooltipFields);
    end;

    local procedure BuildBarJson(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"; RowId: Text; Level: Integer; var BarJson: JsonObject; var StartValue: DateTime; var EndValue: DateTime)
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

        StatusText := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Status Field ID");
        ColorText := ResolveBarColor(StatusText, ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Color Override Field ID"));
        TrackColorText := ResolveTrackColor(StatusText);
        LabelText := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Label Override Field ID");
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
        BarJson.Add('tooltipTitle', ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Tooltip Title Field ID"));
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

    local procedure BuildDependencyJson(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"; RowId: Text; var DependencyJson: JsonObject)
    var
        SourceKey: Text;
        TargetKey: Text;
        DependencyType: Text;
    begin
        SourceKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Dependency Source Field ID");
        TargetKey := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Dependency Target Field ID");
        if (SourceKey = '') or (TargetKey = '') then
            exit;

        DependencyType := ValidationHelper.GetFieldValueAsText(SourceRef, MappingLine."Dependency Type Field ID");
        if DependencyType = '' then
            DependencyType := 'FS';

        DependencyJson.Add('dependencyId', GetStableBarId(MappingLine."Line No.", SourceRef.RecordId) + ':' + DependencyType);
        DependencyJson.Add('rowId', RowId);
        DependencyJson.Add('mappingLineNo', MappingLine."Line No.");
        DependencyJson.Add('sourceKey', SourceKey);
        DependencyJson.Add('targetKey', TargetKey);
        DependencyJson.Add('type', DependencyType);
        DependencyJson.Add('sourceRecordId', Format(SourceRef.RecordId));
    end;

    local procedure BuildTooltipFields(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"; var TooltipFields: JsonArray)
    var
        DetailLine: Record "LVE Gantt Detail Line";
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
            TooltipFieldJson.Add('value', ValidationHelper.GetFieldValueAsText(SourceRef, DetailLine."Field ID"));
            TooltipFields.Add(TooltipFieldJson);
        until DetailLine.Next() = 0;
    end;

    local procedure ResolveProgressPercent(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"): Decimal
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

    local procedure GetContextKey(var SourceRef: RecordRef; MappingLine: Record "LVE Gantt Mapping Line"): Text
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
        ChildMapping: Record "LVE Gantt Mapping Line";
    begin
        ChildMapping.SetRange("Setup ID", SetupId);
        ChildMapping.SetRange("View Code", ViewCode);
        ChildMapping.SetRange("Parent Line No.", ParentLineNo);
        exit(ChildMapping.FindFirst());
    end;

    local procedure HasBar(MappingLine: Record "LVE Gantt Mapping Line"): Boolean
    begin
        exit((MappingLine."Start Date Field ID" <> 0) and (MappingLine."End Date Field ID" <> 0));
    end;

    local procedure HasDependency(MappingLine: Record "LVE Gantt Mapping Line"): Boolean
    begin
        exit((MappingLine."Dependency Source Field ID" <> 0) and (MappingLine."Dependency Target Field ID" <> 0));
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
