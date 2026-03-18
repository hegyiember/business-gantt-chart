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
                field("View Code"; Rec."View Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which configured view this mapping line belongs to.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique mapping line number within the selected setup and view.';
                }
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source table that provides rows or bars for this mapping level.';
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent mapping line.';
                }
                field("Relation Field ID"; Rec."Relation Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the child table field that links this line to its parent business identity.';
                }
                field("Key Field ID"; Rec."Key Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the primary row label.';
                }
                field("Description Field ID"; Rec."Description Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the secondary row description.';
                }
                field("Start Date Field ID"; Rec."Start Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar start.';
                }
                field("End Date Field ID"; Rec."End Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar end.';
                }
                field("Due Date Field ID"; Rec."Due Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the due date marker.';
                }
                field("Status Field ID"; Rec."Status Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used for status-based coloring.';
                }
                field("Sequence Field ID"; Rec."Sequence Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field that orders sibling rows.';
                }
                field("Is Expandable"; Rec."Is Expandable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether rows generated from this mapping line can expand to show children.';
                }
                field("Is Editable"; Rec."Is Editable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether bars generated from this mapping line are editable.';
                }
                field("Card Page ID"; Rec."Card Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the preferred page opened when bars from this line are clicked.';
                }
                field("Context Identity Field ID"; Rec."Context Identity Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business identity used to preserve context across view switching.';
                }
                field("Resource Group Field ID"; Rec."Resource Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the grouping field used for aggregate utilization overlays.';
                }
                field("Dependency Source Field ID"; Rec."Dependency Source Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the predecessor dependency field.';
                }
                field("Dependency Target Field ID"; Rec."Dependency Target Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the successor dependency field.';
                }
                field("Dependency Type Field ID"; Rec."Dependency Type Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the dependency type field.';
                }
                field("Aggregation Value Field ID"; Rec."Aggregation Value Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the numeric load field for aggregate buckets.';
                }
                field("Aggregation Capacity Field ID"; Rec."Aggregation Capacity Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity field for aggregate buckets.';
                }
                field("Aggregation Bucket Mode"; Rec."Aggregation Bucket Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how aggregate buckets are grouped.';
                }
                field("Conflict Group Field ID"; Rec."Conflict Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used for overlap detection grouping.';
                }
                field("Progress Override Field ID"; Rec."Progress Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the direct progress percentage field.';
                }
                field("Color Override Field ID"; Rec."Color Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used to override the bar color.';
                }
                field("Label Override Field ID"; Rec."Label Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar label instead of the key text.';
                }
                field("Tooltip Title Field ID"; Rec."Tooltip Title Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the tooltip title.';
                }
            }
        }
    }
}