table 71891739 "DGOG Gantt Mapping Filter"
{
    Caption = 'Gantt Mapping Filter';
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
        field(5; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(6; "Filter View"; Text[2048])
        {
            Caption = 'Filter View';
            DataClassification = CustomerContent;
        }
        field(7; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Setup ID", "View Code", "Mapping Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if "Source Table ID" = 0 then
            if MappingLine.Get("Setup ID", "View Code", "Mapping Line No.") then
                "Source Table ID" := MappingLine."Source Table ID";
    end;
}