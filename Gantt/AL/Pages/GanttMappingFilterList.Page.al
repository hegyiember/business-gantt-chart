page 71891721 "DGOG Gantt Mapping Filter List"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Gantt Mapping Filters';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "DGOG Gantt Mapping Filter";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a descriptive name for this filter preset, for example "Released Orders Only" or "Location BLUE". This name helps you identify the purpose of each saved filter when you have multiple presets configured. The name is auto-populated with a default when you create a filter using the "Create / Edit Filter" action, but you can change it to anything meaningful. The name is for administrative reference only and is not shown to end users at runtime.';
                }
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the source table that this filter applies to, automatically inherited from the parent mapping line when the record is created. This is a read-only reference field — the source table is determined by the mapping line configuration. All filter criteria defined in the Filter View column apply to records from this table. You cannot change this value directly; it is synchronized from the mapping line.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Toggle this to activate or deactivate this filter preset. Only one filter preset per mapping line can be active at a time — enabling this will automatically deactivate any other active filter on the same mapping line. When active, the filter criteria stored in the Filter View column are applied automatically every time the Gantt data builder loads records for this mapping line. Deactivate a filter to temporarily stop applying it without losing the saved criteria. If no filter is active, all records from the source table are loaded (subject to any runtime filters set via the Gantt host page).';

                    trigger OnValidate()
                    var
                        OtherFilter: Record "DGOG Gantt Mapping Filter";
                    begin
                        if Rec."Is Active" then begin
                            OtherFilter.SetRange("Setup ID", Rec."Setup ID");
                            OtherFilter.SetRange("View Code", Rec."View Code");
                            OtherFilter.SetRange("Mapping Line No.", Rec."Mapping Line No.");
                            OtherFilter.SetFilter("Line No.", '<>%1', Rec."Line No.");
                            OtherFilter.ModifyAll("Is Active", false);
                        end;
                    end;
                }
                field("Filter View"; Rec."Filter View")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the serialized filter expression that was saved using the "Create / Edit Filter" action. This is a system-generated string in Business Central''s internal filter view format — do not edit it manually unless you are familiar with the RecordRef.SetView() syntax. To modify the filter criteria, use the "Create / Edit Filter" action which opens a visual filter dialog. The stored expression is applied to the source table''s RecordRef at data build time, filtering which records appear as bars on the Gantt chart.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateFilter)
            {
                ApplicationArea = All;
                Caption = 'Create / Edit Filter';
                Image = FilterLines;
                ToolTip = 'Open the standard Business Central filter dialog for the source table to visually define or modify the filter criteria for this preset. The dialog shows all available fields from the source table — set filter values on any combination of fields (e.g., Status = Released, Location Code = BLUE). When you confirm the dialog, the filter expression is saved to the Filter View field. If the preset has no name yet, a default name is generated based on the table caption. You can run this action multiple times to refine the criteria. The filter only takes effect at runtime when the "Is Active" flag is enabled.';

                trigger OnAction()
                var
                    AllObj: Record AllObjWithCaption;
                    MappingLine: Record "DGOG Gantt Mapping Line";
                    FilterPage: FilterPageBuilder;
                    TableId: Integer;
                    TableCaption: Text;
                begin
                    if not MappingLine.Get(Rec."Setup ID", Rec."View Code", Rec."Mapping Line No.") then
                        Error('Mapping line not found.');

                    TableId := MappingLine."Source Table ID";
                    Rec."Source Table ID" := TableId;

                    AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                    AllObj.SetRange("Object ID", TableId);
                    if AllObj.FindFirst() then
                        TableCaption := AllObj."Object Caption"
                    else
                        TableCaption := Format(TableId);

                    FilterPage.PageCaption('Filter: ' + TableCaption);
                    FilterPage.AddTable(TableCaption, TableId);

                    if Rec."Filter View" <> '' then
                        FilterPage.SetView(TableCaption, Rec."Filter View");

                    if not FilterPage.RunModal() then
                        exit;

                    Rec."Filter View" := CopyStr(FilterPage.GetView(TableCaption, false), 1, MaxStrLen(Rec."Filter View"));
                    if Rec."Name" = '' then
                        Rec."Name" := CopyStr('Filter - ' + TableCaption, 1, MaxStrLen(Rec."Name"));
                    Rec.Modify(true);
                end;
            }
        }
    }
}