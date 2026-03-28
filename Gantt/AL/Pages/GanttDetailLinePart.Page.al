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
                    ToolTip = 'Select the source table field whose value should appear as a line item in the hover tooltip when users mouse over a bar from the parent mapping line. Use the lookup button to browse all available fields on the source table. You can add multiple detail lines to build a rich, informative tooltip — for example, add "Starting Date", "Ending Date", "Quantity", and "Status" as separate detail lines. Each detail line appears as a label-value pair in the tooltip. The field must belong to the same source table as the parent mapping line.';

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
                    ToolTip = 'Displays the caption of the field selected as Field ID. This is a read-only calculated value that helps you confirm the correct field was chosen without needing to remember numeric field IDs.';
                }
                field("Caption Override"; Rec."Caption Override")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a custom label to display in the tooltip instead of the field''s standard caption. For example, if the source field is "Expected Operation Cost Amt." you might override it to simply "Cost" for a cleaner tooltip appearance. Leave blank to use the field''s original caption as defined in the source table. The override only affects tooltip display — it does not change the source field or any other page.';
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Set a numeric value that controls the vertical display order of this detail line within the tooltip. Lower numbers appear first (at the top of the tooltip). Use increments of 10000 (the default) to leave room for inserting additional detail lines later without renumbering. For example, set "Starting Date" to 10000, "Ending Date" to 20000, and "Quantity" to 30000. Lines with the same sequence value are ordered by their Line No.';
                }
                field("Is Visible"; Rec."Is Visible")
                {
                    ApplicationArea = All;
                    ToolTip = 'Toggle whether this detail line appears in the tooltip at runtime. When disabled, the line is saved in the configuration but hidden from users — useful for temporarily removing a field from the tooltip without deleting the record, or for preparing fields that will be shown later. When enabled, the field value is rendered in the tooltip according to its sequence position. Default is true for new records.';
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