page 71891736 "DGOG Gantt Mapping Rel. List"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Map Parent Fields';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "DGOG Gantt Mapping Relation";
    SourceTableView = sorting("Setup ID", "View Code", "Child Line No.", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(Relations)
            {
                field("Child Field ID"; Rec."Child Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Current Field ID';
                    ToolTip = 'Specifies the field on the current mapping line table used in the parent-child join.';
                }
                field("Child Field Name"; Rec."Child Field Name")
                {
                    ApplicationArea = All;
                    Caption = 'Current Field Name';
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected current-line field.';
                }
                field("Parent Field ID"; Rec."Parent Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Field ID';
                    ToolTip = 'Specifies the matching field on the parent mapping line table.';
                }
                field("Parent Field Name"; Rec."Parent Field Name")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Field Name';
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected parent-line field.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Child Line No." <> 0 then
            Rec.Validate("Child Line No.", Rec."Child Line No.");
    end;
}