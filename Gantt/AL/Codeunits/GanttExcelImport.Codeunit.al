codeunit 71891737 "DGOG Gantt Excel Import"
{
    procedure ImportView(SetupId: Integer)
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        InStr: InStream;
        FileName: Text;
        SheetName: Text;
        ViewCode: Code[20];
        GanttView: Record "DGOG Gantt View";
        SheetNames: List of [Text];
    begin
        if not UploadIntoStream('Select Gantt View Excel file', '', 'Excel Files (*.xlsx)|*.xlsx', FileName, InStr) then
            exit;

        // ── Read View sheet ──
        SheetName := 'View';
        ExcelBuffer.OpenBookStream(InStr, SheetName);
        ExcelBuffer.ReadSheet();

        ViewCode := CopyStr(GetCellText(ExcelBuffer, 2, 2), 1, MaxStrLen(ViewCode));
        if ViewCode = '' then
            Error('The View sheet does not contain a valid View Code in cell B2.');

        if GanttView.Get(SetupId, ViewCode) then
            Error('View Code %1 already exists under Setup %2. Please rename or delete the existing view first.', ViewCode, SetupId);

        ImportViewRecord(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        // ── Read Mapping Lines ──
        ExcelBuffer.OpenBookStream(InStr, 'Mapping Lines');
        ExcelBuffer.ReadSheet();
        ImportMappingLines(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        // ── Read Detail Lines ──
        ExcelBuffer.OpenBookStream(InStr, 'Detail Lines');
        ExcelBuffer.ReadSheet();
        ImportDetailLines(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        // ── Read Grouping Lines ──
        ExcelBuffer.OpenBookStream(InStr, 'Grouping Lines');
        ExcelBuffer.ReadSheet();
        ImportGroupingLines(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        // ── Read Mapping Relations ──
        ExcelBuffer.OpenBookStream(InStr, 'Mapping Relations');
        ExcelBuffer.ReadSheet();
        ImportMappingRelations(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        // ── Read Mapping Filters ──
        ExcelBuffer.OpenBookStream(InStr, 'Mapping Filters');
        ExcelBuffer.ReadSheet();
        ImportMappingFilters(ExcelBuffer, SetupId, ViewCode);
        ExcelBuffer.DeleteAll();

        Message('View %1 was imported successfully into Setup %2.', ViewCode, SetupId);
    end;

    // ── View ──

    local procedure ImportViewRecord(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        GanttView: Record "DGOG Gantt View";
    begin
        GanttView.Init();
        GanttView."Setup ID" := SetupId;
        GanttView."View Code" := ViewCode;
        GanttView."Name" := CopyStr(GetCellText(ExcelBuffer, 2, 3), 1, MaxStrLen(GanttView."Name"));
        GanttView.Sequence := GetCellInt(ExcelBuffer, 2, 4);
        GanttView."Is Default" := GetCellBool(ExcelBuffer, 2, 5);
        GanttView."Root Mapping Line No." := GetCellInt(ExcelBuffer, 2, 6);
        GanttView."Aggregation Enabled" := GetCellBool(ExcelBuffer, 2, 7);
        GanttView."Dependency Enabled" := GetCellBool(ExcelBuffer, 2, 8);
        GanttView."Conflict Detection Enabled" := GetCellBool(ExcelBuffer, 2, 9);
        GanttView.Insert(true);
    end;

    // ── Mapping Lines ──

    local procedure ImportMappingLines(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
        RowNo: Integer;
        MaxRow: Integer;
    begin
        MaxRow := GetMaxRow(ExcelBuffer);
        for RowNo := 2 to MaxRow do begin
            MappingLine.Init();
            MappingLine."Setup ID" := SetupId;
            MappingLine."View Code" := ViewCode;
            MappingLine."Line No." := GetCellInt(ExcelBuffer, RowNo, 1);
            MappingLine."Source Table ID" := GetCellInt(ExcelBuffer, RowNo, 2);
            MappingLine."Parent Line No." := GetCellInt(ExcelBuffer, RowNo, 3);
            MappingLine."Key Field ID" := GetCellInt(ExcelBuffer, RowNo, 4);
            MappingLine."Description Field ID" := GetCellInt(ExcelBuffer, RowNo, 5);
            MappingLine."Start Date Field ID" := GetCellInt(ExcelBuffer, RowNo, 6);
            MappingLine."End Date Field ID" := GetCellInt(ExcelBuffer, RowNo, 7);
            MappingLine."Due Date Field ID" := GetCellInt(ExcelBuffer, RowNo, 8);
            MappingLine."Start Decimal Field ID" := GetCellInt(ExcelBuffer, RowNo, 9);
            MappingLine."End Decimal Field ID" := GetCellInt(ExcelBuffer, RowNo, 10);
            MappingLine."Status Field ID" := GetCellInt(ExcelBuffer, RowNo, 11);
            MappingLine."Sequence Field ID" := GetCellInt(ExcelBuffer, RowNo, 12);
            MappingLine."Is Expandable" := GetCellBool(ExcelBuffer, RowNo, 13);
            MappingLine."Is Editable" := GetCellBool(ExcelBuffer, RowNo, 14);
            MappingLine."Card Page ID" := GetCellInt(ExcelBuffer, RowNo, 15);
            MappingLine."Grouping Field ID" := GetCellInt(ExcelBuffer, RowNo, 16);
            MappingLine."Context Identity Field ID" := GetCellInt(ExcelBuffer, RowNo, 17);
            MappingLine."Resource Group Field ID" := GetCellInt(ExcelBuffer, RowNo, 18);
            MappingLine."Dependency Target Field ID" := GetCellInt(ExcelBuffer, RowNo, 19);
            MappingLine."Dependency Order Field ID" := GetCellInt(ExcelBuffer, RowNo, 20);
            MappingLine."Aggregation Value Field ID" := GetCellInt(ExcelBuffer, RowNo, 21);
            MappingLine."Aggregation Capacity Field ID" := GetCellInt(ExcelBuffer, RowNo, 22);
            Evaluate(MappingLine."Aggregation Bucket Mode", GetCellText(ExcelBuffer, RowNo, 23));
            MappingLine."Conflict Group Field ID" := GetCellInt(ExcelBuffer, RowNo, 24);
            MappingLine."Progress Override Field ID" := GetCellInt(ExcelBuffer, RowNo, 25);
            MappingLine."Color Override Field ID" := GetCellInt(ExcelBuffer, RowNo, 26);
            MappingLine."Label Override Field ID" := GetCellInt(ExcelBuffer, RowNo, 27);
            MappingLine."Tooltip Title Field ID" := GetCellInt(ExcelBuffer, RowNo, 28);
            MappingLine.Insert(true);
        end;
    end;

    // ── Detail Lines ──

    local procedure ImportDetailLines(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        DetailLine: Record "DGOG Gantt Detail Line";
        RowNo: Integer;
        MaxRow: Integer;
    begin
        MaxRow := GetMaxRow(ExcelBuffer);
        for RowNo := 2 to MaxRow do begin
            DetailLine.Init();
            DetailLine."Setup ID" := SetupId;
            DetailLine."View Code" := ViewCode;
            DetailLine."Mapping Line No." := GetCellInt(ExcelBuffer, RowNo, 1);
            DetailLine."Line No." := GetCellInt(ExcelBuffer, RowNo, 2);
            DetailLine."Field ID" := GetCellInt(ExcelBuffer, RowNo, 3);
            DetailLine."Caption Override" := CopyStr(GetCellText(ExcelBuffer, RowNo, 4), 1, MaxStrLen(DetailLine."Caption Override"));
            DetailLine.Sequence := GetCellInt(ExcelBuffer, RowNo, 5);
            DetailLine."Is Visible" := GetCellBool(ExcelBuffer, RowNo, 6);
            DetailLine.Insert(true);
        end;
    end;

    // ── Grouping Lines ──

    local procedure ImportGroupingLines(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        GroupingLine: Record "DGOG Gantt Grouping Line";
        RowNo: Integer;
        MaxRow: Integer;
    begin
        MaxRow := GetMaxRow(ExcelBuffer);
        for RowNo := 2 to MaxRow do begin
            GroupingLine.Init();
            GroupingLine."Setup ID" := SetupId;
            GroupingLine."View Code" := ViewCode;
            GroupingLine."Mapping Line No." := GetCellInt(ExcelBuffer, RowNo, 1);
            GroupingLine."Line No." := GetCellInt(ExcelBuffer, RowNo, 2);
            GroupingLine."Source Table ID" := GetCellInt(ExcelBuffer, RowNo, 3);
            GroupingLine."Group Field ID" := GetCellInt(ExcelBuffer, RowNo, 4);
            GroupingLine.Insert(true);
        end;
    end;

    // ── Mapping Relations ──

    local procedure ImportMappingRelations(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        MappingRel: Record "DGOG Gantt Mapping Relation";
        RowNo: Integer;
        MaxRow: Integer;
    begin
        MaxRow := GetMaxRow(ExcelBuffer);
        for RowNo := 2 to MaxRow do begin
            MappingRel.Init();
            MappingRel."Setup ID" := SetupId;
            MappingRel."View Code" := ViewCode;
            MappingRel."Child Line No." := GetCellInt(ExcelBuffer, RowNo, 1);
            MappingRel."Line No." := GetCellInt(ExcelBuffer, RowNo, 2);
            MappingRel."Parent Line No." := GetCellInt(ExcelBuffer, RowNo, 3);
            MappingRel."Child Table ID" := GetCellInt(ExcelBuffer, RowNo, 4);
            MappingRel."Parent Table ID" := GetCellInt(ExcelBuffer, RowNo, 5);
            MappingRel."Child Field ID" := GetCellInt(ExcelBuffer, RowNo, 6);
            MappingRel."Parent Field ID" := GetCellInt(ExcelBuffer, RowNo, 7);
            MappingRel.Insert(true);
        end;
    end;

    // ── Mapping Filters ──

    local procedure ImportMappingFilters(var ExcelBuffer: Record "Excel Buffer" temporary; SetupId: Integer; ViewCode: Code[20])
    var
        MappingFilter: Record "DGOG Gantt Mapping Filter";
        RowNo: Integer;
        MaxRow: Integer;
    begin
        MaxRow := GetMaxRow(ExcelBuffer);
        for RowNo := 2 to MaxRow do begin
            MappingFilter.Init();
            MappingFilter."Setup ID" := SetupId;
            MappingFilter."View Code" := ViewCode;
            MappingFilter."Mapping Line No." := GetCellInt(ExcelBuffer, RowNo, 1);
            MappingFilter."Line No." := GetCellInt(ExcelBuffer, RowNo, 2);
            MappingFilter."Name" := CopyStr(GetCellText(ExcelBuffer, RowNo, 3), 1, MaxStrLen(MappingFilter."Name"));
            MappingFilter."Filter View" := CopyStr(GetCellText(ExcelBuffer, RowNo, 4), 1, MaxStrLen(MappingFilter."Filter View"));
            MappingFilter."Source Table ID" := GetCellInt(ExcelBuffer, RowNo, 5);
            MappingFilter."Is Active" := GetCellBool(ExcelBuffer, RowNo, 6);
            MappingFilter.Insert(true);
        end;
    end;

    // ── Cell read helpers ──

    local procedure GetCellText(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer): Text
    begin
        if ExcelBuffer.Get(RowNo, ColNo) then
            exit(ExcelBuffer."Cell Value as Text");
        exit('');
    end;

    local procedure GetCellInt(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer): Integer
    var
        CellText: Text;
        IntVal: Integer;
    begin
        CellText := GetCellText(ExcelBuffer, RowNo, ColNo);
        if CellText = '' then
            exit(0);
        if Evaluate(IntVal, CellText) then
            exit(IntVal);
        exit(0);
    end;

    local procedure GetCellBool(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer): Boolean
    var
        CellText: Text;
    begin
        CellText := UpperCase(GetCellText(ExcelBuffer, RowNo, ColNo));
        exit(CellText in ['YES', 'TRUE', '1']);
    end;

    local procedure GetMaxRow(var ExcelBuffer: Record "Excel Buffer" temporary): Integer
    begin
        if ExcelBuffer.FindLast() then
            exit(ExcelBuffer."Row No.");
        exit(0);
    end;
}
