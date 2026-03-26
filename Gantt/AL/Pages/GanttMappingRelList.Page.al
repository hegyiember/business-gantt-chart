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
                    ToolTip = 'Shows the caption of the selected current-line field.';
                }
                field("Parent Field ID"; Rec."Parent Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Field ID';
                    ToolTip = 'Specifies the matching field on the parent mapping line table.';

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
