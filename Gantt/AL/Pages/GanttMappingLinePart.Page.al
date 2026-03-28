page 71891729 "DGOG Gantt Mapping Line Part"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Gantt Mapping Lines';
    DelayedInsert = true;
    Editable = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "DGOG Gantt Mapping Line";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the Business Central table that provides source records for this mapping level. Use the lookup to browse all available tables (e.g., table 5405 for Production Order, table 5409 for Prod. Order Routing Line). Every bar or row rendered at this hierarchy level will correspond to one record from this table. This is the most important field on the mapping line — all other field mappings (Key, Start Date, End Date, etc.) reference columns from this table. Choose carefully, as changing the source table after configuring field mappings will invalidate them.';
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the mapping line that serves as the parent of this line in the hierarchy tree. The dropdown shows all other mapping lines within the same setup and view. For example, if line 10000 maps Production Orders and this line maps Routing Lines, set the Parent Line No. to 10000 so that routing bars appear as children under their production order row. Leave blank for root-level mapping lines that have no parent. When a parent is set, you must also configure the "Map Parent Fields" relation to define how child records are linked to parent records (e.g., Prod. Order No. on the child matches No. on the parent).';
                }
                field("Key Field ID"; Rec."Key Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field from the source table that serves as the primary row label and business identity for this mapping level. This value is displayed as the row header on the left side of the Gantt chart and is used as the stable identifier when switching between views (if Context Identity is not separately configured). For Production Orders, this is typically the "No." field; for routing lines, it might be "Operation No.". Use the lookup button to browse all available fields on the source table. This is a required field — the Gantt cannot render rows without a key.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Key Field ID", Text));
                    end;
                }
                field("Key Field Name"; Rec."Key Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Key Field ID. This is a read-only lookup value shown for your convenience so you can verify the correct field was chosen without needing to remember field numbers.';
                }
                field("Description Field ID"; Rec."Description Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select an optional secondary field from the source table whose value is displayed below the key field text in the row header. This provides additional context — for example, if the key field is "No.", the description field could be "Description" to show the production order name alongside its number. Leave blank if the key field alone provides sufficient identification. Use the lookup to browse available fields.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Description Field ID", Text));
                    end;
                }
                field("Description Field Name"; Rec."Description Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Description Field ID. This read-only value helps you verify your selection at a glance.';
                }
                field("Start Date Field ID"; Rec."Start Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the date or datetime field from the source table that determines where each bar begins on the timeline. This is one of the two required date fields for rendering bars (along with End Date). For production orders, this is typically "Starting Date" or "Starting Date-Time". The field must be of type Date or DateTime — using other types will cause runtime errors. Use the lookup to browse available fields on the source table.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Start Date Field ID", Text));
                    end;
                }
                field("Start Date Field Name"; Rec."Start Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Start Date Field ID. This read-only value confirms which date field drives bar positioning.';
                }
                field("End Date Field ID"; Rec."End Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the date or datetime field from the source table that determines where each bar ends on the timeline. Together with Start Date, this defines the bar''s horizontal span. For production orders, this is typically "Ending Date" or "Ending Date-Time". If the end date is earlier than or equal to the start date, the bar will render as a zero-width marker. Use the lookup to browse available fields. When "Allow Edit" and "Is Editable" are both enabled, users can resize bars by dragging the right edge, which modifies this field value.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."End Date Field ID", Text));
                    end;
                }
                field("End Date Field Name"; Rec."End Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as End Date Field ID. This read-only value confirms which date field drives bar length.';
                }
                field("Due Date Field ID"; Rec."Due Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select an optional date field that represents a deadline or due date. When mapped, the Gantt chart renders a vertical marker (diamond or line) at this date position on each bar, giving users a visual cue of whether the bar''s end date extends past the deadline. This is useful for highlighting late orders or tasks approaching their due date. Leave blank if your source data does not have a meaningful deadline concept. Use the lookup to browse available date fields.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Due Date Field ID", Text));
                    end;
                }
                field("Due Date Field Name"; Rec."Due Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Due Date Field ID.';
                }
                field("Status Field ID"; Rec."Status Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field whose value determines the color or visual style of each bar based on its status. The Gantt frontend maps distinct status values (e.g., "Planned", "Released", "Finished") to predefined color schemes. This is typically an Option or Enum field such as "Status" on the production order table. When set, bars are automatically color-coded so users can visually distinguish between different states at a glance. Leave blank if you want all bars to use the default color, or use the Color Override Field for per-record custom colors instead.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Status Field ID", Text));
                    end;
                }
                field("Status Field Name"; Rec."Status Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Status Field ID.';
                }
                field("Sequence Field ID"; Rec."Sequence Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field whose value controls the vertical display order of sibling rows at this hierarchy level. Rows are sorted in ascending order by this field''s value. For routing lines, this is typically "Sequence No." or "Operation No.". If left blank, rows are displayed in the default order returned by the source table query (usually by primary key). Use this to ensure operations, tasks, or items appear in a logical sequence that matches the real-world process flow.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Sequence Field ID", Text));
                    end;
                }
                field("Sequence Field Name"; Rec."Sequence Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Sequence Field ID.';
                }
                field("Is Expandable"; Rec."Is Expandable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to allow rows generated from this mapping line to expand and reveal child rows from a child mapping line. When enabled, a collapse/expand toggle appears next to each row. The child mapping line must have its Parent Line No. set to this line and must have parent field relations configured via the "Map Parent Fields" action. If this is the lowest level in your hierarchy (a leaf level), leave this disabled. Example: enable on the Production Order mapping line so users can expand to see Routing Lines underneath.';
                }
                field("Is Editable"; Rec."Is Editable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable this to allow users to drag and resize bars generated from this specific mapping line at runtime. This works in conjunction with the setup-level "Allow Edit" flag — both must be enabled for bars to be interactive. When enabled, users can move bars left/right to reschedule, or drag the right edge to change duration. Changes remain client-side until saved. Leave disabled for mapping lines that represent read-only reference data or header-level rows that should not be moved.';
                }
                field("Card Page ID"; Rec."Card Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the Page ID of the card page that should open when a user clicks on a bar from this mapping line. Use the lookup to browse available pages. For example, set this to 99000831 for the Released Prod. Order card, or 5900 for the Service Order card. This provides line-level specificity — clicking a routing line bar could open the routing line card, while clicking a production order bar opens the production order card. If left blank, the system falls back to the setup-level "Highest Parent Card Page ID". Leave both blank if you do not want any click-through navigation.';
                }
                field("Context Identity Field ID"; Rec."Context Identity Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a field that provides a stable business identity used to preserve the user''s scroll position and expanded state when switching between views at runtime. For example, if two views show the same production orders but in different hierarchies (by order vs. by work center), setting Context Identity to "No." on both views allows the chart to keep the same order focused when the user toggles views. Leave blank if view switching is not used or if preserving context is not needed. Use the lookup to browse available fields.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Context Identity Field ID", Text));
                    end;
                }
                field("Context Identity Field Name"; Rec."Context Identity Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Context Identity Field ID.';
                }
                field("Resource Group Field ID"; Rec."Resource Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field that groups bars for aggregate utilization calculations. All bars sharing the same value in this field are treated as belonging to the same resource pool. For example, mapping this to "Work Center No." groups all routing line bars by work center, allowing the aggregation overlay to show how much capacity each work center consumes per time bucket. This field is only used when both setup-level "Enable Aggregation" and view-level "Aggregation Enabled" are turned on. Leave blank if this mapping line should not contribute to aggregation.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Resource Group Field ID", Text));
                    end;
                }
                field("Resource Group Field Name"; Rec."Resource Group Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Resource Group Field ID.';
                }
                field("Dependency Target Field ID"; Rec."Dependency Target Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field (referred to as "Field A" in dependency logic) that groups bars for automatic dependency arrow generation. Bars sharing the same value in this field are considered part of the same dependency chain, even if they belong to different parent rows. For example, on Prod. Order Routing Lines, setting this to "Prod. Order No." groups all operations of the same production order together. Within each group, the Dependency Order Field determines the arrow sequence. Both this field and the Dependency Order Field must be set for arrows to generate. Leave blank if this mapping line should not participate in dependency rendering.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Dependency Target Field ID", Text));
                    end;
                }
                field("Dep. Target Field Name"; Rec."Dep. Target Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Dependency Target Field ID.';
                }
                field("Dependency Order Field ID"; Rec."Dependency Order Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field (referred to as "Field B" in dependency logic) that determines the sequential order of dependency arrows within each dependency target group. The system sorts bars by this field in ascending order and draws an arrow from each bar to the immediate next bar with a higher unique value. For routing lines, this is typically "Sequence No." or "Operation No." — operation 10 connects to operation 20, 20 connects to 30, and so on. Both this field and the Dependency Target Field must be set for arrows to generate. Leave blank if dependencies are not needed for this mapping line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Dependency Order Field ID", Text));
                    end;
                }
                field("Dep. Order Field Name"; Rec."Dep. Order Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Dependency Order Field ID.';
                }
                field("Aggregation Value Field ID"; Rec."Aggregation Value Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the numeric field that provides the load value (e.g., hours, minutes, quantity) each bar contributes to its resource group per aggregation bucket. The system distributes each bar''s value proportionally across the time buckets it spans. For routing lines, this might be "Expected Operation Cost Amt." or "Run Time". This field is only used when aggregation is enabled at both setup and view level, and a Resource Group Field is also mapped. Leave blank if this mapping line should not contribute load data to the aggregation overlay.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Aggregation Value Field ID", Text));
                    end;
                }
                field("Agg. Value Field Name"; Rec."Agg. Value Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Aggregation Value Field ID.';
                }
                field("Aggregation Capacity Field ID"; Rec."Aggregation Capacity Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the numeric field that provides the maximum available capacity for the resource group per aggregation bucket. This is the denominator in the utilization percentage calculation (load ÷ capacity × 100). For work centers, this might be "Capacity (Effective)" or a fixed daily hours field. If all bars in a resource group share the same capacity, any one of them can supply the value. Leave blank to show absolute load values instead of utilization percentages.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Aggregation Capacity Field ID", Text));
                    end;
                }
                field("Agg. Capacity Field Name"; Rec."Agg. Capacity Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Aggregation Capacity Field ID.';
                }
                field("Aggregation Bucket Mode"; Rec."Aggregation Bucket Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Choose how aggregation time buckets are grouped: by Day, Week, or Month. This controls the granularity of the utilization overlay — "Day" creates one bucket per calendar day, "Week" groups by ISO week, and "Month" by calendar month. Choose a granularity that matches your planning horizon: use Day for short-cycle production scheduling, Week for mid-range planning, and Month for long-term capacity overviews. This setting only applies when aggregation is enabled and the Aggregation Value Field is mapped.';
                }
                field("Conflict Group Field ID"; Rec."Conflict Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field that groups bars for overlap (conflict) detection. All bars sharing the same value in this field are checked for date range overlaps — if two bars in the same group have overlapping start-to-end ranges, they are flagged as conflicts with a visual warning indicator. For machine scheduling, map this to "Machine Center No." to detect double-bookings. For room booking, map to "Room No.". This only works when conflict detection is enabled at both setup and view level. Leave blank if this mapping line should not participate in conflict checks.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Conflict Group Field ID", Text));
                    end;
                }
                field("Conflict Group Field Name"; Rec."Conflict Group Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Conflict Group Field ID.';
                }
                field("Progress Override Field ID"; Rec."Progress Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a numeric field (Decimal or Integer, range 0–100) that directly provides the completion percentage for each bar. When mapped, this value is used as-is to render the progress fill inside the bar (e.g., a value of 75 fills 75% of the bar). This overrides the numerator/denominator progress calculation from Start Decimal and End Decimal fields. Use this when your source data already has a precomputed progress percentage. Leave blank to fall back to the Start/End Decimal calculation, or to show no progress indicator at all.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Progress Override Field ID", Text));
                    end;
                }
                field("Progress Ovr. Field Name"; Rec."Progress Ovr. Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Progress Override Field ID.';
                }
                field("Color Override Field ID"; Rec."Color Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a text field that provides an explicit color value for each bar, overriding the default status-based coloring. The field value should contain a valid CSS color string (e.g., "#FF5733", "rgb(255,87,51)", or a named color like "tomato"). Use this when you need per-record color control that goes beyond the standard status palette — for example, color-coding bars by priority level stored as a hex code in a custom field. Leave blank to use the default status-based or theme-based bar colors.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Color Override Field ID", Text));
                    end;
                }
                field("Color Override Field Name"; Rec."Color Override Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Color Override Field ID.';
                }
                field("Label Override Field ID"; Rec."Label Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a text field whose value replaces the default key field text as the label displayed inside each bar on the Gantt chart. By default, bars show the Key Field value — use this override when you want a different or shorter label. For example, the Key Field might be "No." (a long code) while the Label Override could be "Short Description" for a more readable bar label. Leave blank to keep the default key field value as the bar label.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Label Override Field ID", Text));
                    end;
                }
                field("Label Override Field Name"; Rec."Label Override Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Label Override Field ID.';
                }
                field("Tooltip Title Field ID"; Rec."Tooltip Title Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the field whose value is used as the bold title line in the hover tooltip that appears when users mouse over a bar or row. By default, the tooltip title uses the Key Field value — use this override to show a more descriptive field instead. For example, use "Description" as the tooltip title while keeping "No." as the bar label. The tooltip body is populated from the Detail Lines configured below. Leave blank to use the Key Field value as the tooltip title.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Tooltip Title Field ID", Text));
                    end;
                }
                field("Tooltip Title Field Name"; Rec."Tooltip Title Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Displays the caption of the field selected as Tooltip Title Field ID.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MapGroupingFields)
            {
                ApplicationArea = All;
                Caption = 'Map Grouping Fields';
                Image = List;
                ToolTip = 'Open the ordered grouping field list for the currently selected mapping line. Grouping fields define how source records are visually grouped in the Gantt chart — for example, grouping routing lines by Work Center creates collapsible work center sections. You can add multiple grouping levels that nest inside each other (e.g., first by Work Center, then by Machine Center). The order of the grouping lines determines the nesting hierarchy. Each grouping field must exist on the same source table as the mapping line.';
                RunObject = Page "DGOG Gantt Grouping List";
                RunPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Mapping Line No." = field("Line No.");
            }
            action(MapParentFields)
            {
                ApplicationArea = All;
                Caption = 'Map Parent Fields';
                Image = LinkAccount;
                ToolTip = 'Open the field-pair mapping list that defines how records from this mapping line are linked to records from its parent mapping line. Each pair specifies one field on the current (child) table and one field on the parent table — when their values match, the child record is nested under that parent row. For example, to link Prod. Order Routing Lines to Production Orders, map "Prod. Order No." on the child table to "No." on the parent table. You can define multiple field pairs for composite keys (e.g., Prod. Order No. + Status). The parent mapping line must be set via "Parent Line No." before this action becomes useful.';
                RunObject = Page "DGOG Gantt Mapping Rel. List";
                RunPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code");
            }
            action(ManageFilters)
            {
                ApplicationArea = All;
                Caption = 'Manage Filters';
                Image = FilterLines;
                ToolTip = 'Open the saved filter presets for the currently selected mapping line. Filter presets allow you to pre-define which source records are included when the Gantt loads — for example, filtering production orders to only show "Released" status, or limiting to a specific location code. You can create multiple filter presets and mark one as active. The active filter is applied automatically every time the Gantt data is built for this mapping line. Inactive presets are saved for quick switching. Use the "Create / Edit Filter" action on the filter list page to visually define filter criteria using the standard Business Central filter dialog.';
                RunObject = Page "DGOG Gantt Mapping Filter List";
                RunPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Mapping Line No." = field("Line No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        GrantMappingLine: Record "DGOG Gantt Mapping Line";
    begin
        GrantMappingLine.SetRange("Setup ID", Rec."Setup ID");
        GrantMappingLine.SetRange("View Code", Rec."View Code");
        if GrantMappingLine.FindLast() then
            Rec."Line No." := GrantMappingLine."Line No." + 10000
        else
            Rec."Line No." := 10000;
    end;

    local procedure LookupSourceField(var FieldId: Integer; var Text: Text): Boolean
    var
        FieldRec: Record Field;
    begin
        if Rec."Source Table ID" = 0 then
            exit(false);

        FieldRec.FilterGroup(2);
        FieldRec.SetRange(TableNo, Rec."Source Table ID");
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        FieldRec.FilterGroup(0);

        if FieldId <> 0 then
            if FieldRec.Get(Rec."Source Table ID", FieldId) then;

        if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
            FieldId := FieldRec."No.";
            Text := Format(FieldId);
            exit(true);
        end;

        exit(false);
    end;
}