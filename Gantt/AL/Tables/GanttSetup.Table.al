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
            ToolTip = 'Specifies the unique identifier of this Gantt configuration. Each setup represents one reusable Gantt solution.';
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the human-readable name of the Gantt solution that administrators see on setup pages.';
        }
        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the purpose of this Gantt setup and the business scenario it is intended to visualize.';
        }
        field(4; "Default View Code"; Code[20])
        {
            Caption = 'Default View Code';
            DataClassification = CustomerContent;
            TableRelation = "DGOG Gantt View"."View Code" where("Setup ID" = field("ID"));
            ToolTip = 'Specifies which configured view opens first when the Gantt page is launched for this setup.';
        }
        field(5; "Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this setup is available for use at runtime.';
        }
        field(6; "Default Zoom %"; Integer)
        {
            Caption = 'Default Zoom %';
            DataClassification = CustomerContent;
            InitValue = 100;
            ToolTip = 'Specifies the initial zoom level in percent. The frontend supports a range from 30 to 400 percent in 10 percent steps.';
        }
        field(7; "Default Time Grain"; Enum "DGOG Gantt Time Grain")
        {
            Caption = 'Default Time Grain';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the initial time grain used by the timeline when the Gantt first opens.';
        }
        field(8; "Allow Edit"; Boolean)
        {
            Caption = 'Allow Edit';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether users are allowed to drag or resize bars in this setup.';
        }
        field(9; "Allow Save"; Boolean)
        {
            Caption = 'Allow Save';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether pending timeline changes can be written back to source Business Central records.';
        }
        field(10; "Enable Dependencies"; Boolean)
        {
            Caption = 'Enable Dependencies';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether dependency arrows should be rendered when dependency mapping fields exist.';
        }
        field(11; "Enable Aggregation"; Boolean)
        {
            Caption = 'Enable Aggregation';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether load or utilization overlays are enabled for this setup.';
        }
        field(12; "Enable Conflict Detection"; Boolean)
        {
            Caption = 'Enable Conflict Detection';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether overlap detection should highlight conflicting bars.';
        }
        field(13; "Enable View Switching"; Boolean)
        {
            Caption = 'Enable View Switching';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the user can switch between multiple configured hierarchy views at runtime.';
        }
        field(14; "Highest Parent Card Page ID"; Integer)
        {
            Caption = 'Highest Parent Card Page ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));
            ToolTip = 'Specifies the fallback card page to open when a bar click does not provide a more specific page mapping.';
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