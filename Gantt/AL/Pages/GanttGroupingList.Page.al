page 71891738 "DGOG Gantt Grouping List"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Map Grouping Fields';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "DGOG Gantt Grouping Line";
    SourceTableView = sorting("Setup ID", "View Code", "Mapping Line No.", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(GroupingLines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the grouping level order used at runtime.';
                }
                field("Group Field ID"; Rec."Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used for the current grouping level.';
                }
                field("Group Field Name"; Rec."Group Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected grouping field.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Mapping Line No." <> 0 then
            Rec.Validate("Mapping Line No.", Rec."Mapping Line No.");
    end;
}
