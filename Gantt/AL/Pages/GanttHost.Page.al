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
                ToolTip = 'Opens a filter dialog for the source tables used in the current view, similar to a report request page.';

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
                ToolTip = 'Clears all runtime filters and reloads the Gantt.';

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
                ToolTip = 'Reloads the Gantt from authoritative Business Central data and discards unsaved client-side edits.';

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
                ToolTip = 'Asks the client control to submit all pending edits to the AL save handler.';

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
                ToolTip = 'Increases the client-side zoom level by one step.';

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
                ToolTip = 'Decreases the client-side zoom level by one step.';

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

            // Ensure unique caption per table (FilterPageBuilder requires unique names)
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
