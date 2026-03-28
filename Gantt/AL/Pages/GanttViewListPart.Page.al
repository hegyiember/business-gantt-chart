page 71891728 "DGOG Gantt View Part"
{
    ApplicationArea = All;
    Caption = 'Gantt Views';
    DelayedInsert = true;
    Editable = true;
    PageType = ListPart;
    SourceTable = "DGOG Gantt View";

    layout
    {
        area(Content)
        {
            repeater(Views)
            {
                field("View Code"; Rec."View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a short, unique code that identifies this view within the current setup (e.g., "BYORDER", "BYWC", "RESOURCE"). This code is used internally to link mapping lines, detail lines, grouping lines, relations, and filters to this view. It is also shown in the runtime view switcher if view switching is enabled. Once mapping lines exist under this code, avoid changing it — doing so will orphan the child records. Use uppercase letters and keep it under 20 characters.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a descriptive display name for this view, such as "By Production Order" or "By Work Center". This name appears in the runtime view switcher dropdown and helps users understand the perspective each view provides. Keep it clear and concise — ideally under 50 characters — so it fits comfortably in the switcher UI.';
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Set a numeric value that controls the display order of this view relative to other views in the same setup. Lower numbers appear first in both the setup card and the runtime view switcher. Use increments of 10 (e.g., 10, 20, 30) to leave room for inserting new views later without renumbering. Views with the same sequence value are sorted alphabetically by View Code.';
                }
                field("Is Default"; Rec."Is Default")
                {
                    ApplicationArea = All;
                    ToolTip = 'Mark this view as the default for the current setup. When a user opens the Gantt host page and no Default View Code is set on the setup header, the system will automatically load the view marked as default. Only one view per setup can be the default — toggling this on will automatically clear the flag from any other view in the same setup. If no view is marked as default and no Default View Code is set, the system uses the first view by sequence order.';
                }
                field("Root Mapping Line No."; Rec."Root Mapping Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Optionally specify which mapping line serves as the root (top-level) entry point for the hierarchy tree in this view. The dropdown shows all mapping lines configured under this setup and view. When set, the Gantt data builder starts reading source records from this mapping line and expands downward through child mapping lines. Leave blank to treat all mapping lines that have no parent as independent roots — this is useful when you want a flat list or multiple parallel hierarchies displayed side by side.';
                }
                field("Aggregation Enabled"; Rec."Aggregation Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to activate aggregate load/utilization overlays specifically for this view. This is a view-level toggle that works in conjunction with the setup-level "Enable Aggregation" flag — both must be on for overlays to appear. When enabled, the chart reads the Aggregation Value, Capacity, and Bucket Mode fields from each mapping line to calculate utilization per time bucket. Use this to show different overlay configurations per view, for example enabling aggregation in a "By Work Center" view but disabling it in a "By Production Order" view.';
                }
                field("Dependency Enabled"; Rec."Dependency Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to render dependency arrows specifically for this view. This view-level flag works together with the setup-level "Enable Dependencies" setting — both must be on for arrows to appear. Use this to control dependency visibility per view, for example showing dependency arrows in a detailed routing view but hiding them in a high-level summary view. Dependencies are generated based on the Dependency Target and Order fields on the mapping lines.';
                }
                field("Conflict Detection Enabled"; Rec."Conflict Detection Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to activate overlap/conflict detection specifically for this view. Works in conjunction with the setup-level "Enable Conflict Detection" flag — both must be enabled for conflict highlighting to appear. When active, bars sharing the same Conflict Group Field value are compared for date overlaps, and overlapping bars are visually flagged. Use this to show conflict detection in scheduling views while keeping it off in summary or reporting views.';
                }
            }
        }
    }
}