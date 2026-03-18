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
            ToolTip = 'Specifies the parent setup that owns this hierarchy view.';
        }
        field(2; "View Code"; Code[20])
        {
            Caption = 'View Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unique code of the view within the selected setup.';
        }
        field(3; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the display name that users see in the runtime view switcher.';
        }
        field(4; Sequence; Integer)
        {
            Caption = 'Sequence';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the display order of this view in setup pages and the runtime selector.';
        }
        field(5; "Is Default"; Boolean)
        {
            Caption = 'Is Default';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this is the default view for the setup.';

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
            ToolTip = 'Specifies the top mapping line of the hierarchy for this view. Leave blank to treat all top-level mapping lines as roots.';
        }
        field(7; "Aggregation Enabled"; Boolean)
        {
            Caption = 'Aggregation Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this view enables aggregate utilization overlays.';
        }
        field(8; "Dependency Enabled"; Boolean)
        {
            Caption = 'Dependency Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this view renders configured dependency arrows.';
        }
        field(9; "Conflict Detection Enabled"; Boolean)
        {
            Caption = 'Conflict Detection Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this view should detect overlaps inside configured conflict groups.';
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