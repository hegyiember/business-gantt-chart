controladdin "DGOG Gantt Diagram"
{
    HorizontalStretch = true;
    VerticalStretch = true;
    MinimumHeight = 480;
    RequestedHeight = 760;
    Scripts = 'Gantt/Frontend/Scripts/GanttChart.js';
    StartupScript = 'Gantt/Frontend/Scripts/GanttStartup.js';
    StyleSheets = 'Gantt/Frontend/Resources/GanttChart.css';

    event ControlReady();
    event LogMessage(Category: Text; Level: Text; MessageText: Text; ContextJson: Text);
    event BarClicked(SourceTableId: Integer; SourceRecordId: Text; BarId: Text; PageId: Integer);
    event SaveRequested(PendingChangesJson: Text);
    event ReloadRequested();
    event ViewChangeRequested(NewViewCode: Text; ContextKey: Text);

    procedure LoadData(PayloadJson: Text);
    procedure ShowNotification(MessageText: Text; Level: Text);
    procedure SetBusyState(CaptionText: Text; IsBusy: Boolean);
    procedure SetZoom(ZoomPercent: Integer);
    procedure RequestClientSave();
    procedure RequestClientReload();
}
