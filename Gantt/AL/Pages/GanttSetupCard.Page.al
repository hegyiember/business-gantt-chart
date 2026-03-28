page 71891727 "DGOG Gantt Setup Card"
{
    ApplicationArea = All;
    Caption = 'Gantt Setup';
    PageType = Card;
    SourceTable = "DGOG Gantt Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("ID"; Rec."ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a unique numeric identifier for this Gantt setup. This ID is referenced by all child records (views, mapping lines, detail lines, etc.) and must remain stable once records exist. Choose a meaningful number or let the system auto-assign. Changing this value after child records are created will orphan them, so plan your numbering scheme before you start building views.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a concise, human-readable name that describes the business purpose of this Gantt setup, for example "Production Order Timeline" or "Project Resource Plan". This name appears on setup list pages and helps administrators quickly identify which configuration to open or modify. Keep it descriptive but short — ideally under 60 characters.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Provide a detailed explanation of what this Gantt setup visualizes and which business scenario it serves. Include information about the source data (e.g., production orders, service tasks, project lines), the intended audience (planners, managers, operators), and any special considerations. This description is for administrative reference only and is not shown to end users at runtime.';
                }
                field("Default View Code"; Rec."Default View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the view that should open automatically when users launch the Gantt host page for this setup. The dropdown shows all views configured under this setup. If left blank, the system will look for a view marked as "Is Default" on the Views subpage, and failing that, it will use the first available view. Tip: always set this explicitly for a consistent user experience.';
                }
                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Toggle this on to make the setup available for runtime use. When turned off, the Gantt host page will not load data for this setup and users will see an empty chart. Use this to temporarily disable a setup during maintenance or testing without deleting any configuration. New setups default to active.';
                }
                field("Default Zoom %"; Rec."Default Zoom %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Set the initial zoom level (in percent) that the Gantt timeline uses when it first loads. The supported range is 30% to 400%, adjustable in 10% increments at runtime using the Zoom In / Zoom Out actions. A value of 100% shows the standard timeline density. Use lower values (e.g., 50%) for high-level overviews spanning months, or higher values (e.g., 200%) to zoom into daily or hourly detail. If left at 0 or blank, the system defaults to 100%.';
                }
                field("Default Time Grain"; Rec."Default Time Grain")
                {
                    ApplicationArea = All;
                    ToolTip = 'Choose the time granularity that the Gantt timeline header displays when first opened. Options include Hour, Day, Week, Month, Quarter, and Year. This controls how the horizontal axis is subdivided. For example, choosing "Day" shows one column per calendar day, while "Week" groups columns into ISO weeks. Users can change the grain at runtime, but this sets their starting point. Match the grain to your typical planning horizon — use Day for short-cycle production, Week or Month for project portfolios.';
                }
                field("Allow Edit"; Rec."Allow Edit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to allow runtime users to drag bars horizontally (reschedule) or resize them (change duration) directly on the Gantt chart. When disabled, the chart is read-only and bars cannot be moved. This is the global master switch — individual mapping lines also have their own "Is Editable" flag, which must also be enabled for a specific bar level to be draggable. Use this to enforce a read-only view for reporting dashboards while keeping editing available on planning setups.';
                }
                field("Allow Save"; Rec."Allow Save")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to allow users to persist their drag-and-drop or resize changes back to the underlying Business Central records. When enabled, the "Save Pending Changes" action on the Gantt host page becomes functional and writes modified start/end dates back to the source table. When disabled, users can still drag bars (if Allow Edit is on), but the changes remain client-side only and are lost on reload. Always pair this with appropriate user permissions on the source tables.';
                }
                field("Enable Dependencies"; Rec."Enable Dependencies")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to render dependency arrows between bars on the Gantt chart. Dependencies are generated automatically based on the Dependency Target Field and Dependency Order Field configured on each mapping line. When two bars share the same dependency target value, an arrow connects the bar with the lower order value to the bar with the next higher order value. This is useful for visualizing predecessor-successor relationships in production routing operations or project task sequences. Leave disabled if your data does not have sequential dependencies.';
                }
                field("Enable Aggregation"; Rec."Enable Aggregation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to show aggregate load or utilization overlays on the Gantt chart. When active, the system reads the Aggregation Value Field (load/hours), Aggregation Capacity Field, and Aggregation Bucket Mode from each mapping line to calculate per-bucket utilization percentages. The overlay appears as a colored band behind the bars, indicating whether resources are under-loaded, optimally loaded, or over-loaded. This is especially useful for capacity planning scenarios such as work center utilization or team workload balancing. Leave disabled if you do not need resource utilization visuals.';
                }
                field("Enable Conflict Detection"; Rec."Enable Conflict Detection")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to automatically detect and highlight overlapping bars within the same conflict group. When active, the system compares the start and end dates of bars that share the same Conflict Group Field value (configured on the mapping line). Overlapping bars are visually flagged with a warning indicator, helping planners spot double-bookings or scheduling conflicts. This is particularly valuable for machine scheduling, room booking, or any scenario where a single resource cannot handle concurrent assignments. Leave disabled if overlaps are acceptable in your domain.';
                }
                field("Enable View Switching"; Rec."Enable View Switching")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to show a view selector dropdown on the runtime Gantt host page, letting users switch between different hierarchy views without leaving the page. Each view can show the same source data organized in a different tree structure (e.g., by production order vs. by work center). When disabled, only the default view is accessible and no switcher is shown. Use this when you have configured multiple views under this setup and want users to toggle perspectives on the fly.';
                }
                field("Highest Parent Card Page ID"; Rec."Highest Parent Card Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the Page ID of the card page that should open when a user clicks on a bar that does not have a more specific Card Page ID set on its mapping line. This acts as a global fallback — for example, if you set this to the Production Order card page, clicking any bar without its own page mapping will open that production order card. Use the lookup to browse available pages. Leave blank if you do not want a click action on unmapped bars. Tip: set specific Card Page IDs on individual mapping lines first, and use this field only as a catch-all default.';
                }
            }
            part(ViewList; "DGOG Gantt View Part")
            {
                ApplicationArea = All;
                SubPageLink = "Setup ID" = field("ID");
                UpdatePropagation = Both;
            }
            part(MappingList; "DGOG Gantt Mapping Line Part")
            {
                ApplicationArea = All;
                Provider = ViewList;
                SubPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code");
                UpdatePropagation = Both;
            }
            part(DetailList; "DGOG Gantt Detail Line Part")
            {
                ApplicationArea = All;
                Provider = MappingList;
                SubPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Mapping Line No." = field("Line No."), "Source Table ID" = field("Source Table ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSetup)
            {
                ApplicationArea = All;
                Caption = 'Validate Setup';
                Image = Check;
                ToolTip = 'Run a comprehensive validation check on the entire setup, including all views, mapping lines, parent-child relations, field mappings, and filter configurations. The validator ensures that all referenced tables and fields exist, that parent line references form valid hierarchies, that required fields (such as Source Table ID and Key Field ID) are populated, and that no circular dependencies exist. If any issue is found, a detailed error message is shown. Run this action after making changes to confirm your configuration is ready for runtime use.';

                trigger OnAction()
                var
                    ValidationHelper: Codeunit "DGOG Gantt Validation Helper";
                begin
                    ValidationHelper.ValidateSetup(Rec);
                    Message('The setup is valid.');
                end;
            }
            action(OpenGantt)
            {
                ApplicationArea = All;
                Caption = 'Open Gantt';
                Image = Open;
                ToolTip = 'Launch the runtime Gantt host page for this setup. The chart will load using the default view and zoom level configured above. Use this to preview your configuration or to work with the Gantt as an end user. Any filters, edits, or view switches you make at runtime do not affect the setup configuration — they are session-level only. To make permanent changes, return to this setup card.';

                trigger OnAction()
                begin
                    Page.Run(Page::"DGOG Gantt Host", Rec);
                end;
            }
            action(ExportView)
            {
                ApplicationArea = All;
                Caption = 'Export View to Excel';
                Image = ExportToExcel;
                ToolTip = 'Export a single view and all of its related configuration to an Excel workbook. The export includes six sheets: View (header), Mapping Lines, Detail Lines, Grouping Lines, Mapping Relations, and Mapping Filters. Use this to create a portable backup of a view configuration, share it with colleagues for review, or transfer it to another setup using the Import action. After clicking, you will be prompted to select which view to export. The downloaded file preserves all field IDs, sequences, boolean flags, and enum values exactly as configured.';

                trigger OnAction()
                var
                    GanttView: Record "DGOG Gantt View";
                    ExcelExport: Codeunit "DGOG Gantt Excel Export";
                begin
                    GanttView.SetRange("Setup ID", Rec."ID");
                    if Page.RunModal(0, GanttView) <> Action::LookupOK then
                        exit;
                    ExcelExport.ExportView(Rec."ID", GanttView."View Code");
                end;
            }
            action(ImportView)
            {
                ApplicationArea = All;
                Caption = 'Import View from Excel';
                Image = ImportExcel;
                ToolTip = 'Import a view configuration from a previously exported Excel workbook into the current setup. The import reads all six sheets and recreates the view header, mapping lines, detail lines, grouping lines, mapping relations, and mapping filters under this setup. The View Code from the Excel must not already exist in this setup — a new view is always created. Use this to clone a view from one setup to another, restore a backup, or apply a template shared by another administrator. After import, review the created records and run Validate Setup to confirm everything is correct.';

                trigger OnAction()
                var
                    ExcelImport: Codeunit "DGOG Gantt Excel Import";
                begin
                    ExcelImport.ImportView(Rec."ID");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}