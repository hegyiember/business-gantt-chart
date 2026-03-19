(function () {
  function invoke(eventName, args) {
    try {
      if (window.Microsoft && Microsoft.Dynamics && Microsoft.Dynamics.NAV) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(eventName, args || []);
      }
    } catch (error) {
      console.error('[GANTT][invoke-error]', eventName, error);
    }
  }

  function toDate(value) {
    if (!value) return null;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function startOfDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0);
  }

  function startOfWeek(date) {
    const day = date.getDay();
    const diff = (day + 6) % 7;
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() - diff, 0, 0, 0, 0);
  }

  function startOfMonth(date) {
    return new Date(date.getFullYear(), date.getMonth(), 1, 0, 0, 0, 0);
  }

  function startOfYear(date) {
    return new Date(date.getFullYear(), 0, 1, 0, 0, 0, 0);
  }

  function addDays(date, amount) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + amount, 0, 0, 0, 0);
  }

  function addMonths(date, amount) {
    return new Date(date.getFullYear(), date.getMonth() + amount, 1, 0, 0, 0, 0);
  }

  function addYears(date, amount) {
    return new Date(date.getFullYear() + amount, 0, 1, 0, 0, 0, 0);
  }

  function getIsoWeek(date) {
    const target = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNr = (target.getUTCDay() + 6) % 7;
    target.setUTCDate(target.getUTCDate() - dayNr + 3);
    const firstThursday = new Date(Date.UTC(target.getUTCFullYear(), 0, 4));
    const firstDayNr = (firstThursday.getUTCDay() + 6) % 7;
    firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNr + 3);
    return 1 + Math.round((target - firstThursday) / 604800000);
  }

  class LVEGanttChart {
    constructor(rootElement) {
      this.root = rootElement;
      this.payload = null;
      this.zoom = 100;
      this.timeGrain = 'Day';
      this.effectiveTimeGrain = 'Day';
      this.pendingChanges = [];
      this.pendingByKey = new Map();
      this.dirty = false;
      this.selectedBarId = '';
      this.dragState = null;
      this.expandedRows = new Set();
      this.expandedStatusGroups = new Set();
      this.visibleRows = [];
      this.childRowsByParent = new Map();
      this.barMapByRow = new Map();
      this.barByDependencyKey = new Map();
      this.barById = new Map();
      this.rowIndexById = new Map();
      this.mappingLineMetaByNo = new Map();
      this.conflictingBarIds = new Set();
      this.rowsWithConflict = new Set();
      this.hoverTooltip = null;
      this.ui = {};
      this.timelineCols = [];
      this.timelineStart = null;
      this.timelineEnd = null;
      this.viewportWidth = 0;
      this.totalTimelineWidth = 0;
      this.totalContentHeight = 0;
      this.lastScrollLeft = 0;
      this.miniMapEnabled = true;
      this.rowHeight = 48;
      this.statusGroupHeaderHeight = 16;
      this.statusLabelWidth = 112;
      this.statusRailWidth = 20;
      this.rowOverscan = 12;
      this.renderFrame = 0;
      this.dependencyRenderFrame = 0;
      this.lastDependencyDebugSignature = '';
    }

    log(category, level, message, context) {
      invoke('LogMessage', [category, level, message, JSON.stringify(context || {})]);
    }

    init() {
      this.root.classList.add('lve-gantt-root');
      this.root.innerHTML = `
        <div class="lve-gantt-shell">
          <div class="lve-gantt-toolbar">
            <div class="lve-left-controls">
              <button class="lve-btn" data-action="zoom-out" title="Zoom out" type="button">−</button>
              <span class="lve-zoom-label">100%</span>
              <button class="lve-btn" data-action="zoom-in" title="Zoom in" type="button">+</button>
              <div class="lve-timegrain-group" aria-label="Time grain"></div>
              <div class="lve-view-group" aria-label="View selector"></div>
            </div>
            <div class="lve-right-controls">
              <button class="lve-btn" data-action="reload" type="button">Reload</button>
              <button class="lve-btn lve-btn-primary" data-action="save" type="button" disabled>Save</button>
            </div>
          </div>
          <div class="lve-status-strip">
            <span class="lve-status-item"><i class="dot planned"></i>Planned</span>
            <span class="lve-status-item"><i class="dot firm"></i>Firm Planned</span>
            <span class="lve-status-item"><i class="dot released"></i>Released</span>
            <span class="lve-status-item"><i class="dot finished"></i>Finished</span>
            <span class="lve-dirty-indicator" hidden>Unsaved changes</span>
          </div>
          <div class="lve-gantt-board">
            <div class="lve-label-pane"></div>
            <div class="lve-grid-pane">
              <div class="lve-timeline-head"></div>
              <div class="lve-scroll-body">
                <div class="lve-grid-canvas">
                  <svg class="lve-dependency-layer"></svg>
                </div>
              </div>
            </div>
          </div>
          <div class="lve-minimap-wrap" hidden>
            <canvas class="lve-minimap" height="40"></canvas>
            <div class="lve-minimap-viewport"></div>
          </div>
          <div class="lve-empty-state" hidden>No records to display</div>
          <div class="lve-error-state" hidden></div>
        </div>`;

      this.cacheDom();
      this.bindUiEvents();
      this.hoverTooltip = document.createElement('div');
      this.hoverTooltip.className = 'lve-tooltip';
      this.hoverTooltip.hidden = true;
      this.root.appendChild(this.hoverTooltip);
      this.log('Initialization', 'info', 'Gantt chart initialized', { ready: true });
    }

    cacheDom() {
      const shell = this.root.querySelector('.lve-gantt-shell');
      this.ui = {
        shell,
        zoomLabel: shell.querySelector('.lve-zoom-label'),
        saveButton: shell.querySelector('[data-action="save"]'),
        reloadButton: shell.querySelector('[data-action="reload"]'),
        timegrainGroup: shell.querySelector('.lve-timegrain-group'),
        viewGroup: shell.querySelector('.lve-view-group'),
        labelPane: shell.querySelector('.lve-label-pane'),
        timelineHead: shell.querySelector('.lve-timeline-head'),
        scrollBody: shell.querySelector('.lve-scroll-body'),
        gridCanvas: shell.querySelector('.lve-grid-canvas'),
        dependencyLayer: shell.querySelector('.lve-dependency-layer'),
        dirtyIndicator: shell.querySelector('.lve-dirty-indicator'),
        emptyState: shell.querySelector('.lve-empty-state'),
        errorState: shell.querySelector('.lve-error-state'),
        minimapWrap: shell.querySelector('.lve-minimap-wrap'),
        minimap: shell.querySelector('.lve-minimap'),
        minimapViewport: shell.querySelector('.lve-minimap-viewport'),
        labelHead: null,
        labelViewport: null,
        labelSurface: null,
        gridBackground: null,
        gridRowLayer: null,
        gridBarLayer: null,
        timelineTrack: null
      };
    }

    bindUiEvents() {
      this.root.addEventListener('click', (event) => {
        const actionButton = event.target.closest('[data-action]');
        if (!actionButton) return;
        const action = actionButton.getAttribute('data-action');
        if (action === 'zoom-in') this.setZoom(this.zoom + 10);
        if (action === 'zoom-out') this.setZoom(this.zoom - 10);
        if (action === 'save') this.requestClientSave();
        if (action === 'reload') this.requestClientReload();
      });

      this.ui.timegrainGroup.addEventListener('click', (event) => {
        const button = event.target.closest('[data-grain]');
        if (!button) return;
        const centerDate = this.getViewportCenterDate();
        this.timeGrain = this.normalizeTimeGrain(button.getAttribute('data-grain'));
        this.syncTimegrainButtons();
        this.render();
        this.restoreViewportCenter(this.getGrainFocusDate(centerDate, this.effectiveTimeGrain));
        this.log('View', 'info', 'Time grain changed', { timeGrain: this.timeGrain, effectiveGrain: this.effectiveTimeGrain });
      });

      this.ui.viewGroup.addEventListener('click', (event) => {
        const button = event.target.closest('[data-view-code]');
        if (!button) return;
        const contextKey = this.getSelectedContextKey();
        invoke('ViewChangeRequested', [button.getAttribute('data-view-code') || '', contextKey]);
      });

      this.ui.scrollBody.addEventListener('scroll', () => {
        this.lastScrollLeft = this.ui.scrollBody.scrollLeft;
        this.syncTimelineHeaderPosition();
        this.syncLabelViewport();
        this.scheduleViewportRender();
        this.syncMiniMapViewport();
      });

      this.ui.scrollBody.addEventListener(
        'wheel',
        (event) => {
          if (!event.ctrlKey) return;
          event.preventDefault();
          this.setZoom(this.zoom + (event.deltaY < 0 ? 10 : -10));
        },
        { passive: false }
      );

      this.root.addEventListener('mousemove', (event) => this.onPointerMove(event));
      this.root.addEventListener('mouseup', () => this.finishDrag());
      this.root.addEventListener('mouseleave', () => this.finishDrag());
    }

    load(payload) {
      const previousExpandedRows = new Set(this.expandedRows);
      const previousExpandedStatusGroups = new Set(this.expandedStatusGroups);
      const previousStatusKeys = new Set((this.payload?.rows || []).map((row) => this.getNormalizedStatusValue(row)).filter(Boolean));
      const preserveExpandedState = !!this.payload;
      const previousViewState = preserveExpandedState ? this.captureViewState() : null;

      this.payload = payload || {};
      this.pendingChanges = [];
      this.pendingByKey.clear();
      this.dirty = false;
      this.selectedBarId = '';
      this.dragState = null;

      const setup = this.payload.setup || {};
      this.timeGrain = preserveExpandedState
        ? this.normalizeTimeGrain(previousViewState?.timeGrain || this.timeGrain)
        : this.normalizeTimeGrain(setup.defaultTimeGrain || this.timeGrain);
      this.zoom = preserveExpandedState
        ? clamp(Math.round(Number(previousViewState?.zoom || this.zoom) / 10) * 10, 30, 400)
        : clamp(Math.round(Number(setup.defaultZoom || this.zoom) / 10) * 10, 30, 400);
      this.ui.zoomLabel.textContent = `${this.zoom}%`;
      this.seedExpandedRows(previousExpandedRows, preserveExpandedState);
      this.seedExpandedStatusGroups(previousExpandedStatusGroups, previousStatusKeys, preserveExpandedState);
      this.render();
      if (preserveExpandedState) this.restoreViewState(previousViewState);
    }

    seedExpandedRows(previousExpandedRows, preserveExpandedState) {
      const rows = this.payload?.rows || [];
      const validRowIds = new Set(rows.filter((row) => row && row.rowId).map((row) => row.rowId));
      this.expandedRows.clear();

      if (preserveExpandedState) {
        previousExpandedRows.forEach((rowId) => {
          if (validRowIds.has(rowId)) this.expandedRows.add(rowId);
        });
        return;
      }

      rows.forEach((row) => {
        if (row && row.isExpanded && validRowIds.has(row.rowId)) this.expandedRows.add(row.rowId);
      });
    }

    seedExpandedStatusGroups(previousExpandedStatusGroups, previousStatusKeys, preserveExpandedState) {
      const currentStatusKeys = new Set((this.payload?.rows || []).map((row) => this.getNormalizedStatusValue(row)).filter(Boolean));
      this.expandedStatusGroups.clear();

      if (!preserveExpandedState) {
        currentStatusKeys.forEach((statusKey) => this.expandedStatusGroups.add(statusKey));
        return;
      }

      previousExpandedStatusGroups.forEach((statusKey) => {
        if (currentStatusKeys.has(statusKey)) this.expandedStatusGroups.add(statusKey);
      });

      currentStatusKeys.forEach((statusKey) => {
        if (!previousStatusKeys.has(statusKey)) this.expandedStatusGroups.add(statusKey);
      });
    }

    normalizeTimeGrain(value) {
      switch (String(value || '').trim().toLowerCase()) {
        case 'day':
          return 'Day';
        case 'week':
          return 'Week';
        case 'month':
          return 'Month';
        case 'year':
          return 'Year';
        case 'hour':
          return 'Hour';
        default:
          return 'Day';
      }
    }

    setZoom(value) {
      const centerDate = this.getViewportCenterDate();
      this.zoom = clamp(Math.round(value / 10) * 10, 30, 400);
      this.ui.zoomLabel.textContent = `${this.zoom}%`;
      this.render();
      this.restoreViewportCenter(centerDate);
      window.requestAnimationFrame(() => {
        this.syncTimelineHeaderPosition();
        this.syncLabelViewport();
        this.syncMiniMapViewport();
      });
      this.log('View', 'info', 'Zoom changed', { zoom: this.zoom, grain: this.timeGrain, effectiveGrain: this.effectiveTimeGrain });
    }

    getViewportCenterDate() {
      const body = this.ui.scrollBody;
      if (!body || !this.timelineStart || !this.timelineEnd || this.totalTimelineWidth <= 0) return null;
      return this.xToDate(body.scrollLeft + body.clientWidth / 2);
    }

    captureViewState() {
      const body = this.ui.scrollBody;
      return {
        timeGrain: this.timeGrain,
        zoom: this.zoom,
        centerDate: this.getViewportCenterDate(),
        scrollLeft: body?.scrollLeft || 0,
        scrollTop: body?.scrollTop || 0
      };
    }

    restoreViewportCenter(centerDate) {
      const body = this.ui.scrollBody;
      if (!body || !centerDate || !this.timelineStart || !this.timelineEnd) {
        this.syncTimelineHeaderPosition();
        return;
      }
      const desiredScrollLeft = this.dateToX(centerDate) - body.clientWidth / 2;
      body.scrollLeft = clamp(desiredScrollLeft, 0, Math.max(0, this.totalTimelineWidth - body.clientWidth));
      this.lastScrollLeft = body.scrollLeft;
      this.syncTimelineHeaderPosition();
      this.syncLabelViewport();
      this.syncMiniMapViewport();
    }

    restoreViewState(viewState) {
      const body = this.ui.scrollBody;
      if (!body || !viewState) return;

      const maxScrollTop = Math.max(0, this.totalContentHeight - body.clientHeight);
      body.scrollTop = clamp(viewState.scrollTop || 0, 0, maxScrollTop);

      if (viewState.centerDate) {
        this.restoreViewportCenter(viewState.centerDate);
        return;
      }

      body.scrollLeft = clamp(viewState.scrollLeft || 0, 0, Math.max(0, this.totalTimelineWidth - body.clientWidth));
      this.lastScrollLeft = body.scrollLeft;
      this.syncTimelineHeaderPosition();
      this.syncLabelViewport();
      this.syncMiniMapViewport();
    }

    getGrainFocusDate(centerDate, grain) {
      if (!centerDate) return null;
      const normalizedGrain = this.normalizeTimeGrain(grain);
      if (normalizedGrain === 'Day') return centerDate;

      const bucketStart = this.alignDateToGrain(centerDate, normalizedGrain);
      const bucketEnd = this.advanceDateByGrain(bucketStart, normalizedGrain, 1);
      return new Date(bucketStart.getTime() + (bucketEnd.getTime() - bucketStart.getTime()) / 2);
    }

    syncTimelineHeaderPosition() {
      if (!this.ui.timelineTrack || !this.ui.scrollBody) return;
      const scrollLeft = this.ui.scrollBody.scrollLeft;
      this.lastScrollLeft = scrollLeft;
      this.ui.timelineTrack.style.transform = `translate3d(${-scrollLeft}px, 0, 0)`;
    }

    setBusy(caption, isBusy) {
      this.root.classList.toggle('is-busy', !!isBusy);
      this.root.setAttribute('data-busy-caption', caption || '');
    }

    showNotification(message, level) {
      this.log('Interaction', level || 'info', message, {});
      if (!message) return;
      this.ui.errorState.hidden = true;
      this.ui.emptyState.hidden = true;
      this.ui.dirtyIndicator.textContent = message;
      this.ui.dirtyIndicator.hidden = false;
      setTimeout(() => {
        if (!this.dirty) this.ui.dirtyIndicator.hidden = true;
      }, 2500);
    }

    requestClientSave() {
      if (!this.dirty || !(this.payload?.setup || {}).allowSave) return;
      invoke('SaveRequested', [JSON.stringify(this.pendingChanges)]);
      this.log('Edit', 'info', 'Save requested', { count: this.pendingChanges.length });
    }

    requestClientReload() {
      invoke('ReloadRequested', []);
      this.log('Edit', 'info', 'Reload requested', {});
    }

    scheduleViewportRender() {
      if (this.renderFrame) return;
      this.renderFrame = window.requestAnimationFrame(() => {
        this.renderFrame = 0;
        this.renderViewport();
      });
    }

    render() {
      if (!this.payload) return;
      const rows = this.payload.rows || [];
      const bars = this.payload.bars || [];
      this.ui.emptyState.hidden = rows.length > 0;
      this.ui.errorState.hidden = true;

      this.syncTimegrainButtons();
      this.syncViewButtons();

      if (!rows.length) {
        this.ui.labelPane.innerHTML = '';
        this.ui.timelineHead.innerHTML = '';
        this.ui.gridCanvas.innerHTML = '<svg class="lve-dependency-layer"></svg>';
        this.ui.dependencyLayer = this.ui.gridCanvas.querySelector('.lve-dependency-layer');
        this.ui.timelineTrack = null;
        this.renderDirtyState();
        return;
      }

      this.indexBars(bars);
      this.computeVisibleRows(rows);
      this.buildDerivedCaches();
      this.computeTimeline();
      this.renderTimelineHeader();
      this.renderRowsAndGrid();
      this.syncTimelineHeaderPosition();
      this.syncLabelViewport();
      this.renderViewport();
      this.renderMiniMap();
      this.renderDirtyState();
    }

    syncTimegrainButtons() {
      const grains = ['Hour', 'Day', 'Week', 'Month', 'Year'];
      const labels = {
        Hour: 'Hourly',
        Day: 'Day',
        Week: 'Week',
        Month: 'Month',
        Year: 'Year'
      };
      this.ui.timegrainGroup.innerHTML = '';
      const fragment = document.createDocumentFragment();
      grains.forEach((grain) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `lve-btn${grain === this.timeGrain ? ' lve-btn-primary' : ''}`;
        button.textContent = labels[grain] || grain;
        button.setAttribute('data-grain', grain);
        fragment.appendChild(button);
      });
      this.ui.timegrainGroup.appendChild(fragment);
    }

    syncViewButtons() {
      const views = this.payload?.views || [];
      const activeViewCode = this.payload?.activeView?.viewCode || '';
      const allowSwitching = (this.payload?.setup || {}).enableViewSwitching !== false;
      this.ui.viewGroup.hidden = !allowSwitching || views.length <= 1;
      this.ui.viewGroup.innerHTML = '';
      if (this.ui.viewGroup.hidden) return;

      const fragment = document.createDocumentFragment();
      views.forEach((view) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `lve-btn${view.viewCode === activeViewCode ? ' lve-btn-primary' : ''}`;
        button.textContent = view.name || view.viewCode || 'View';
        button.setAttribute('data-view-code', view.viewCode || '');
        fragment.appendChild(button);
      });
      this.ui.viewGroup.appendChild(fragment);
    }

    getSelectedContextKey() {
      const selectedBar = this.barById.get(this.selectedBarId);
      if (selectedBar?.contextKey) return selectedBar.contextKey;
      return (this.payload?.setup || {}).focusContextKey || '';
    }

    indexBars(bars) {
      this.barMapByRow.clear();
      this.barByDependencyKey.clear();
      this.barById.clear();

      bars.forEach((bar) => {
        if (!this.barMapByRow.has(bar.rowId)) this.barMapByRow.set(bar.rowId, []);
        this.barMapByRow.get(bar.rowId).push(bar);
        if (bar.barId) this.barById.set(bar.barId, bar);
        if (bar.dependencyKey) {
          this.barByDependencyKey.set(this.getDependencyLookupKey(bar.mappingLineNo, bar.dependencyKey), bar);
          if (!this.barByDependencyKey.has(bar.dependencyKey)) this.barByDependencyKey.set(bar.dependencyKey, bar);
        }
      });
    }

    getDependencyLookupKey(mappingLineNo, dependencyKey) {
      return `${mappingLineNo || 0}|${dependencyKey || ''}`;
    }

    computeVisibleRows(rows) {
      this.childRowsByParent.clear();
      const roots = [];

      rows.forEach((row) => {
        const parentId = row.parentRowId || '';
        if (!parentId) {
          roots.push(row);
          return;
        }
        if (!this.childRowsByParent.has(parentId)) this.childRowsByParent.set(parentId, []);
        this.childRowsByParent.get(parentId).push(row);
      });

      this.visibleRows = [];
      this.visibleRenderRows = [];
      const walk = (row) => {
        this.visibleRows.push(row);

        const children = this.childRowsByParent.get(row.rowId) || [];
        if (!children.length || !row.hasChildren || !this.expandedRows.has(row.rowId)) return;
        children.forEach(walk);
      };

      roots.forEach(walk);

      let previousStatusKey = '';
      this.visibleRows.forEach((row) => {
        const statusKey = this.getNormalizedStatusValue(row);
        if (statusKey !== previousStatusKey) {
          this.visibleRenderRows.push({ kind: 'status-header', rowId: `status:${statusKey || 'unspecified'}`, statusKey, sourceRow: row });
          previousStatusKey = statusKey;
        }

        if (!statusKey || this.expandedStatusGroups.has(statusKey)) {
          this.visibleRenderRows.push({ kind: 'data', rowId: row.rowId, statusKey, sourceRow: row });
        }
      });
    }

    buildDerivedCaches() {
      this.rowIndexById.clear();
      this.mappingLineMetaByNo.clear();
      this.conflictingBarIds.clear();
      this.rowsWithConflict.clear();

      this.visibleRows.forEach((row) => {
        const renderIndex = this.visibleRenderRows.findIndex((entry) => entry.kind === 'data' && entry.rowId === row.rowId);
        this.rowIndexById.set(row.rowId, renderIndex);
      });

      const payloadMappings = this.payload?.mappingLines || [];
      payloadMappings.forEach((line) => {
        this.mappingLineMetaByNo.set(line.lineNo, line);
      });

      this.precomputeConflicts();
    }

    precomputeConflicts() {
      if ((this.payload?.setup || {}).enableConflictDetection === false) return;
      const groups = new Map();

      this.visibleRows.forEach((row) => {
        const bars = this.barMapByRow.get(row.rowId) || [];
        bars.forEach((bar) => {
          const key = bar.conflictGroupKey || row.conflictGroupKey || row.rowId;
          if (!groups.has(key)) groups.set(key, []);
          groups.get(key).push({ rowId: row.rowId, bar });
        });
      });

      groups.forEach((items) => {
        items.sort((a, b) => {
          const aStart = toDate(a.bar.start)?.getTime() || 0;
          const bStart = toDate(b.bar.start)?.getTime() || 0;
          return aStart - bStart;
        });

        for (let i = 1; i < items.length; i += 1) {
          const previous = items[i - 1];
          const current = items[i];
          const previousEnd = toDate(previous.bar.end)?.getTime() || 0;
          const currentStart = toDate(current.bar.start)?.getTime() || 0;
          if (currentStart < previousEnd) {
            this.conflictingBarIds.add(previous.bar.barId);
            this.conflictingBarIds.add(current.bar.barId);
            this.rowsWithConflict.add(previous.rowId);
            this.rowsWithConflict.add(current.rowId);
          }
        }
      });
    }

    computeTimeline() {
      const bars = this.payload?.bars || [];
      let rangeStart = toDate(this.payload?.rangeStart);
      let rangeEnd = toDate(this.payload?.rangeEnd);

      if (!rangeStart || !rangeEnd) {
        bars.forEach((bar) => {
          const start = toDate(bar.start);
          const end = toDate(bar.end);
          if (!start || !end) return;
          if (!rangeStart || start < rangeStart) rangeStart = start;
          if (!rangeEnd || end > rangeEnd) rangeEnd = end;
        });
      }

      if (!rangeStart || !rangeEnd) {
        const today = startOfDay(new Date());
        rangeStart = addDays(today, -7);
        rangeEnd = addDays(today, 30);
      }

      this.effectiveTimeGrain = this.resolveEffectiveTimeGrain(bars);
      const renderGrain = this.getTimelineRenderGrain();
      const alignedStart = this.alignDateToGrain(rangeStart, renderGrain);
      let cursor = new Date(alignedStart.getTime());
      const alignedEnd = this.advanceDateByGrain(rangeEnd, renderGrain, 1);
      const columns = [];
      let totalWidth = 0;

      while (cursor < alignedEnd) {
        const next = this.advanceDateByGrain(cursor, renderGrain, 1);
        const width = this.getColumnWidth(renderGrain);
        columns.push({ start: new Date(cursor.getTime()), end: new Date(next.getTime()), width, x: totalWidth });
        totalWidth += width;
        cursor = next;
      }

      const visibleWidth = Math.max(320, this.ui.scrollBody?.clientWidth || 0);
      this.totalTimelineWidth = Math.max(totalWidth, visibleWidth);
      const scale = totalWidth > 0 ? this.totalTimelineWidth / totalWidth : 1;
      let offset = 0;
      this.timelineCols = columns.map((col) => {
        const scaledCol = {
          start: col.start,
          end: col.end,
          width: col.width * scale,
          x: offset
        };
        offset += scaledCol.width;
        return scaledCol;
      });
      this.timelineStart = alignedStart;
      this.timelineEnd = alignedEnd;
    }

    getTimelineRenderGrain() {
      return this.effectiveTimeGrain === 'Hour' ? 'Day' : this.effectiveTimeGrain;
    }

    resolveEffectiveTimeGrain(bars) {
      const requested = this.normalizeTimeGrain(this.timeGrain);
      if (requested === 'Day' && this.zoom >= 220 && this.hasSubDayPrecision(bars)) {
        return 'Hour';
      }
      return requested;
    }

    hasSubDayPrecision(bars) {
      return (bars || []).some((bar) => {
        const start = toDate(bar.start);
        const end = toDate(bar.end);
        return [start, end].some((date) => date && (date.getHours() !== 0 || date.getMinutes() !== 0 || date.getSeconds() !== 0));
      });
    }

    getColumnWidth(grain) {
      const zoomFactor = this.zoom / 100;
      const dayWidth = 32 * zoomFactor;
      switch (grain) {
        case 'Hour':
          return dayWidth * 3;
        case 'Day':
          return this.effectiveTimeGrain === 'Hour' ? dayWidth * 3 : dayWidth;
        case 'Week':
          return 96 * zoomFactor;
        case 'Month':
          return 140 * zoomFactor;
        case 'Year':
          return 180 * zoomFactor;
        default:
          return dayWidth;
      }
    }

    alignDateToGrain(date, grain) {
      switch (grain) {
        case 'Hour': {
          const alignedHour = date.getHours() < 12 ? 0 : 12;
          return new Date(date.getFullYear(), date.getMonth(), date.getDate(), alignedHour, 0, 0, 0);
        }
        case 'Week':
          return startOfWeek(date);
        case 'Month':
          return startOfMonth(date);
        case 'Year':
          return startOfYear(date);
        case 'Day':
        default:
          return startOfDay(date);
      }
    }

    advanceDateByGrain(date, grain, amount) {
      switch (grain) {
        case 'Hour':
          return new Date(this.alignDateToGrain(date, 'Hour').getTime() + amount * 12 * 3600 * 1000);
        case 'Week':
          return addDays(startOfWeek(date), amount * 7);
        case 'Month':
          return addMonths(startOfMonth(date), amount);
        case 'Year':
          return addYears(startOfYear(date), amount);
        case 'Day':
        default:
          return addDays(startOfDay(date), amount);
      }
    }

    getTopBandMeta(col) {
      const date = col.start;
      switch (this.effectiveTimeGrain) {
        case 'Hour':
        case 'Day':
        case 'Week':
          return {
            key: `${date.getFullYear()}-${date.getMonth()}`,
            label: date.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })
          };
        case 'Month':
          return {
            key: `${date.getFullYear()}`,
            label: String(date.getFullYear())
          };
        case 'Year':
        default:
          return {
            key: `${Math.floor(date.getFullYear() / 10) * 10}`,
            label: `${Math.floor(date.getFullYear() / 10) * 10}s`
          };
      }
    }

    getHourlyDayLabel(date) {
      return date.toLocaleDateString(undefined, { weekday: 'short', day: 'numeric' });
    }

    getBottomBandLabel(col) {
      const date = col.start;
      switch (this.effectiveTimeGrain) {
        case 'Hour':
          return this.getHourlyDayLabel(date);
        case 'Week':
          return `W${getIsoWeek(date)}`;
        case 'Month':
          return date.toLocaleDateString(undefined, { month: 'short' });
        case 'Year':
          return String(date.getFullYear());
        case 'Day':
        default:
          return date.toLocaleDateString(undefined, { day: 'numeric' });
      }
    }

    isWeekendColumn(col) {
      if (!['Day', 'Hour'].includes(this.effectiveTimeGrain)) return false;
      const day = col.start.getDay();
      return day === 0 || day === 6;
    }

    isPrimaryBoundary(col) {
      const date = col.start;
      switch (this.effectiveTimeGrain) {
        case 'Hour':
        case 'Day':
        case 'Week':
          return date.getDate() === 1;
        case 'Month':
          return date.getMonth() === 0;
        case 'Year':
        default:
          return date.getFullYear() % 10 === 0;
      }
    }

    renderHourlyDayCell(col) {
      const cell = document.createElement('div');
      cell.className = `day-cell hourly-day-cell${this.isWeekendColumn(col) ? ' weekend' : ''}`;
      cell.style.position = 'absolute';
      cell.style.left = `${col.x}px`;
      cell.style.width = `${col.width}px`;
      cell.style.minWidth = `${col.width}px`;
      cell.style.maxWidth = `${col.width}px`;
      cell.style.height = '34px';
      cell.style.display = 'flex';
      cell.style.flexDirection = 'column';
      cell.style.justifyContent = 'space-between';
      cell.style.paddingTop = '2px';
      cell.style.lineHeight = 'normal';
      cell.title = `${col.start.toLocaleString()} – ${col.end.toLocaleString()}`;

      const dayLabel = document.createElement('div');
      dayLabel.textContent = this.getHourlyDayLabel(col.start);
      dayLabel.style.fontSize = '11px';
      dayLabel.style.fontWeight = '600';
      dayLabel.style.lineHeight = '14px';
      dayLabel.style.padding = '0 4px';
      dayLabel.style.whiteSpace = 'nowrap';
      dayLabel.style.overflow = 'hidden';
      dayLabel.style.textOverflow = 'ellipsis';
      cell.appendChild(dayLabel);

      const halves = document.createElement('div');
      halves.style.display = 'grid';
      halves.style.gridTemplateColumns = '1fr 1fr';
      halves.style.alignItems = 'stretch';
      halves.style.height = '18px';
      halves.style.marginTop = 'auto';
      halves.style.borderTop = '1px solid var(--gantt-border)';
      halves.style.fontSize = '10px';
      halves.style.color = 'var(--gantt-subtext)';

      ['12 AM', '12 PM'].forEach((labelText, index) => {
        const half = document.createElement('div');
        half.textContent = labelText;
        half.style.display = 'flex';
        half.style.alignItems = 'center';
        half.style.justifyContent = 'center';
        half.style.whiteSpace = 'nowrap';
        half.style.overflow = 'hidden';
        half.style.textOverflow = 'ellipsis';
        if (index === 0) half.style.borderRight = '1px solid var(--gantt-border)';
        halves.appendChild(half);
      });

      cell.appendChild(halves);
      return cell;
    }

    renderTimelineHeader() {
      const isHourlyOverlay = this.effectiveTimeGrain === 'Hour';
      const bottomBandHeight = isHourlyOverlay ? 34 : 26;
      const track = document.createElement('div');
      track.className = 'lve-timeline-track';
      track.style.width = `${this.totalTimelineWidth}px`;
      track.style.height = `${26 + bottomBandHeight}px`;
      track.style.position = 'relative';

      const topBand = document.createElement('div');
      topBand.className = 'lve-timeline-months';
      topBand.style.position = 'relative';
      topBand.style.width = `${this.totalTimelineWidth}px`;
      topBand.style.height = '26px';

      const bottomBand = document.createElement('div');
      bottomBand.className = 'lve-timeline-days';
      bottomBand.setAttribute('data-grain', this.effectiveTimeGrain.toLowerCase());
      bottomBand.style.position = 'relative';
      bottomBand.style.width = `${this.totalTimelineWidth}px`;
      bottomBand.style.height = `${bottomBandHeight}px`;

      let currentGroupKey = '';
      let topCell = null;
      let topCellLeft = 0;
      this.timelineCols.forEach((col) => {
        const topMeta = this.getTopBandMeta(col);
        if (topMeta.key !== currentGroupKey) {
          currentGroupKey = topMeta.key;
          topCell = document.createElement('div');
          topCell.className = 'month-cell';
          topCell.textContent = topMeta.label;
          topCell.style.position = 'absolute';
          topCell.style.left = `${col.x}px`;
          topCell.style.width = '0px';
          topCellLeft = col.x;
          topBand.appendChild(topCell);
        }
        if (topCell) topCell.style.width = `${col.x + col.width - topCellLeft}px`;

        if (isHourlyOverlay) {
          bottomBand.appendChild(this.renderHourlyDayCell(col));
          return;
        }

        const cell = document.createElement('div');
        cell.className = `day-cell${this.isWeekendColumn(col) ? ' weekend' : ''}`;
        cell.style.position = 'absolute';
        cell.style.left = `${col.x}px`;
        cell.style.width = `${col.width}px`;
        cell.style.minWidth = `${col.width}px`;
        cell.style.maxWidth = `${col.width}px`;
        cell.textContent = this.getBottomBandLabel(col);
        cell.title = `${col.start.toLocaleString()} – ${col.end.toLocaleString()}`;
        bottomBand.appendChild(cell);
      });

      track.appendChild(topBand);
      track.appendChild(bottomBand);
      this.ui.timelineHead.style.width = '100%';
      this.ui.timelineHead.innerHTML = '';
      this.ui.timelineHead.appendChild(track);
      this.ui.timelineTrack = track;
      this.syncTimelineHeaderPosition();
    }

    renderRowsAndGrid() {
      this.viewportWidth = this.totalTimelineWidth;
      this.totalContentHeight = this.visibleRenderRows.length * this.rowHeight;
      const headHeight = this.ui.timelineHead.offsetHeight || 52;

      this.ui.labelPane.innerHTML = '';
      this.ui.labelPane.style.display = 'flex';
      this.ui.labelPane.style.flexDirection = 'column';
      this.ui.labelPane.style.minHeight = '0';

      const labelHead = document.createElement('div');
      labelHead.style.flex = '0 0 auto';
      labelHead.style.height = `${headHeight}px`;
      labelHead.style.borderBottom = '1px solid var(--gantt-border)';
      labelHead.style.background = '#fff';

      const labelViewport = document.createElement('div');
      labelViewport.style.position = 'relative';
      labelViewport.style.overflow = 'hidden';
      labelViewport.style.flex = '1 1 auto';
      labelViewport.style.minHeight = '0';

      const labelSurface = document.createElement('div');
      labelSurface.style.position = 'relative';
      labelSurface.style.height = `${this.totalContentHeight}px`;
      labelSurface.style.minHeight = `${this.totalContentHeight}px`;
      labelViewport.appendChild(labelSurface);

      this.ui.labelPane.appendChild(labelHead);
      this.ui.labelPane.appendChild(labelViewport);
      this.ui.labelHead = labelHead;
      this.ui.labelViewport = labelViewport;
      this.ui.labelSurface = labelSurface;

      this.ui.gridCanvas.innerHTML = '';
      this.ui.gridCanvas.style.width = `${this.totalTimelineWidth}px`;
      this.ui.gridCanvas.style.height = `${this.totalContentHeight}px`;
      this.ui.gridCanvas.style.minHeight = `${this.totalContentHeight}px`;

      const bg = document.createElement('div');
      bg.className = 'lve-grid-bg';
      bg.style.width = `${this.totalTimelineWidth}px`;
      bg.style.height = `${this.totalContentHeight}px`;

      const rowLayer = document.createElement('div');
      rowLayer.style.position = 'absolute';
      rowLayer.style.left = '0';
      rowLayer.style.top = '0';
      rowLayer.style.width = `${this.totalTimelineWidth}px`;
      rowLayer.style.height = `${this.totalContentHeight}px`;

      const barLayer = document.createElement('div');
      barLayer.style.position = 'absolute';
      barLayer.style.left = '0';
      barLayer.style.top = '0';
      barLayer.style.width = `${this.totalTimelineWidth}px`;
      barLayer.style.height = `${this.totalContentHeight}px`;

      const dependencyLayer = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      dependencyLayer.setAttribute('class', 'lve-dependency-layer');
      dependencyLayer.setAttribute('width', String(this.totalTimelineWidth));
      dependencyLayer.setAttribute('height', String(this.totalContentHeight));
      dependencyLayer.style.left = '0';
      dependencyLayer.style.top = '0';
      dependencyLayer.style.width = `${this.totalTimelineWidth}px`;
      dependencyLayer.style.height = `${this.totalContentHeight}px`;

      this.ui.gridCanvas.appendChild(bg);
      this.ui.gridCanvas.appendChild(rowLayer);
      this.ui.gridCanvas.appendChild(barLayer);
      this.ui.gridCanvas.appendChild(dependencyLayer);

      this.ui.gridBackground = bg;
      this.ui.gridRowLayer = rowLayer;
      this.ui.gridBarLayer = barLayer;
      this.ui.dependencyLayer = dependencyLayer;

      const today = new Date();
      const todayX = this.dateToX(today);
      const todayStart = startOfDay(today);

      this.timelineCols.forEach((col) => {
        const x = col.x;
        const line = document.createElement('div');
        line.className = 'vline';
        if (this.isPrimaryBoundary(col)) line.classList.add('month-boundary');
        line.style.left = `${x}px`;
        bg.appendChild(line);

        if (this.isWeekendColumn(col)) {
          const weekend = document.createElement('div');
          weekend.className = 'weekend-bg';
          weekend.style.left = `${x}px`;
          weekend.style.width = `${col.width}px`;
          bg.appendChild(weekend);
        }

        if (col.end <= todayStart) {
          const past = document.createElement('div');
          past.className = 'past-bg';
          past.style.left = `${x}px`;
          past.style.width = `${col.width}px`;
          bg.appendChild(past);
        }
      });

      if (this.effectiveTimeGrain === 'Hour' && this.timelineCols.length) {
        const halfDayOverlay = document.createElement('div');
        halfDayOverlay.style.position = 'absolute';
        halfDayOverlay.style.left = '0';
        halfDayOverlay.style.top = '0';
        halfDayOverlay.style.width = `${this.totalTimelineWidth}px`;
        halfDayOverlay.style.height = `${this.totalContentHeight}px`;
        halfDayOverlay.style.pointerEvents = 'none';
        halfDayOverlay.style.backgroundImage = 'linear-gradient(to right, transparent calc(50% - 0.5px), rgba(207, 216, 228, 0.95) calc(50% - 0.5px), rgba(207, 216, 228, 0.95) calc(50% + 0.5px), transparent calc(50% + 0.5px))';
        halfDayOverlay.style.backgroundSize = `${this.timelineCols[0].width}px 100%`;
        halfDayOverlay.style.backgroundRepeat = 'repeat';
        bg.appendChild(halfDayOverlay);
      }

      const todayLine = document.createElement('div');
      todayLine.className = 'today-line';
      todayLine.style.left = `${todayX}px`;
      bg.appendChild(todayLine);
    }

    syncLabelViewport() {
      if (!this.ui.labelSurface || !this.ui.scrollBody) return;
      this.ui.labelSurface.style.transform = `translateY(${-this.ui.scrollBody.scrollTop}px)`;
    }

    getViewportRowRange() {
      const scrollTop = this.ui.scrollBody?.scrollTop || 0;
      const viewportHeight = this.ui.scrollBody?.clientHeight || 0;
      const start = Math.max(0, Math.floor(scrollTop / this.rowHeight) - this.rowOverscan);
      const end = Math.min(
        this.visibleRenderRows.length,
        Math.ceil((scrollTop + viewportHeight) / this.rowHeight) + this.rowOverscan
      );
      return { start, end };
    }

    renderViewport() {
      if (!this.ui.labelSurface || !this.ui.gridRowLayer || !this.ui.gridBarLayer || !this.ui.dependencyLayer) return;

      const range = this.getViewportRowRange();
      this.ui.labelSurface.innerHTML = '';
      this.ui.gridRowLayer.innerHTML = '';
      this.ui.gridBarLayer.innerHTML = '';
      this.ui.dependencyLayer.innerHTML = '';

      this.renderVisibleRows(range.start, range.end);
      this.renderBars(range.start, range.end);
      this.renderConflicts();
      this.syncLabelViewport();
      this.scheduleDependencyRender(range.start, range.end);
    }

    scheduleDependencyRender(startIndex, endIndex) {
      if (this.dependencyRenderFrame) {
        window.cancelAnimationFrame(this.dependencyRenderFrame);
      }

      this.dependencyRenderFrame = window.requestAnimationFrame(() => {
        this.dependencyRenderFrame = 0;
        this.renderDependencies(startIndex, endIndex);
      });
    }

    getStatusDisplayValue(row) {
      return String(row?.statusLabel || row?.statusValue || '').trim();
    }

    getNormalizedStatusValue(row) {
      return this.getStatusDisplayValue(row).toLowerCase();
    }

    isStatusGroupStart(index) {
      const entry = this.visibleRenderRows[index];
      if (!entry || entry.kind !== 'status-header') return false;
      return true;
    }

    getRenderRowTop(index) {
      return index * this.rowHeight;
    }

    getStatusPaletteColor(normalized) {
      const palette = ['#4f7dbf', '#f3a64a', '#6e8f66', '#b85c7b', '#7f6bb3', '#3e9a95', '#9a7a3e', '#5f8ea8'];
      let hash = 0;
      const source = String(normalized || 'unspecified');
      for (let index = 0; index < source.length; index += 1) {
        hash = ((hash << 5) - hash + source.charCodeAt(index)) >>> 0;
      }
      return palette[hash % palette.length];
    }

    getStatusMeta(row) {
      const displayLabel = this.getStatusDisplayValue(row) || 'Unspecified';
      const normalized = displayLabel.toLowerCase();
      const overrideColor = /^#([0-9a-f]{6})$/i.test(String(row?.colorValue || '').trim())
        ? String(row.colorValue).trim()
        : '';
      const predefined = {
        planned: { label: 'Planned', color: '#4f7dbf' },
        'firm planned': { label: 'Firm Planned', color: '#6f8aa8' },
        released: { label: 'Released', color: '#f3a64a' },
        finished: { label: 'Finished', color: '#6e8f66' }
      };
      const base = predefined[normalized] || {
        label: displayLabel,
        color: overrideColor || this.getStatusPaletteColor(normalized)
      };

      return {
        label: base.label,
        color: base.color,
        railColor: this.tintColor(base.color, 0.18),
        normalized
      };
    }

    renderVisibleRows(startIndex, endIndex) {
      const labelFragment = document.createDocumentFragment();
      const rowLineFragment = document.createDocumentFragment();

      for (let index = startIndex; index < endIndex; index += 1) {
        const entry = this.visibleRenderRows[index];
        if (!entry) continue;

        const row = entry.sourceRow;
        const rowTop = this.getRenderRowTop(index);
        const statusMeta = this.getStatusMeta(row);

        const labelRow = document.createElement('div');
        labelRow.className = 'lve-label-row';
        labelRow.style.position = 'absolute';
        labelRow.style.left = '0';
        labelRow.style.right = '0';
        labelRow.style.top = `${rowTop}px`;
        labelRow.style.height = `${this.rowHeight}px`;
        labelRow.style.paddingRight = '0';
        labelRow.style.background = '#ffffff';
        labelRow.dataset.rowId = entry.rowId;
        labelRow.dataset.rowKind = entry.kind;

        if (entry.kind === 'status-header') {
          labelRow.style.display = 'flex';
          labelRow.style.alignItems = 'stretch';
          labelRow.style.background = statusMeta.color;

          const statusHeader = document.createElement('button');
          statusHeader.type = 'button';
          statusHeader.style.display = 'flex';
          statusHeader.style.alignItems = 'center';
          statusHeader.style.gap = '8px';
          statusHeader.style.width = '100%';
          statusHeader.style.padding = '0 10px';
          statusHeader.style.border = '0';
          statusHeader.style.background = statusMeta.color;
          statusHeader.style.color = '#ffffff';
          statusHeader.style.cursor = 'pointer';
          statusHeader.style.fontSize = '11px';
          statusHeader.style.fontWeight = '700';
          statusHeader.style.textAlign = 'left';

          const expander = document.createElement('span');
          expander.textContent = this.expandedStatusGroups.has(entry.statusKey) ? '▾' : '▸';
          expander.style.flex = '0 0 auto';

          const text = document.createElement('span');
          text.textContent = statusMeta.label;
          text.style.minWidth = '0';
          text.style.overflow = 'hidden';
          text.style.whiteSpace = 'nowrap';
          text.style.textOverflow = 'ellipsis';

          statusHeader.appendChild(expander);
          statusHeader.appendChild(text);
          statusHeader.addEventListener('click', () => {
            if (this.expandedStatusGroups.has(entry.statusKey)) this.expandedStatusGroups.delete(entry.statusKey);
            else this.expandedStatusGroups.add(entry.statusKey);
            this.log('Interaction', 'info', 'Status group toggle', { status: statusMeta.label, expanded: this.expandedStatusGroups.has(entry.statusKey) });
            this.render();
          });
          labelRow.appendChild(statusHeader);

          const blankGridRow = document.createElement('div');
          blankGridRow.style.position = 'absolute';
          blankGridRow.style.left = '0';
          blankGridRow.style.top = `${rowTop}px`;
          blankGridRow.style.width = `${this.totalTimelineWidth}px`;
          blankGridRow.style.height = `${this.rowHeight}px`;
          blankGridRow.style.background = '#ffffff';
          rowLineFragment.appendChild(blankGridRow);
        } else {
          labelRow.style.display = 'grid';
          labelRow.style.gridTemplateColumns = `${this.statusRailWidth}px minmax(0, 1fr)`;

          const rail = document.createElement('div');
          rail.style.display = 'flex';
          rail.style.justifyContent = 'center';
          rail.style.background = '#ffffff';

          const railLine = document.createElement('div');
          railLine.style.width = '18px';
          railLine.style.height = '100%';
          railLine.style.background = statusMeta.railColor;
          rail.appendChild(railLine);

          labelRow.appendChild(rail);
          labelRow.appendChild(this.createRowContentWrap(row, this.rowHeight));

          const hLine = document.createElement('div');
          hLine.className = 'hline';
          hLine.style.top = `${rowTop + this.rowHeight - 1}px`;
          rowLineFragment.appendChild(hLine);
        }

        this.addTooltipHandlers(labelRow, row.tooltipTitle, row.tooltipFields);
        labelFragment.appendChild(labelRow);
      }

      this.ui.labelSurface.appendChild(labelFragment);
      this.ui.gridRowLayer.appendChild(rowLineFragment);
    }

    renderBars(startIndex, endIndex) {
      const fragment = document.createDocumentFragment();

      for (let renderIndex = startIndex; renderIndex < endIndex; renderIndex += 1) {
        const entry = this.visibleRenderRows[renderIndex];
        if (!entry || entry.kind !== 'data') continue;

        const row = entry.sourceRow;
        const rowBars = this.barMapByRow.get(row.rowId) || [];
        rowBars.forEach((bar) => {
          const start = toDate(bar.start);
          const end = toDate(bar.end);
          if (!start || !end) return;

          const xStart = this.dateToX(start);
          const xEnd = this.dateToX(end);
          const width = Math.max(6, xEnd - xStart);
          const metrics = this.getBarVerticalMetrics(bar, renderIndex);
          const isChild = metrics.isChild;
          const top = metrics.top;
          const height = metrics.height;

          const barEl = document.createElement('div');
          barEl.className = 'lve-bar';
          if (this.selectedBarId === bar.barId) barEl.classList.add('selected');
          if (this.hasConflict(bar)) barEl.classList.add('conflict');
          if (this.isBarDirty(bar)) barEl.classList.add('dirty');

          barEl.style.left = `${xStart}px`;
          barEl.style.top = `${top}px`;
          barEl.style.width = `${width}px`;
          barEl.style.height = `${height}px`;
          barEl.style.background = isChild ? this.tintColor(bar.color || '#3AAB5C', 0.16) : (bar.color || '#3AAB5C');

          const progress = document.createElement('div');
          progress.className = 'lve-bar-progress';
          progress.style.width = `${clamp(bar.progressPercent || 0, 0, 100)}%`;
          progress.style.background = bar.trackColor || 'rgba(255,255,255,0.45)';
          barEl.appendChild(progress);

          const label = document.createElement('span');
          label.className = 'lve-bar-label';
          label.style.lineHeight = `${height}px`;
          label.textContent = width > (isChild ? 46 : 66) ? (bar.label || '') : '';
          barEl.appendChild(label);

          const due = toDate(bar.due);
          if (due) {
            const dueMarker = document.createElement('div');
            dueMarker.className = 'lve-due-marker';
            dueMarker.style.left = `${this.dateToX(due) - xStart - 5}px`;
            barEl.appendChild(dueMarker);
          }

          barEl.addEventListener('mousedown', (event) => this.beginDrag(event, bar, row, xStart, xEnd));
          barEl.addEventListener('click', () => {
            this.selectedBarId = bar.barId;
            this.renderViewport();
            invoke('BarClicked', [bar.sourceTableId || 0, bar.sourceRecordId || '', bar.barId || '', bar.pageId || 0]);
          });
          this.addTooltipHandlers(barEl, bar.tooltipTitle || bar.label, row.tooltipFields || []);
          fragment.appendChild(barEl);
        });
      }

      this.ui.gridBarLayer.appendChild(fragment);
    }

    tintColor(color, amount) {
      const hex = String(color || '').trim();
      if (!/^#([0-9a-f]{6})$/i.test(hex)) return color;
      const normalize = (value) => clamp(Math.round(value + (255 - value) * amount), 0, 255);
      const r = normalize(parseInt(hex.slice(1, 3), 16));
      const g = normalize(parseInt(hex.slice(3, 5), 16));
      const b = normalize(parseInt(hex.slice(5, 7), 16));
      return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
    }

    getBarVerticalMetrics(bar, renderIndex) {
      const entry = this.visibleRenderRows[renderIndex] || {};
      const row = entry.sourceRow || {};
      const isChild = (bar?.depth || 0) > 0 || ((row.level || 0) > 0);
      const top = this.getRenderRowTop(renderIndex) + (isChild ? 10 : 8);
      const height = isChild ? 16 : 20;

      return {
        isChild,
        top,
        height,
        bottom: top + height,
        centerY: top + height / 2
      };
    }

    getBarLayout(bar, rowIndex) {
      const start = toDate(bar?.start);
      const end = toDate(bar?.end);
      if (!start || !end || rowIndex === undefined) return null;

      const left = this.dateToX(start);
      const right = Math.max(left + 6, this.dateToX(end));
      const metrics = this.getBarVerticalMetrics(bar, rowIndex);

      return {
        left,
        right,
        width: right - left,
        top: metrics.top,
        bottom: metrics.bottom,
        centerY: metrics.centerY
      };
    }

    buildDependencyRoute(sourceLayout, targetLayout) {
      if (!sourceLayout || !targetLayout) return null;

      const directGap = targetLayout.left - sourceLayout.right;
      if (directGap >= 12) {
        const laneX = Math.min(
          this.totalTimelineWidth - 8,
          Math.max(sourceLayout.right + 12, sourceLayout.right + directGap / 2)
        );
        return {
          direction: 'right',
          path: `M ${sourceLayout.right} ${sourceLayout.centerY} L ${laneX} ${sourceLayout.centerY} L ${laneX} ${targetLayout.centerY} L ${targetLayout.left} ${targetLayout.centerY}`
        };
      }

      const laneX = Math.max(8, Math.min(sourceLayout.left, targetLayout.left) - 18);
      return {
        direction: 'left',
        path: `M ${sourceLayout.left} ${sourceLayout.centerY} L ${laneX} ${sourceLayout.centerY} L ${laneX} ${targetLayout.centerY} L ${targetLayout.left} ${targetLayout.centerY}`
      };
    }

    renderDependencies(startIndex, endIndex) {
      if (!this.ui.dependencyLayer) return;
      if ((this.payload?.setup || {}).enableDependencies === false) return;
      if ((this.payload?.activeView || {}).dependencyEnabled === false) return;

      const deps = this.payload.dependencies || [];
      const svg = this.ui.dependencyLayer;
      const rowsById = new Map((this.payload?.rows || []).map((row) => [row.rowId, row]));
      svg.innerHTML = '';
      svg.setAttribute('width', String(this.totalTimelineWidth));
      svg.setAttribute('height', String(this.totalContentHeight));

      const visibleRowIds = new Set();
      for (let index = startIndex; index < endIndex; index += 1) {
        const entry = this.visibleRenderRows[index];
        if (entry && entry.kind === 'data') visibleRowIds.add(entry.rowId);
      }

      const marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker');
      marker.setAttribute('id', 'dgog-arrow');
      marker.setAttribute('markerWidth', '8');
      marker.setAttribute('markerHeight', '8');
      marker.setAttribute('refX', '6');
      marker.setAttribute('refY', '3');
      marker.setAttribute('orient', 'auto');
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', 'M0,0 L0,6 L6,3 z');
      path.setAttribute('fill', '#60728a');
      marker.appendChild(path);
      const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
      defs.appendChild(marker);
      svg.appendChild(defs);

      const resolvedDependencies = [];
      deps.forEach((dep) => {
        const sourceBar = this.barByDependencyKey.get(this.getDependencyLookupKey(dep.mappingLineNo, dep.sourceKey))
          || this.barByDependencyKey.get(dep.sourceKey);
        const targetBar = this.barByDependencyKey.get(this.getDependencyLookupKey(dep.mappingLineNo, dep.targetKey))
          || this.barByDependencyKey.get(dep.targetKey);
        if (!sourceBar || !targetBar) return;

        const sourceRowIndex = this.rowIndexById.get(sourceBar.rowId);
        const targetRowIndex = this.rowIndexById.get(targetBar.rowId);
        const sourceLayout = this.getBarLayout(sourceBar, sourceRowIndex);
        const targetLayout = this.getBarLayout(targetBar, targetRowIndex);
        const route = this.buildDependencyRoute(sourceLayout, targetLayout);

        resolvedDependencies.push({
          dep,
          sourceBar,
          targetBar,
          sourceRow: rowsById.get(sourceBar.rowId) || {},
          targetRow: rowsById.get(targetBar.rowId) || {},
          sourceLayout,
          targetLayout,
          route,
          shouldRender: !!route && (visibleRowIds.has(sourceBar.rowId) || visibleRowIds.has(targetBar.rowId))
        });
      });

      this.logDependencyDebugGroups(resolvedDependencies);

      resolvedDependencies.forEach((item) => {
        if (!item.shouldRender || !item.route) return;

        const arrow = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        arrow.setAttribute('d', item.route.path);
        arrow.setAttribute('fill', 'none');
        arrow.setAttribute('stroke', '#60728a');
        arrow.setAttribute('stroke-width', '1.2');
        arrow.setAttribute('stroke-linejoin', 'round');
        arrow.setAttribute('stroke-linecap', 'round');
        arrow.setAttribute('marker-end', 'url(#dgog-arrow)');
        svg.appendChild(arrow);
      });
    }

    getRowDebugLabel(row) {
      const parts = [row?.keyText, row?.descriptionText].filter(Boolean);
      return parts.join(' — ') || row?.tooltipTitle || row?.rowId || '(row)';
    }

    getRowDebugInfo(row) {
      const tooltipFields = Array.isArray(row?.tooltipFields)
        ? row.tooltipFields.map((field) => ({
            caption: field?.caption || '',
            value: field?.value || ''
          }))
        : [];

      return {
        rowId: row?.rowId || '',
        parentRowId: row?.parentRowId || '',
        level: row?.level || 0,
        keyText: row?.keyText || '',
        descriptionText: row?.descriptionText || '',
        statusValue: row?.statusValue || '',
        colorValue: row?.colorValue || '',
        tooltipTitle: row?.tooltipTitle || '',
        yLabel: this.getRowDebugLabel(row),
        yLabelFields: tooltipFields
      };
    }

    getBarDebugInfo(bar, row, route, layout) {
      return {
        barId: bar?.barId || '',
        label: bar?.label || '',
        status: bar?.status || row?.statusValue || '',
        rowId: bar?.rowId || row?.rowId || '',
        dependencyKey: bar?.dependencyKey || '',
        mappingLineNo: bar?.mappingLineNo || 0,
        sourceTableId: bar?.sourceTableId || 0,
        sourceRecordId: bar?.sourceRecordId || '',
        start: bar?.start || '',
        end: bar?.end || '',
        due: bar?.due || '',
        layout: layout || null,
        routeDirection: route?.direction || '',
        yAxisContext: this.getRowDebugInfo(row)
      };
    }

    logDependencyDebugGroups(resolvedDependencies) {
      const signature = resolvedDependencies
        .map(({ dep, sourceBar, targetBar, route }) => `${dep.mappingLineNo || 0}:${sourceBar.barId || sourceBar.dependencyKey}->${targetBar.barId || targetBar.dependencyKey}:${route?.direction || 'none'}`)
        .join('|');
      if (signature === this.lastDependencyDebugSignature) return;
      this.lastDependencyDebugSignature = signature;

      const groups = new Map();

      resolvedDependencies.forEach((item) => {
        const { dep, sourceBar, targetBar, sourceRow, targetRow, route, sourceLayout, targetLayout } = item;
        const parentRowId = sourceRow.parentRowId || targetRow.parentRowId || sourceBar.rowId || targetBar.rowId || 'root';
        const parentRow = this.payload?.rows?.find((row) => row.rowId === parentRowId) || {};
        const groupKey = `${dep.mappingLineNo || 0}|${parentRowId}`;

        if (!groups.has(groupKey)) {
          groups.set(groupKey, {
            mappingLineNo: dep.mappingLineNo || 0,
            parent: this.getRowDebugInfo(parentRow),
            items: []
          });
        }

        groups.get(groupKey).items.push({
          relation: {
            mappingLineNo: dep.mappingLineNo || 0,
            sourceKey: dep.sourceKey || '',
            targetKey: dep.targetKey || '',
            routeDirection: route?.direction || 'unresolved',
            rendered: !!item.shouldRender
          },
          source: this.getBarDebugInfo(sourceBar, sourceRow, route, sourceLayout),
          target: this.getBarDebugInfo(targetBar, targetRow, route, targetLayout)
        });
      });

      console.groupCollapsed(`[GANTT][dependency-debug] ${resolvedDependencies.length} arrow candidate(s)`);
      groups.forEach((group) => {
        console.groupCollapsed(
          `[GANTT][dependency-parent] mappingLine=${group.mappingLineNo} parent=${group.parent.yLabel} (${group.items.length})`
        );
        console.log('parent', group.parent);
        group.items.forEach((item, index) => {
          console.groupCollapsed(
            `[GANTT][dependency-arrow ${index + 1}] ${item.source.yAxisContext.yLabel} -> ${item.target.yAxisContext.yLabel} [${item.relation.routeDirection}]`
          );
          console.log('relation', item.relation);
          console.log('source', item.source);
          console.log('target', item.target);
          console.groupEnd();
        });
        console.groupEnd();
      });
      console.groupEnd();
    }

    hasConflict(bar) {
      return this.conflictingBarIds.has(bar.barId);
    }

    renderConflicts() {
      this.ui.labelSurface.querySelectorAll('.lve-label-row').forEach((element) => {
        element.classList.toggle('has-conflict', this.rowsWithConflict.has(element.dataset.rowId));
      });
    }

    isBarDirty(bar) {
      const key = `${bar.barId}|${bar.sourceTableId}|${bar.sourceRecordId}`;
      return this.pendingByKey.has(key);
    }

    beginDrag(event, bar, row, xStart, xEnd) {
      if (!(bar.isEditable && (this.payload.setup || {}).allowEdit)) return;
      const rect = event.currentTarget.getBoundingClientRect();
      const localX = event.clientX - rect.left;
      const edgeThreshold = 8;
      let mode = 'move';
      if (localX < edgeThreshold) mode = 'resize-left';
      else if (localX > rect.width - edgeThreshold) mode = 'resize-right';

      event.currentTarget.classList.add('is-drag-source');
      this.dragState = {
        mode,
        bar,
        row,
        startClientX: event.clientX,
        originalStart: toDate(bar.start),
        originalEnd: toDate(bar.end),
        originalXStart: xStart,
        originalXEnd: xEnd,
        sourceElement: event.currentTarget,
        ghost: null
      };

      const renderIndex = this.rowIndexById.get(row.rowId) || 0;
      const metrics = this.getBarVerticalMetrics(bar, renderIndex);
      const ghost = document.createElement('div');
      ghost.className = 'lve-bar-ghost';
      ghost.style.left = `${xStart}px`;
      ghost.style.top = `${metrics.top}px`;
      ghost.style.width = `${Math.max(6, xEnd - xStart)}px`;
      ghost.style.height = `${metrics.height}px`;
      this.ui.gridBarLayer.appendChild(ghost);
      this.dragState.ghost = ghost;
      this.log('Interaction', 'info', 'Drag start', { barId: bar.barId, mode });
      event.preventDefault();
    }

    onPointerMove(event) {
      if (!this.dragState) return;
      const deltaPx = event.clientX - this.dragState.startClientX;
      const { mode, originalStart, originalEnd, ghost, originalXStart, originalXEnd } = this.dragState;
      const anchorDate = mode === 'resize-right' ? originalEnd : originalStart;
      const anchorX = mode === 'resize-right' ? originalXEnd : originalXStart;
      const shiftedDate = this.xToDate(anchorX + deltaPx) || anchorDate;
      const deltaMs = shiftedDate.getTime() - anchorDate.getTime();
      let newStart = new Date(originalStart.getTime());
      let newEnd = new Date(originalEnd.getTime());

      if (mode === 'move') {
        newStart = new Date(originalStart.getTime() + deltaMs);
        newEnd = new Date(originalEnd.getTime() + deltaMs);
      }
      if (mode === 'resize-left') {
        newStart = new Date(Math.min(originalEnd.getTime() - this.minimumBarMs(), originalStart.getTime() + deltaMs));
      }
      if (mode === 'resize-right') {
        newEnd = new Date(Math.max(originalStart.getTime() + this.minimumBarMs(), originalEnd.getTime() + deltaMs));
      }

      const ghostLeft = this.dateToX(newStart);
      const ghostWidth = Math.max(6, this.dateToX(newEnd) - ghostLeft);
      ghost.style.left = `${ghostLeft}px`;
      ghost.style.width = `${ghostWidth}px`;
      this.dragState.newStart = newStart;
      this.dragState.newEnd = newEnd;
    }

    finishDrag() {
      if (!this.dragState) return;
      const state = this.dragState;
      if (state.sourceElement) state.sourceElement.classList.remove('is-drag-source');
      if (state.ghost) state.ghost.remove();
      this.dragState = null;
      if (!state.newStart || !state.newEnd) return;

      const bar = state.bar;
      const oldStart = bar.start;
      const oldEnd = bar.end;
      bar.start = state.newStart.toISOString();
      bar.end = state.newEnd.toISOString();

      this.addPendingChange(bar, 'start', oldStart, bar.start);
      this.addPendingChange(bar, 'end', oldEnd, bar.end);
      this.renderViewport();
      this.renderMiniMap();
      this.log('Interaction', 'info', 'Drag end', { barId: bar.barId });
    }

    addPendingChange(bar, logicalField, oldValue, newValue) {
      if (String(oldValue) === String(newValue)) return;
      const fieldId = logicalField === 'start' ? this.resolveStartFieldId(bar.mappingLineNo) : this.resolveEndFieldId(bar.mappingLineNo);
      if (!fieldId) return;
      const key = `${bar.barId}|${bar.sourceTableId}|${bar.sourceRecordId}|${fieldId}`;
      const change = {
        sourceTableId: bar.sourceTableId,
        sourceRecordId: bar.sourceRecordId,
        fieldId,
        oldValue: oldValue || '',
        newValue: newValue || ''
      };

      this.pendingByKey.set(key, change);
      this.pendingChanges = Array.from(this.pendingByKey.values());
      this.dirty = this.pendingChanges.length > 0;
      this.renderDirtyState();
      this.log('Edit', 'info', 'Pending change added', { count: this.pendingChanges.length, fieldId });
    }

    resolveStartFieldId(mappingLineNo) {
      const line = this.mappingLineMetaByNo.get(mappingLineNo);
      return line ? line.startDateFieldId : 0;
    }

    resolveEndFieldId(mappingLineNo) {
      const line = this.mappingLineMetaByNo.get(mappingLineNo);
      return line ? line.endDateFieldId : 0;
    }

    renderDirtyState() {
      const allowSave = (this.payload?.setup || {}).allowSave !== false;
      this.ui.saveButton.disabled = !this.dirty || !allowSave;
      this.ui.dirtyIndicator.hidden = !this.dirty;
      if (this.dirty) {
        this.ui.dirtyIndicator.textContent = `${this.pendingChanges.length} unsaved change(s)`;
      }
    }

    renderMiniMap() {
      if (!this.miniMapEnabled || this.viewportWidth <= 0 || this.visibleRows.length > 500) {
        this.ui.minimapWrap.hidden = true;
        return;
      }
      this.ui.minimapWrap.hidden = false;
      const canvas = this.ui.minimap;
      const ctx = canvas.getContext('2d');
      const width = this.ui.minimapWrap.clientWidth || this.root.clientWidth || 900;
      canvas.width = width;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      ctx.fillStyle = '#eff3f8';
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      const scale = canvas.width / this.viewportWidth;
      this.visibleRows.forEach((row, index) => {
        const bars = this.barMapByRow.get(row.rowId) || [];
        bars.forEach((bar) => {
          const start = toDate(bar.start);
          const end = toDate(bar.end);
          if (!start || !end) return;
          const x = this.dateToX(start) * scale;
          const w = Math.max(1, (this.dateToX(end) - this.dateToX(start)) * scale);
          const y = (index % 20) * 2;
          ctx.fillStyle = bar.color || '#5a7fb0';
          ctx.fillRect(x, y, w, 1.5);
        });
      });
      this.syncMiniMapViewport();
    }

    syncMiniMapViewport() {
      if (this.ui.minimapWrap.hidden) return;
      const body = this.ui.scrollBody;
      const scale = this.ui.minimap.width / this.viewportWidth;
      const left = body.scrollLeft * scale;
      const width = Math.max(12, body.clientWidth * scale);
      this.ui.minimapViewport.style.left = `${left}px`;
      this.ui.minimapViewport.style.width = `${width}px`;
    }

    addTooltipHandlers(element, title, fields) {
      element.addEventListener('mouseenter', (event) => {
        const parts = [];
        if (title) parts.push(`<div class="title">${escapeHtml(title)}</div>`);
        (fields || []).forEach((field) => {
          parts.push(`<div class="line"><span>${escapeHtml(field.caption || '')}</span><strong>${escapeHtml(field.value || '')}</strong></div>`);
        });
        if (!parts.length) return;
        this.hoverTooltip.innerHTML = parts.join('');
        this.hoverTooltip.hidden = false;
        this.positionTooltip(event);
      });
      element.addEventListener('mousemove', (event) => this.positionTooltip(event));
      element.addEventListener('mouseleave', () => {
        this.hoverTooltip.hidden = true;
      });
    }

    positionTooltip(event) {
      const margin = 14;
      const rect = this.root.getBoundingClientRect();
      const tipRect = this.hoverTooltip.getBoundingClientRect();
      let left = event.clientX - rect.left + margin;
      let top = event.clientY - rect.top + margin;
      if (left + tipRect.width > rect.width - margin) left = rect.width - tipRect.width - margin;
      if (top + tipRect.height > rect.height - margin) top = rect.height - tipRect.height - margin;
      this.hoverTooltip.style.left = `${Math.max(margin, left)}px`;
      this.hoverTooltip.style.top = `${Math.max(margin, top)}px`;
    }

    dateToX(dateObj) {
      if (!dateObj || !this.timelineCols.length) return 0;
      const time = dateObj.getTime();
      if (time <= this.timelineCols[0].start.getTime()) return 0;
      const lastCol = this.timelineCols[this.timelineCols.length - 1];
      if (time >= lastCol.end.getTime()) return this.totalTimelineWidth;

      for (let index = 0; index < this.timelineCols.length; index += 1) {
        const col = this.timelineCols[index];
        const start = col.start.getTime();
        const end = col.end.getTime();
        if (time < end || index === this.timelineCols.length - 1) {
          const ratio = clamp((time - start) / Math.max(1, end - start), 0, 1);
          return col.x + ratio * col.width;
        }
      }

      return this.totalTimelineWidth;
    }

    xToDate(x) {
      if (!this.timelineCols.length) return null;
      const clampedX = clamp(x, 0, this.totalTimelineWidth);
      for (let index = 0; index < this.timelineCols.length; index += 1) {
        const col = this.timelineCols[index];
        if (clampedX <= col.x + col.width || index === this.timelineCols.length - 1) {
          const ratio = clamp((clampedX - col.x) / Math.max(col.width, 1), 0, 1);
          return new Date(col.start.getTime() + (col.end.getTime() - col.start.getTime()) * ratio);
        }
      }
      return new Date(this.timelineEnd.getTime());
    }

    millisecondsPerPixel() {
      const totalMs = this.timelineEnd.getTime() - this.timelineStart.getTime();
      return totalMs / Math.max(this.totalTimelineWidth, 1);
    }

    minimumBarMs() {
      return this.effectiveTimeGrain === 'Hour' ? 3600 * 1000 : 24 * 3600 * 1000;
    }
  }

  window.LVEGanttChart = LVEGanttChart;
})();