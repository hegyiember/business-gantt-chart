page 71891726 "DGOG Gantt Setup List"
{
    ApplicationArea = All;
    Caption = 'Gantt Setups';
    CardPageId = "DGOG Gantt Setup Card";
    Editable = true;
    PageType = List;
    SourceTable = "DGOG Gantt Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("ID"; Rec."ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The unique numeric identifier for this Gantt setup. Click the row to open the Setup Card where you can configure views, mapping lines, and all related settings. Each ID corresponds to one complete Gantt solution that can be launched independently at runtime.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The descriptive name of this Gantt setup, for example "Production Order Timeline" or "Service Schedule". Use a clear name so administrators can quickly identify the right configuration to open or modify from this list.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'A detailed explanation of the business scenario this setup covers. Review this column to understand what each setup does without needing to open the card. For example: "Visualizes released production orders with routing-level child bars and work center grouping."';
                }
                field("Default View Code"; Rec."Default View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows which view opens by default when the Gantt host page is launched for this setup. If blank, the system will use the first view marked as default or the first available view. You can change this on the Setup Card page.';
                }
                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this setup is currently available for runtime use. Toggle this directly in the list to quickly enable or disable a setup without opening the card. Inactive setups will not load any data when the Gantt host page is opened.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenGantt)
            {
                ApplicationArea = All;
                Caption = 'Open Gantt';
                Image = Open;
                ToolTip = 'Launch the runtime Gantt host page for the selected setup. This opens the interactive chart using the configured default view and zoom level. Use this to quickly preview how the Gantt looks with live data, or to work with the chart as an end user. You can also open the setup card first for configuration changes.';

                trigger OnAction()
                begin
                    Page.Run(Page::"DGOG Gantt Host", Rec);
                end;
            }
        }
    }
}