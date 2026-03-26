table 71891722 "DGOG Gantt Mapping Line"
{
    Caption = 'Gantt Mapping Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Setup ID"; Integer)
        {
            Caption = 'Setup ID';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Setup"."ID";
            ToolTip = 'Specifies the parent setup that owns this mapping line.';
        }
        field(2; "View Code"; Code[20])
        {
            Caption = 'View Code';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("Setup ID"));
            ToolTip = 'Specifies which configured view this mapping line belongs to.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique line number of this mapping definition inside the selected setup and view.';
        }
        field(4; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            ToolTip = 'Specifies the Business Central source table that provides the records for this hierarchy level.';
        }
        field(5; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt Mapping Line"."Line No." where("Setup ID" = field("Setup ID"), "View Code" = field("View Code"));
            ToolTip = 'Specifies the parent mapping line. Leave blank for a root hierarchy level.';
        }
        field(7; "Key Field ID"; Integer)
        {
            Caption = 'Key Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field used as the primary row label and stable business identity within this mapping line.';
        }
        field(8; "Description Field ID"; Integer)
        {
            Caption = 'Description Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the secondary descriptive field shown below the primary row label.';
        }
        field(9; "Start Date Field ID"; Integer)
        {
            Caption = 'Start Date Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that provides the bar start date or datetime.';
        }
        field(10; "End Date Field ID"; Integer)
        {
            Caption = 'End Date Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that provides the bar end date or datetime.';
        }
        field(11; "Due Date Field ID"; Integer)
        {
            Caption = 'Due Date Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the optional due-date field rendered as a marker on the timeline.';
        }
        field(12; "Start Decimal Field ID"; Integer)
        {
            Caption = 'Start Decimal Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the numeric field used as the progress numerator when a direct percentage field is not mapped.';
        }
        field(13; "End Decimal Field ID"; Integer)
        {
            Caption = 'End Decimal Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the numeric field used as the progress denominator when a direct percentage field is not mapped.';
        }
        field(14; "Status Field ID"; Integer)
        {
            Caption = 'Status Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field whose value controls status-based bar coloring.';
        }
        field(15; "Sequence Field ID"; Integer)
        {
            Caption = 'Sequence Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field whose value orders sibling rows in the hierarchy.';
        }
        field(16; "Is Expandable"; Boolean)
        {
            Caption = 'Is Expandable';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this row level can expand to reveal child mapping lines.';
        }
        field(17; "Is Editable"; Boolean)
        {
            Caption = 'Is Editable';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether bars originating from this mapping line are allowed to move or resize.';
        }
        field(18; "Card Page ID"; Integer)
        {
            Caption = 'Card Page ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));
            ToolTip = 'Specifies the preferred card page to open when the user clicks bars originating from this mapping line.';
        }
        field(19; "Grouping Field ID"; Integer)
        {
            Caption = 'Grouping Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies an optional business grouping field used for contextual grouping and visual annotations.';
        }
        field(20; "Context Identity Field ID"; Integer)
        {
            Caption = 'Context Identity Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that preserves business context when switching between views.';
        }
        field(21; "Resource Group Field ID"; Integer)
        {
            Caption = 'Resource Group Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that groups rows or bars for aggregate utilization calculations.';
        }
        field(23; "Dependency Target Field ID"; Integer)
        {
            Caption = 'Dependency Group Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies Field A, which groups child elements for dependency generation even when they are not under the same parent.';
        }
        field(24; "Dependency Order Field ID"; Integer)
        {
            Caption = 'Dependency Order Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies Field B, which orders dependencies inside the same dependency group. Each row connects only to the immediate next higher unique value.';
        }
        field(25; "Aggregation Value Field ID"; Integer)
        {
            Caption = 'Aggregation Value Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the numeric field that contributes load minutes, hours, or quantity to aggregate buckets.';
        }
        field(26; "Aggregation Capacity Field ID"; Integer)
        {
            Caption = 'Aggregation Capacity Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the numeric field that provides available capacity for aggregate utilization calculations.';
        }
        field(27; "Aggregation Bucket Mode"; Enum "DGOG Gantt Bucket Mode")
        {
            Caption = 'Aggregation Bucket Mode';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether aggregation buckets are calculated per day, week, or month.';
        }
        field(28; "Conflict Group Field ID"; Integer)
        {
            Caption = 'Conflict Group Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that groups records for overlap detection.';
        }
        field(29; "Progress Override Field ID"; Integer)
        {
            Caption = 'Progress Override Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the direct progress percentage field that overrides numerator and denominator progress calculation.';
        }
        field(30; "Color Override Field ID"; Integer)
        {
            Caption = 'Color Override Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field that provides an explicit bar color value from source data.';
        }
        field(31; "Label Override Field ID"; Integer)
        {
            Caption = 'Label Override Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field used instead of the default key text for the label displayed inside the bar.';
        }
        field(32; "Tooltip Title Field ID"; Integer)
        {
            Caption = 'Tooltip Title Field ID';
            DataClassification = CustomerContent;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            ToolTip = 'Specifies the field used as the tooltip title when hovering the row or bar.';
        }

        // ── FlowField captions for all Field ID columns ──
        field(100; "Key Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Key Field ID")));
            Caption = 'Key Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected key field.';
        }
        field(101; "Description Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Description Field ID")));
            Caption = 'Description Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected description field.';
        }
        field(102; "Start Date Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Start Date Field ID")));
            Caption = 'Start Date Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected start date field.';
        }
        field(103; "End Date Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("End Date Field ID")));
            Caption = 'End Date Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected end date field.';
        }
        field(104; "Due Date Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Due Date Field ID")));
            Caption = 'Due Date Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected due date field.';
        }
        field(105; "Start Decimal Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Start Decimal Field ID")));
            Caption = 'Start Decimal Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected start decimal field.';
        }
        field(106; "End Decimal Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("End Decimal Field ID")));
            Caption = 'End Decimal Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected end decimal field.';
        }
        field(107; "Status Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Status Field ID")));
            Caption = 'Status Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected status field.';
        }
        field(108; "Sequence Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Sequence Field ID")));
            Caption = 'Sequence Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected sequence field.';
        }
        field(109; "Grouping Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Grouping Field ID")));
            Caption = 'Grouping Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected grouping field.';
        }
        field(110; "Context Identity Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Context Identity Field ID")));
            Caption = 'Context Identity Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected context identity field.';
        }
        field(111; "Resource Group Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Resource Group Field ID")));
            Caption = 'Resource Group Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected resource group field.';
        }
        field(112; "Dep. Target Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Dependency Target Field ID")));
            Caption = 'Dependency Target Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected dependency target field.';
        }
        field(113; "Dep. Order Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Dependency Order Field ID")));
            Caption = 'Dependency Order Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected dependency order field.';
        }
        field(114; "Agg. Value Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Aggregation Value Field ID")));
            Caption = 'Aggregation Value Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected aggregation value field.';
        }
        field(115; "Agg. Capacity Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Aggregation Capacity Field ID")));
            Caption = 'Aggregation Capacity Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected aggregation capacity field.';
        }
        field(116; "Conflict Group Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Conflict Group Field ID")));
            Caption = 'Conflict Group Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected conflict group field.';
        }
        field(117; "Progress Ovr. Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Progress Override Field ID")));
            Caption = 'Progress Override Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected progress override field.';
        }
        field(118; "Color Override Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Color Override Field ID")));
            Caption = 'Color Override Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected color override field.';
        }
        field(119; "Label Override Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Label Override Field ID")));
            Caption = 'Label Override Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected label override field.';
        }
        field(120; "Tooltip Title Field Name"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Tooltip Title Field ID")));
            Caption = 'Tooltip Title Field Name';
            FieldClass = FlowField;
            ToolTip = 'Shows the caption of the selected tooltip title field.';
        }
    }

    keys
    {
        key(PK; "Setup ID", "View Code", "Line No.")
        {
            Clustered = true;
        }
        key(ParentKey; "Setup ID", "View Code", "Parent Line No.", "Line No.")
        {
        }
    }
}
