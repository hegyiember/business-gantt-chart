table 71891737 "DGOG Gantt Grouping Line"
{
    Caption = 'Gantt Grouping Line';
    DataClassification = CustomerContent;
    DrillDownPageId = "DGOG Gantt Grouping List";
    LookupPageId = "DGOG Gantt Grouping List";

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

            trigger OnValidate()
            begin
                SyncMappingContext();
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(6; "Group Field ID"; Integer)
        {
            Caption = 'Group Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
        }
        field(7; "Group Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Group Field ID")));
            Caption = 'Group Field Name';
            FieldClass = FlowField;
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
    begin
        SyncMappingContext();
    end;

    local procedure SyncMappingContext()
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if ("Setup ID" = 0) or ("View Code" = '') or ("Mapping Line No." = 0) then
            exit;

        if not MappingLine.Get("Setup ID", "View Code", "Mapping Line No.") then
            exit;

        "Source Table ID" := MappingLine."Source Table ID";
    end;
}