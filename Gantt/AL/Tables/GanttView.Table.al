table 71891721 "DGOG Gantt View"
{
    Caption = 'Gantt View';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Setup ID"; Integer)
        {
            Caption = 'Setup ID';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Setup"."ID";
        }
        field(2; "View Code"; Code[20])
        {
            Caption = 'View Code';
            DataClassification = CustomerContent;
        }
        field(3; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(4; Sequence; Integer)
        {
            Caption = 'Sequence';
            DataClassification = CustomerContent;
        }
        field(5; "Is Default"; Boolean)
        {
            Caption = 'Is Default';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                GanttView: Record "DGOG Gantt View";
            begin
                if not "Is Default" then
                    exit;

                GanttView.SetRange("Setup ID", "Setup ID");
                GanttView.SetFilter("View Code", '<>%1', "View Code");
                if GanttView.FindSet() then
                    repeat
                        if GanttView."Is Default" then begin
                            GanttView."Is Default" := false;
                            GanttView.Modify();
                        end;
                    until GanttView.Next() = 0;
            end;
        }
        field(6; "Root Mapping Line No."; Integer)
        {
            Caption = 'Root Mapping Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
        }
        field(7; "Aggregation Enabled"; Boolean)
        {
            Caption = 'Aggregation Enabled';
            DataClassification = CustomerContent;
        }
        field(8; "Dependency Enabled"; Boolean)
        {
            Caption = 'Dependency Enabled';
            DataClassification = CustomerContent;
        }
        field(9; "Conflict Detection Enabled"; Boolean)
        {
            Caption = 'Conflict Detection Enabled';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Setup ID", "View Code")
        {
            Clustered = true;
        }
        key(SequenceKey; "Setup ID", Sequence)
        {
        }
    }
}