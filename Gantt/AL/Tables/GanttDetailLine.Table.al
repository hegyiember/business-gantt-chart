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
            ToolTip = 'Specifies the parent setup that owns this detail mapping line.';
        }
        field(2; "View Code"; Code[20])
        {
            Caption = 'View Code';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("Setup ID"));
            ToolTip = 'Specifies which view this detail field belongs to.';
        }
        field(3; "Mapping Line No."; Integer)
        {
            Caption = 'Mapping Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
            ToolTip = 'Specifies which mapping line this detail field decorates in tooltips and detail popups.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the sequence identity of this detail line inside the selected mapping line.';
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the source field that should be shown in the hover tooltip and detail popup.';
        }
        field(6; "Caption Override"; Text[80])
        {
            Caption = 'Caption Override';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a custom caption shown instead of the source field caption when the tooltip is rendered.';
        }
        field(7; Sequence; Integer)
        {
            Caption = 'Sequence';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the display order of this detail entry within the tooltip.';
        }
        field(8; "Is Visible"; Boolean)
        {
            Caption = 'Is Visible';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this detail line should be rendered in tooltips.';
        }
        field(9; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("DGOG Gantt Mapping Line"."Source Table ID" where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Line No." = field("Mapping Line No.")));
            ToolTip = 'Specifies the source table from the linked mapping line; used to validate the selected field ID.';
        }
        field(10; "Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Field ID")));
            Caption = 'Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected field.';
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
