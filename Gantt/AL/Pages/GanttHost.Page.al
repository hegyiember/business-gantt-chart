page 71891731 "DGOG Gantt Host"
{
    ApplicationArea = All;
    Caption = 'Gantt';
    PageType = Card;
    SourceTable = "DGOG Gantt Setup";
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            usercontrol(GanttHost; "DGOG Gantt Diagram")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    IsControlReady := true;
                    LoadCurrentView(LastContextKey);
                end;

                trigger LogMessage(Category: Text; Level: Text; MessageText: Text; ContextJson: Text)
                begin
                    LastLogCategory := Category;
                    LastLogMessage := MessageText;
                end;

                trigger BarClicked(SourceTableId: Integer; SourceRecordId: Text; BarId: Text; PageId: Integer)
                begin
                    OpenSourcePage(SourceTableId, SourceRecordId, PageId);
                end;

                trigger SaveRequested(PendingChangesJson: Text)
                begin
                    HandleSaveRequested(PendingChangesJson);
                end;

                trigger ReloadRequested()
                begin
                    LoadCurrentView(LastContextKey);
                end;

                trigger ViewChangeRequested(NewViewCode: Text; ContextKey: Text)
                begin
                    ActiveViewCode := CopyStr(NewViewCode, 1, MaxStrLen(ActiveViewCode));
                    LastContextKey := ContextKey;
                    LoadCurrentView(ContextKey);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetFilters)
            {
                ApplicationArea = All;
                Caption = 'Set Filters';
                Image = FilterLines;
                ToolTip = 'Open a filter dialog that lets you apply runtime filters to the source tables used in the current view. This works similarly to a report request page — you can set filter criteria on any field of each source table. The filters are applied on top of any saved filter presets configured in the setup, and they persist for your current session only. After confirming the dialog, the Gantt reloads with the filtered data. Use this to narrow down the displayed bars without changing the setup configuration — for example, filter to a specific production order number, date range, or location code.';

                trigger OnAction()
                begin
                    RunFilterDialog();
                end;
            }
            action(ClearFilters)
            {
                ApplicationArea = All;
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Remove all runtime filters that were applied using the "Set Filters" action and reload the Gantt with the full unfiltered dataset (saved filter presets from the setup configuration still apply). Use this when you want to return to the default view after narrowing down the data. The chart reloads immediately after clearing.';

                trigger OnAction()
                begin
                    Clear(ActiveFilterViews);
                    HasActiveFilters := false;
                    LoadCurrentView(LastContextKey);
                    CurrPage.GanttHost.ShowNotification('Filters cleared.', 'info');
                end;
            }
            action(ReloadGantt)
            {
                ApplicationArea = All;
                Caption = 'Reload';
                Image = Refresh;
                ToolTip = 'Reload the Gantt chart from the authoritative Business Central database, discarding any unsaved client-side edits (bar moves or resizes that have not been saved). Use this to refresh the chart after external changes were made to the source data by other users or processes, or to discard your own drag-and-drop changes and start fresh. Any runtime filters you have set remain active after the reload. This does not affect the setup configuration.';

                trigger OnAction()
                begin
                    LoadCurrentView(LastContextKey);
                end;
            }
            action(RequestSave)
            {
                ApplicationArea = All;
                Caption = 'Save Pending Changes';
                Image = Save;
                ToolTip = 'Submit all pending bar edits (moves and resizes) from the client-side chart to Business Central for permanent storage. This writes the modified start and end date values back to the original source table records. A confirmation notification appears when the save completes successfully. If no changes are pending, nothing happens. This action is only functional when both "Allow Edit" and "Allow Save" are enabled on the setup. After saving, the chart automatically reloads with the updated data to confirm the changes were applied correctly.';

                trigger OnAction()
                begin
                    if IsControlReady then
                        CurrPage.GanttHost.RequestClientSave();
                end;
            }
            action(ZoomIn)
            {
                ApplicationArea = All;
                Caption = 'Zoom In';
                Image = ZoomIn;
                ToolTip = 'Increase the timeline zoom level by one step (10 percentage points). Zooming in shows more detail for shorter time spans — individual hours or days become wider, making it easier to position bars precisely and read labels on short-duration items. The maximum zoom level is 400%. The current zoom level persists for your session but resets to the setup default when you reopen the page.';

                trigger OnAction()
                begin
                    if IsControlReady then
                        CurrPage.GanttHost.SetZoom(CurrentZoom + 10);
                end;
            }
            action(ZoomOut)
            {
                ApplicationArea = All;
                Caption = 'Zoom Out';
                Image = ZoomOut;
                ToolTip = 'Decrease the timeline zoom level by one step (10 percentage points). Zooming out compresses the timeline so more time is visible on screen — useful for getting a high-level overview of weeks or months at a glance. The minimum zoom level is 30%. The current zoom level persists for your session but resets to the setup default when you reopen the page.';

                trigger OnAction()
                begin
                    if IsControlReady then
                        CurrPage.GanttHost.SetZoom(CurrentZoom - 10);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ActiveViewCode := ResolveInitialViewCode();
        CurrentZoom := Rec."Default Zoom %";
        if CurrentZoom = 0 then
            CurrentZoom := 100;
    end;

    var
        DataBuilder: Codeunit "DGOG Gantt Data Builder";
        SaveHandler: Codeunit "DGOG Gantt Save Handler";
        ActiveViewCode: Code[20];
        LastContextKey: Text;
        LastLogCategory: Text;
        LastLogMessage: Text;
        CurrentZoom: Integer;
        IsControlReady: Boolean;
        HasActiveFilters: Boolean;
        ActiveFilterViews: Dictionary of [Integer, Text];

    local procedure ResolveInitialViewCode(): Code[20]
    var
        GanttView: Record "DGOG Gantt View";
    begin
        if Rec."Default View Code" <> '' then
            exit(Rec."Default View Code");

        GanttView.SetRange("Setup ID", Rec."ID");
        GanttView.SetRange("Is Default", true);
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        GanttView.SetRange("Is Default");
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        exit('');
    end;

    local procedure LoadCurrentView(ContextKey: Text)
    var
        PayloadJson: Text;
    begin
        if not IsControlReady then
            exit;

        CurrPage.GanttHost.SetBusyState('Loading Gantt data...', true);
        if HasActiveFilters then
            PayloadJson := DataBuilder.BuildPayloadFiltered(Rec."ID", ActiveViewCode, ContextKey, ActiveFilterViews)
        else
            PayloadJson := DataBuilder.BuildPayload(Rec."ID", ActiveViewCode, ContextKey);
        CurrPage.GanttHost.LoadData(PayloadJson);
        CurrPage.GanttHost.SetZoom(CurrentZoom);
        CurrPage.GanttHost.SetBusyState('', false);
    end;

    local procedure RunFilterDialog()
    var
        AllObj: Record AllObjWithCaption;
        FilterPage: FilterPageBuilder;
        SourceTableIds: List of [Integer];
        TableId: Integer;
        TableCaption: Text;
        FilterViewText: Text;
        TableCaptions: Dictionary of [Integer, Text];
        FilterIndex: Integer;
    begin
        DataBuilder.CollectSourceTableIds(Rec."ID", ActiveViewCode, SourceTableIds);
        if SourceTableIds.Count() = 0 then begin
            Message('No source tables found in the current view.');
            exit;
        end;

        FilterPage.PageCaption('Gantt Data Filters');

        foreach TableId in SourceTableIds do begin
            AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
            AllObj.SetRange("Object ID", TableId);
            if AllObj.FindFirst() then
                TableCaption := AllObj."Object Caption"
            else
                TableCaption := Format(TableId);

            if not TableCaptions.ContainsKey(TableId) then begin
                FilterPage.AddTable(TableCaption, TableId);
                TableCaptions.Add(TableId, TableCaption);

                if HasActiveFilters and ActiveFilterViews.ContainsKey(TableId) then begin
                    FilterViewText := ActiveFilterViews.Get(TableId);
                    if FilterViewText <> '' then
                        FilterPage.SetView(TableCaption, FilterViewText);
                end;
            end;
        end;

        if not FilterPage.RunModal() then
            exit;

        Clear(ActiveFilterViews);
        HasActiveFilters := false;

        foreach TableId in SourceTableIds do begin
            if TableCaptions.ContainsKey(TableId) then begin
                TableCaption := TableCaptions.Get(TableId);
                FilterViewText := FilterPage.GetView(TableCaption, false);

                if FilterViewText <> '' then begin
                    if not ActiveFilterViews.ContainsKey(TableId) then
                        ActiveFilterViews.Add(TableId, FilterViewText);
                    HasActiveFilters := true;
                end;
            end;
        end;

        LoadCurrentView(LastContextKey);

        if HasActiveFilters then
            CurrPage.GanttHost.ShowNotification('Filters applied.', 'success')
        else
            CurrPage.GanttHost.ShowNotification('No filters set.', 'info');
    end;

    local procedure HandleSaveRequested(PendingChangesJson: Text)
    begin
        SaveHandler.ApplyPendingChanges(PendingChangesJson);
        CurrPage.GanttHost.ShowNotification('Pending changes were saved successfully.', 'success');
        LoadCurrentView(LastContextKey);
    end;

    local procedure OpenSourcePage(SourceTableId: Integer; SourceRecordIdText: Text; PageId: Integer)
    var
        SourceRecordId: RecordId;
        OpenPageId: Integer;
        SourceRef: RecordRef;
        RecordVariant: Variant;
    begin
        OpenPageId := PageId;
        if OpenPageId = 0 then
            OpenPageId := Rec."Highest Parent Card Page ID";
        if (OpenPageId = 0) or (SourceRecordIdText = '') then
            exit;

        Evaluate(SourceRecordId, SourceRecordIdText);
        SourceRef.Open(SourceTableId);
        if not SourceRef.Get(SourceRecordId) then
            exit;

        RecordVariant := SourceRef;
        Page.Run(OpenPageId, RecordVariant);
    end;
}