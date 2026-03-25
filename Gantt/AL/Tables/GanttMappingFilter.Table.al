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
            ToolTip = 'Specifies the parent setup.';
        }
        field(2; "View Code"; Code[20])
        {
            Caption = 'View Code';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("Setup ID"));
            ToolTip = 'Specifies the view.';
        }
        field(3; "Mapping Line No."; Integer)
        {
            Caption = 'Mapping Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
            ToolTip = 'Specifies which mapping line this filter applies to.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique line number of this filter entry.';
        }
        field(5; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a descriptive name for this saved filter preset.';
        }
        field(6; "Filter View"; Text[2048])
        {
            Caption = 'Filter View';
            DataClassification = CustomerContent;
            ToolTip = 'Stores the serialized filter view string.';
        }
        field(7; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the source table this filter applies to.';
        }
        field(8; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this filter preset is currently active for the mapping line.';
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
