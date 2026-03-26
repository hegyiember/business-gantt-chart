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
                field("Group Field ID"; Rec."Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used for the current grouping level.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                    begin
                        if Rec."Source Table ID" = 0 then
                            exit(false);

                        FieldRec.FilterGroup(2);
                        FieldRec.SetRange(TableNo, Rec."Source Table ID");
                        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                        FieldRec.FilterGroup(0);

                        if Rec."Group Field ID" <> 0 then
                            if FieldRec.Get(Rec."Source Table ID", Rec."Group Field ID") then;

                        if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                            Rec."Group Field ID" := FieldRec."No.";
                            Text := Format(Rec."Group Field ID");
                            exit(true);
                        end;

                        exit(false);
                    end;
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
    var
        GanttGroupingLine: Record "DGOG Gantt Grouping Line";
    begin
        if Rec."Mapping Line No." <> 0 then
            Rec.Validate("Mapping Line No.", Rec."Mapping Line No.");

        GanttGroupingLine.SetRange("Setup ID", Rec."Setup ID");
        GanttGroupingLine.SetRange("View Code", Rec."View Code");
        GanttGroupingLine.SetRange("Mapping Line No.", Rec."Mapping Line No.");
        if GanttGroupingLine.FindLast() then
            Rec."Line No." := GanttGroupingLine."Line No." + 10000
        else
            Rec."Line No." := 10000;
    end;
}
