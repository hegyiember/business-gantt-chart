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
                    ToolTip = 'Select the field on the current (child) mapping line''s source table that is used to match records to their parent row. This field''s value at runtime is compared against the Parent Field value — when they match, the child record is nested under that parent row in the Gantt hierarchy. For example, to link Prod. Order Routing Lines to Production Orders, select "Prod. Order No." here (the routing line field that stores the parent order number). Use the lookup to browse fields available on the current line''s source table. You can add multiple field pairs for composite key matching (e.g., both "Prod. Order No." and "Status").';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                    begin
                        if Rec."Child Table ID" = 0 then
                            exit(false);

                        FieldRec.FilterGroup(2);
                        FieldRec.SetRange(TableNo, Rec."Child Table ID");
                        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                        FieldRec.FilterGroup(0);

                        if Rec."Child Field ID" <> 0 then
                            if FieldRec.Get(Rec."Child Table ID", Rec."Child Field ID") then;

                        if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                            Rec."Child Field ID" := FieldRec."No.";
                            Text := Format(Rec."Child Field ID");
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field("Child Field Name"; Rec."Child Field Name")
                {
                    ApplicationArea = All;
                    Caption = 'Current Field Name';
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Current Field ID. This read-only value confirms which child-side field is used in the parent-child join condition.';
                }
                field("Parent Field ID"; Rec."Parent Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Field ID';
                    ToolTip = 'Select the corresponding field on the parent mapping line''s source table that the current field is matched against. At runtime, when the current field value equals this parent field value, the child record is placed under that parent row. For example, if the current field is "Prod. Order No." on routing lines, the parent field should be "No." on the production order table — they both store the same production order number, creating the join. Use the lookup to browse fields available on the parent line''s source table.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                    begin
                        if Rec."Parent Table ID" = 0 then
                            exit(false);

                        FieldRec.FilterGroup(2);
                        FieldRec.SetRange(TableNo, Rec."Parent Table ID");
                        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                        FieldRec.FilterGroup(0);

                        if Rec."Parent Field ID" <> 0 then
                            if FieldRec.Get(Rec."Parent Table ID", Rec."Parent Field ID") then;

                        if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                            Rec."Parent Field ID" := FieldRec."No.";
                            Text := Format(Rec."Parent Field ID");
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field("Parent Field Name"; Rec."Parent Field Name")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Field Name';
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Parent Field ID. This read-only value confirms which parent-side field is used in the parent-child join condition.';
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