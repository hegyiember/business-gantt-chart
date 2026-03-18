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
                    ToolTip = 'Specifies the unique identifier of the Gantt setup.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name of the Gantt setup.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business purpose of this setup.';
                }
                field("Default View Code"; Rec."Default View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the view that opens first when the host page launches.';
                }
                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this setup can be launched at runtime.';
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
                ToolTip = 'Opens the runtime Gantt page for the selected setup.';

                trigger OnAction()
                begin
                    Page.Run(Page::"DGOG Gantt Host", Rec);
                end;
            }
        }
    }
}