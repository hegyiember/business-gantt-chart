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
                    ToolTip = 'Specifies the unique identifier of the setup.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name shown to administrators and runtime users.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Specifies the purpose of the setup and the scenario it supports.';
                }
                field("Default View Code"; Rec."Default View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which view opens first in the runtime host.';
                }
                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this setup can be used at runtime.';
                }
                field("Default Zoom %"; Rec."Default Zoom %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the initial zoom level for the Gantt timeline.';
                }
                field("Default Time Grain"; Rec."Default Time Grain")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the initial time grain used when the Gantt page opens.';
                }
                field("Allow Edit"; Rec."Allow Edit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether runtime users are allowed to drag and resize bars.';
                }
                field("Allow Save"; Rec."Allow Save")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether runtime users are allowed to save pending edits.';
                }
                field("Enable Dependencies"; Rec."Enable Dependencies")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether configured dependency arrows are shown.';
                }
                field("Enable Aggregation"; Rec."Enable Aggregation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether aggregate load or utilization overlays are shown.';
                }
                field("Enable Conflict Detection"; Rec."Enable Conflict Detection")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether overlapping bars should be highlighted as conflicts.';
                }
                field("Enable View Switching"; Rec."Enable View Switching")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the runtime view switcher is available.';
                }
                field("Highest Parent Card Page ID"; Rec."Highest Parent Card Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fallback card page to open when clicking bars without a line-specific page mapping.';
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
                ToolTip = 'Validates the current setup and its view mappings.';

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
                ToolTip = 'Opens the runtime Gantt host page for this setup.';

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
                ToolTip = 'Exports the selected view and all its mapping lines, detail lines, grouping lines, relations, and filters to an Excel file.';

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
                ToolTip = 'Imports a view and all its child records from a previously exported Excel file into this setup.';

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