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

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                    begin
                        Rec.CalcFields("Source Table ID");
                        if Rec."Source Table ID" = 0 then
                            exit(false);

                        FieldRec.FilterGroup(2);
                        FieldRec.SetRange(TableNo, Rec."Source Table ID");
                        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                        FieldRec.FilterGroup(0);

                        if Rec."Field ID" <> 0 then
                            if FieldRec.Get(Rec."Source Table ID", Rec."Field ID") then;

                        if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                            Rec."Field ID" := FieldRec."No.";
                            Text := Format(Rec."Field ID");
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected field.';
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
