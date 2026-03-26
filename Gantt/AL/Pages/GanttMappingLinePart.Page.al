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
                    ToolTip = 'Specifies the source table that provides rows or bars for this mapping level.';
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent mapping line.';
                }
                field("Key Field ID"; Rec."Key Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the primary row label.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Key Field ID", Text));
                    end;
                }
                field("Key Field Name"; Rec."Key Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected key field.';
                }
                field("Description Field ID"; Rec."Description Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the secondary row description.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Description Field ID", Text));
                    end;
                }
                field("Description Field Name"; Rec."Description Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected description field.';
                }
                field("Start Date Field ID"; Rec."Start Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar start.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Start Date Field ID", Text));
                    end;
                }
                field("Start Date Field Name"; Rec."Start Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected start date field.';
                }
                field("End Date Field ID"; Rec."End Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar end.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."End Date Field ID", Text));
                    end;
                }
                field("End Date Field Name"; Rec."End Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected end date field.';
                }
                field("Due Date Field ID"; Rec."Due Date Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the due date marker.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Due Date Field ID", Text));
                    end;
                }
                field("Due Date Field Name"; Rec."Due Date Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected due date field.';
                }
                field("Status Field ID"; Rec."Status Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used for status-based coloring.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Status Field ID", Text));
                    end;
                }
                field("Status Field Name"; Rec."Status Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected status field.';
                }
                field("Sequence Field ID"; Rec."Sequence Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field that orders sibling rows.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Sequence Field ID", Text));
                    end;
                }
                field("Sequence Field Name"; Rec."Sequence Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected sequence field.';
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

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Context Identity Field ID", Text));
                    end;
                }
                field("Context Identity Field Name"; Rec."Context Identity Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected context identity field.';
                }
                field("Resource Group Field ID"; Rec."Resource Group Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the grouping field used for aggregate utilization overlays.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Resource Group Field ID", Text));
                    end;
                }
                field("Resource Group Field Name"; Rec."Resource Group Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected resource group field.';
                }
                field("Dependency Target Field ID"; Rec."Dependency Target Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Field A, which groups child elements for dependency generation across the grid.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Dependency Target Field ID", Text));
                    end;
                }
                field("Dep. Target Field Name"; Rec."Dep. Target Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected dependency target field.';
                }
                field("Dependency Order Field ID"; Rec."Dependency Order Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Field B, which determines the immediate-next ascending dependency order within the same Field A group.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Dependency Order Field ID", Text));
                    end;
                }
                field("Dep. Order Field Name"; Rec."Dep. Order Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected dependency order field.';
                }
                field("Aggregation Value Field ID"; Rec."Aggregation Value Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the numeric load field for aggregate buckets.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Aggregation Value Field ID", Text));
                    end;
                }
                field("Agg. Value Field Name"; Rec."Agg. Value Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected aggregation value field.';
                }
                field("Aggregation Capacity Field ID"; Rec."Aggregation Capacity Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity field for aggregate buckets.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Aggregation Capacity Field ID", Text));
                    end;
                }
                field("Agg. Capacity Field Name"; Rec."Agg. Capacity Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected aggregation capacity field.';
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

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Conflict Group Field ID", Text));
                    end;
                }
                field("Conflict Group Field Name"; Rec."Conflict Group Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected conflict group field.';
                }
                field("Progress Override Field ID"; Rec."Progress Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the direct progress percentage field.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Progress Override Field ID", Text));
                    end;
                }
                field("Progress Ovr. Field Name"; Rec."Progress Ovr. Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected progress override field.';
                }
                field("Color Override Field ID"; Rec."Color Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used to override the bar color.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Color Override Field ID", Text));
                    end;
                }
                field("Color Override Field Name"; Rec."Color Override Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected color override field.';
                }
                field("Label Override Field ID"; Rec."Label Override Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the bar label instead of the key text.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Label Override Field ID", Text));
                    end;
                }
                field("Label Override Field Name"; Rec."Label Override Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected label override field.';
                }
                field("Tooltip Title Field ID"; Rec."Tooltip Title Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field used as the tooltip title.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourceField(Rec."Tooltip Title Field ID", Text));
                    end;
                }
                field("Tooltip Title Field Name"; Rec."Tooltip Title Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the caption of the selected tooltip title field.';
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
                ToolTip = 'Opens the ordered grouping-field list for the current mapping line.';
                RunObject = Page "DGOG Gantt Grouping List";
                RunPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code"), "Mapping Line No." = field("Line No.");
            }
            action(MapParentFields)
            {
                ApplicationArea = All;
                Caption = 'Map Parent Fields';
                Image = LinkAccount;
                ToolTip = 'Opens the field-pair list that links the current line to its parent line.';
                RunObject = Page "DGOG Gantt Mapping Rel. List";
                RunPageLink = "Setup ID" = field("Setup ID"), "View Code" = field("View Code");
            }
            action(ManageFilters)
            {
                ApplicationArea = All;
                Caption = 'Manage Filters';
                Image = FilterLines;
                ToolTip = 'Opens the saved filter presets for the current mapping line. Active filters apply automatically when the Gantt loads.';
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
