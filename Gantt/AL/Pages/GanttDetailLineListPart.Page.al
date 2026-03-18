page 71891730 "LVE Gantt Detail Line Part"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Gantt Detail Lines';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "LVE Gantt Detail Line";

    layout
    {
        area(Content)
        {
            repeater(Details)
            {
                field("View Code"; Rec."View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which configured view this detail line belongs to.';
                }
                field("Mapping Line No."; Rec."Mapping Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which mapping line this detail line decorates.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique sequence identity of this detail line.';
                }
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source field that is shown in the tooltip.';
                }
                field("Caption Override"; Rec."Caption Override")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tooltip caption override.';
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display order of this field inside the tooltip.';
                }
                field("Is Visible"; Rec."Is Visible")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the detail line is shown in the tooltip.';
                }
            }
        }
    }
}
