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
                    ToolTip = 'Specifies the descriptive name for this filter preset.';
                }
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source table this filter applies to.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this filter is currently active.';

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
                    ToolTip = 'Specifies the stored filter expression.';
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
                ToolTip = 'Opens the filter dialog for the source table to define or modify this filter preset.';

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
