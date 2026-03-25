page 71891730 "DGOG Gantt Detail Line Part"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Gantt Detail Lines';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "DGOG Gantt Detail Line";

    layout
    {
        area(Content)
        {
            repeater(Details)
            {
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

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        GanttDetailLine: Record "DGOG Gantt Detail Line";
    begin
        GanttDetailLine.SetRange("Setup ID", Rec."Setup ID");
        GanttDetailLine.SetRange("View Code", Rec."View Code");
        GanttDetailLine.SetRange("Mapping Line No.", Rec."Mapping Line No.");
        if GanttDetailLine.FindLast() then
            Rec.Sequence := GanttDetailLine.Sequence + 10000
        else
            Rec.Sequence := 10000;

        Rec.CalcFields("Source Table ID");
    end;
}