table 71891720 "DGOG Gantt Setup"
{
    Caption = 'Gantt Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "DGOG Gantt Setup List";
    LookupPageId = "DGOG Gantt Setup List";

    fields
    {
        field(1; "ID"; Integer)
        {
            Caption = 'ID';
            DataClassification = CustomerContent;
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Default View Code"; Code[20])
        {
            Caption = 'Default View Code';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("ID"));
        }
        field(5; "Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
        }
        field(6; "Default Zoom %"; Integer)
        {
            Caption = 'Default Zoom %';
            DataClassification = CustomerContent;
            InitValue = 100;
        }
        field(7; "Default Time Grain"; Enum "DGOG Gantt Time Grain")
        {
            Caption = 'Default Time Grain';
            DataClassification = CustomerContent;
        }
        field(8; "Allow Edit"; Boolean)
        {
            Caption = 'Allow Edit';
            DataClassification = CustomerContent;
        }
        field(9; "Allow Save"; Boolean)
        {
            Caption = 'Allow Save';
            DataClassification = CustomerContent;
        }
        field(10; "Enable Dependencies"; Boolean)
        {
            Caption = 'Enable Dependencies';
            DataClassification = CustomerContent;
        }
        field(11; "Enable Aggregation"; Boolean)
        {
            Caption = 'Enable Aggregation';
            DataClassification = CustomerContent;
        }
        field(12; "Enable Conflict Detection"; Boolean)
        {
            Caption = 'Enable Conflict Detection';
            DataClassification = CustomerContent;
        }
        field(13; "Enable View Switching"; Boolean)
        {
            Caption = 'Enable View Switching';
            DataClassification = CustomerContent;
        }
        field(14; "Highest Parent Card Page ID"; Integer)
        {
            Caption = 'Highest Parent Card Page ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
        key(NameKey; "Name")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Default Zoom %" = 0 then
            "Default Zoom %" := 100;
        if not "Active" then
            "Active" := true;
    end;
}