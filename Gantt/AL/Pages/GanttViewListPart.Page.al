page 71891728 "LVE Gantt View Part"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Gantt Views';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "LVE Gantt View";

    layout
    {
        area(Content)
        {
            repeater(Views)
            {
                field("View Code"; Rec."View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code of the view inside the selected setup.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name used in the runtime view switcher.';
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display order of the view.';
                }
                field("Is Default"; Rec."Is Default")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this view is the default one for the setup.';
                }
                field("Root Mapping Line No."; Rec."Root Mapping Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the root mapping line of the view.';
                }
                field("Aggregation Enabled"; Rec."Aggregation Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether aggregation overlays are enabled for this view.';
                }
                field("Dependency Enabled"; Rec."Dependency Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether dependency rendering is enabled for this view.';
                }
                field("Conflict Detection Enabled"; Rec."Conflict Detection Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether conflict detection is enabled for this view.';
                }
            }
        }
    }
}
