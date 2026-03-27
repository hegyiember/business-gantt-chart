codeunit 71891736 "DGOG Gantt Excel Export"
{
    procedure ExportView(SetupId: Integer; ViewCode: Code[20])
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        GanttView: Record "DGOG Gantt View";
        GanttMappingLine: Record "DGOG Gantt Mapping Line";
        GanttDetailLine: Record "DGOG Gantt Detail Line";
        GanttGroupingLine: Record "DGOG Gantt Grouping Line";
        GanttMappingRelation: Record "DGOG Gantt Mapping Relation";
        GanttMappingFilter: Record "DGOG Gantt Mapping Filter";
        FileName: Text;
    begin
        GanttView.Get(SetupId, ViewCode);

        // Sheet 1: View
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Setup ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('View Code', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Name', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sequence', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Is Default', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Root Mapping Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Aggregation Enabled', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Dependency Enabled', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Conflict Detection Enabled', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);

        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(GanttView."Setup ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(GanttView."View Code", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(GanttView."Name", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(GanttView.Sequence, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(GanttView."Is Default"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(GanttView."Root Mapping Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(GanttView."Aggregation Enabled"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Format(GanttView."Dependency Enabled"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Format(GanttView."Conflict Detection Enabled"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);

        ExcelBuffer.CreateNewBook('View');
        ExcelBuffer.WriteSheet('View', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        // Sheet 2: Mapping Lines
        WriteMappingLineHeaders(ExcelBuffer);
        GanttMappingLine.SetRange("Setup ID", SetupId);
        GanttMappingLine.SetRange("View Code", ViewCode);
        if GanttMappingLine.FindSet() then
            repeat
                WriteMappingLineRow(ExcelBuffer, GanttMappingLine);
            until GanttMappingLine.Next() = 0;

        ExcelBuffer.WriteSheet('Mapping Lines', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        // Sheet 3: Detail Lines
        WriteDetailLineHeaders(ExcelBuffer);
        GanttDetailLine.SetRange("Setup ID", SetupId);
        GanttDetailLine.SetRange("View Code", ViewCode);
        if GanttDetailLine.FindSet() then
            repeat
                WriteDetailLineRow(ExcelBuffer, GanttDetailLine);
            until GanttDetailLine.Next() = 0;

        ExcelBuffer.WriteSheet('Detail Lines', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        // Sheet 4: Grouping Lines
        WriteGroupingLineHeaders(ExcelBuffer);
        GanttGroupingLine.SetRange("Setup ID", SetupId);
        GanttGroupingLine.SetRange("View Code", ViewCode);
        if GanttGroupingLine.FindSet() then
            repeat
                WriteGroupingLineRow(ExcelBuffer, GanttGroupingLine);
            until GanttGroupingLine.Next() = 0;

        ExcelBuffer.WriteSheet('Grouping Lines', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        // Sheet 5: Mapping Relations
        WriteMappingRelHeaders(ExcelBuffer);
        GanttMappingRelation.SetRange("Setup ID", SetupId);
        GanttMappingRelation.SetRange("View Code", ViewCode);
        if GanttMappingRelation.FindSet() then
            repeat
                WriteMappingRelRow(ExcelBuffer, GanttMappingRelation);
            until GanttMappingRelation.Next() = 0;

        ExcelBuffer.WriteSheet('Mapping Relations', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        // Sheet 6: Mapping Filters
        WriteMappingFilterHeaders(ExcelBuffer);
        GanttMappingFilter.SetRange("Setup ID", SetupId);
        GanttMappingFilter.SetRange("View Code", ViewCode);
        if GanttMappingFilter.FindSet() then
            repeat
                WriteMappingFilterRow(ExcelBuffer, GanttMappingFilter);
            until GanttMappingFilter.Next() = 0;

        ExcelBuffer.WriteSheet('Mapping Filters', CompanyName(), UserId());
        ExcelBuffer.ClearNewRow();
        ExcelBuffer.DeleteAll();

        FileName := StrSubstNo('GanttView_%1_%2.xlsx', SetupId, ViewCode);
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename(FileName);
        ExcelBuffer.OpenExcel();
    end;

    // ── Mapping Line helpers ──

    local procedure WriteMappingLineHeaders(var ExcelBuffer: Record "Excel Buffer" temporary)
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Source Table ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Parent Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Key Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Description Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Start Date Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('End Date Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Due Date Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Start Decimal Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('End Decimal Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Status Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sequence Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Is Expandable', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Is Editable', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Card Page ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Grouping Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Context Identity Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Resource Group Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Dependency Target Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Dependency Order Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Aggregation Value Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Aggregation Capacity Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Aggregation Bucket Mode', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Conflict Group Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Progress Override Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Color Override Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Label Override Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tooltip Title Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure WriteMappingLineRow(var ExcelBuffer: Record "Excel Buffer" temporary; var Rec: Record "DGOG Gantt Mapping Line")
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(Rec."Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Source Table ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Parent Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Key Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Description Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Start Date Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."End Date Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Due Date Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Start Decimal Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."End Decimal Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Status Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Sequence Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(Rec."Is Expandable"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Format(Rec."Is Editable"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Rec."Card Page ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Grouping Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Context Identity Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Resource Group Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Dependency Target Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Dependency Order Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Aggregation Value Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Aggregation Capacity Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(Rec."Aggregation Bucket Mode"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Rec."Conflict Group Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Progress Override Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Color Override Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Label Override Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Tooltip Title Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
    end;

    // ── Detail Line helpers ──

    local procedure WriteDetailLineHeaders(var ExcelBuffer: Record "Excel Buffer" temporary)
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Mapping Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Caption Override', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sequence', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Is Visible', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure WriteDetailLineRow(var ExcelBuffer: Record "Excel Buffer" temporary; var Rec: Record "DGOG Gantt Detail Line")
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(Rec."Mapping Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Caption Override", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Rec.Sequence, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(Rec."Is Visible"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    // ── Grouping Line helpers ──

    local procedure WriteGroupingLineHeaders(var ExcelBuffer: Record "Excel Buffer" temporary)
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Mapping Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Source Table ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Group Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure WriteGroupingLineRow(var ExcelBuffer: Record "Excel Buffer" temporary; var Rec: Record "DGOG Gantt Grouping Line")
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(Rec."Mapping Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Source Table ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Group Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
    end;

    // ── Mapping Relation helpers ──

    local procedure WriteMappingRelHeaders(var ExcelBuffer: Record "Excel Buffer" temporary)
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Child Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Parent Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Child Table ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Parent Table ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Child Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Parent Field ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure WriteMappingRelRow(var ExcelBuffer: Record "Excel Buffer" temporary; var Rec: Record "DGOG Gantt Mapping Relation")
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(Rec."Child Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Parent Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Child Table ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Parent Table ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Child Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Parent Field ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
    end;

    // ── Mapping Filter helpers ──

    local procedure WriteMappingFilterHeaders(var ExcelBuffer: Record "Excel Buffer" temporary)
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Mapping Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Line No.', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Name', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Filter View', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Source Table ID', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Is Active', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure WriteMappingFilterRow(var ExcelBuffer: Record "Excel Buffer" temporary; var Rec: Record "DGOG Gantt Mapping Filter")
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn(Rec."Mapping Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Line No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Rec."Name", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Rec."Filter View", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn(Rec."Source Table ID", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn(Format(Rec."Is Active"), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
    end;
}
