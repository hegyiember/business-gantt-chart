table 71891735 "DGOG Gantt Mapping Relation"
{
    Caption = 'Gantt Mapping Relation';
    DataClassification = CustomerContent;
    DrillDownPageId = "DGOG Gantt Mapping Rel. List";
    LookupPageId = "DGOG Gantt Mapping Rel. List";

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
        field(3; "Child Line No."; Integer)
        {
            Caption = 'Child Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));

            trigger OnValidate()
            begin
                SyncLineContext();
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
        }
        field(6; "Child Table ID"; Integer)
        {
            Caption = 'Current Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(7; "Parent Table ID"; Integer)
        {
            Caption = 'Parent Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(8; "Child Field ID"; Integer)
        {
            Caption = 'Current Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Child Table ID"));
        }
        field(9; "Child Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Child Table ID"), "No." = field("Child Field ID")));
            Caption = 'Current Field Name';
            FieldClass = FlowField;
        }
        field(10; "Parent Field ID"; Integer)
        {
            Caption = 'Parent Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Parent Table ID"));
        }
        field(11; "Parent Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Parent Table ID"), "No." = field("Parent Field ID")));
            Caption = 'Parent Field Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(PK; "Setup ID", "View Code", "Child Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(ParentKey; "Setup ID", "View Code", "Parent Line No.", "Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        SyncLineContext();
    end;

    local procedure SyncLineContext()
    var
        ChildMappingLine: Record "DGOG Gantt Mapping Line";
        ParentMappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if ("Setup ID" = 0) or ("View Code" = '') or ("Child Line No." = 0) then
            exit;

        if not ChildMappingLine.Get("Setup ID", "View Code", "Child Line No.") then
            exit;

        if ChildMappingLine."Parent Line No." = 0 then
            Error('Mapping line %1 has no parent line to map against.', "Child Line No.");

        if not ParentMappingLine.Get("Setup ID", "View Code", ChildMappingLine."Parent Line No.") then
            Error('Parent mapping line %1 does not exist for mapping line %2.', ChildMappingLine."Parent Line No.", "Child Line No.");

        "Parent Line No." := ChildMappingLine."Parent Line No.";
        "Child Table ID" := ChildMappingLine."Source Table ID";
        "Parent Table ID" := ParentMappingLine."Source Table ID";
    end;
}