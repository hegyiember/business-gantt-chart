page 71891731 "LVE Gantt Host"
{
    ApplicationArea = All;
    Caption = 'Gantt';
    PageType = Card;
    SourceTable = "LVE Gantt Setup";
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            usercontrol(GanttHost; "LVE Gantt Diagram")
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
        DataBuilder: Codeunit "LVE Gantt Data Builder";
        SaveHandler: Codeunit "LVE Gantt Save Handler";
        ActiveViewCode: Code[20];
        LastContextKey: Text;
        LastLogCategory: Text;
        LastLogMessage: Text;
        CurrentZoom: Integer;
        IsControlReady: Boolean;

    local procedure ResolveInitialViewCode(): Code[20]
    var
        GanttView: Record "LVE Gantt View";
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
        PayloadJson := DataBuilder.BuildPayload(Rec."ID", ActiveViewCode, ContextKey);
        CurrPage.GanttHost.LoadData(PayloadJson);
        CurrPage.GanttHost.SetZoom(CurrentZoom);
        CurrPage.GanttHost.SetBusyState('', false);
    end;

    local procedure HandleSaveRequested(PendingChangesJson: Text)
    begin
        SaveHandler.ApplyPendingChanges(PendingChangesJson);
        CurrPage.GanttHost.ShowNotification('Pending changes were saved successfully.', 'success');
        LoadCurrentView(LastContextKey);
    end;

    local procedure OpenSourcePage(SourceTableId: Integer; SourceRecordIdText: Text; PageId: Integer)
    var
        OpenPageId: Integer;
        SourceRecordId: RecordId;
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
