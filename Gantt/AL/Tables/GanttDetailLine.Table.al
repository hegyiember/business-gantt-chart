table 71891723 "DGOG Gantt Detail Line"
{
    Caption = 'Gantt Detail Line';
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
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("Setup ID"));
        }
        field(3; "Mapping Line No."; Integer)
        {
            Caption = 'Mapping Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
        }
        field(6; "Caption Override"; Text[80])
        {
            Caption = 'Caption Override';
            DataClassification = CustomerContent;
        }
        field(7; Sequence; Integer)
        {
            Caption = 'Sequence';
            DataClassification = CustomerContent;
        }
        field(8; "Is Visible"; Boolean)
        {
            Caption = 'Is Visible';
            DataClassification = CustomerContent;
        }
        field(9; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("DGOG Gantt Mapping Line"."Source Table ID" where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Line No." = field("Mapping Line No.")));
        }
        field(10; "Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Field ID")));
            Caption = 'Field Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(PK; "Setup ID", "View Code", "Mapping Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(SequenceKey; "Setup ID", "View Code", "Mapping Line No.", Sequence)
        {
        }
    }
}