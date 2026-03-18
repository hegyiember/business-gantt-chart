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
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
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
      this.visibleRows = [];
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
      this.rowHeight = 36;
      this.rowOverscan = 12;
      this.renderFrame = 0;
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
              <button class="lve-btn" data-action="zoom-out" title="Zoom out">−</button>
              <span class="lve-zoom-label">100%</span>
              <button class="lve-btn" data-action="zoom-in" title="Zoom in">+</button>
              <select class="lve-timegrain-select" aria-label="Time grain">
                <option value="Day">Day</option>
                <option value="Week">Week</option>
                <option value="Month">Month</option>
                <option value="Year">Year</option>
              </select>
              <select class="lve-view-select" aria-label="View"></select>
            </div>
            <div class="lve-right-controls">
              <button class="lve-btn" data-action="reload">Reload</button>
              <button class="lve-btn lve-btn-primary" data-action="save" disabled>Save</button>
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
        viewSelect: shell.querySelector('.lve-view-select'),
        timegrainSelect: shell.querySelector('.lve-timegrain-select'),
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
        labelSurface: null,
        gridBackground: null,
        gridRowLayer: null,
        gridBarLayer: null
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

      this.ui.timegrainSelect.addEventListener('change', () => {
        this.timeGrain = this.normalizeTimeGrain(this.ui.timegrainSelect.value);
        this.render();
        this.log('View', 'info', 'Time grain changed', { timeGrain: this.timeGrain });
      });

      this.ui.viewSelect.addEventListener('change', () => {
        const contextKey = this.getSelectedContextKey();
        invoke('ViewChangeRequested', [this.ui.viewSelect.value, contextKey]);
      });

      this.ui.scrollBody.addEventListener('scroll', () => {
        this.lastScrollLeft = this.ui.scrollBody.scrollLeft;
        this.ui.timelineHead.style.transform = `translateX(${-this.lastScrollLeft}px)`;
        this.scheduleViewportRender();
        this.syncMiniMapViewport();
      });

      this.root.addEventListener('mousemove', (event) => this.onPointerMove(event));
      this.root.addEventListener('mouseup', () => this.finishDrag());
      this.root.addEventListener('mouseleave', () => this.finishDrag());
    }

    setZoom(value) {
      this.zoom = clamp(Math.round(value / 10) * 10, 30, 400);
      this.ui.zoomLabel.textContent = `${this.zoom}%`;
      this.render();
      this.log('View', 'info', 'Zoom changed', { zoom: this.zoom, grain: this.timeGrain });
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
      const payload = JSON.stringify(this.pendingChanges);
      invoke('SaveRequested', [payload]);
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
      if (!rows.length) {
        this.ui.labelPane.innerHTML = '';
        this.ui.timelineHead.innerHTML = '';
        this.ui.gridCanvas.innerHTML = '<svg class="lve-dependency-layer"></svg>';
        return;
      }

      this.syncTimegrainSelect();
      this.indexBars(bars);
      this.computeTimeline();
      this.computeVisibleRows(rows);
      this.buildDerivedCaches();
      this.renderTimelineHeader();
      this.renderRowsAndGrid();
      this.renderViewport();
      this.renderMiniMap();
      this.renderDirtyState();
    }

    renderTimelineHeader() {
      const topBand = document.createElement('div');
      topBand.className = 'lve-timeline-months';
      const bottomBand = document.createElement('div');
      bottomBand.className = 'lve-timeline-days';

      let currentGroupKey = '';
      let topCell = null;
      this.timelineCols.forEach((col) => {
        const topMeta = this.getTopBandMeta(col);
        if (topMeta.key !== currentGroupKey) {
          currentGroupKey = topMeta.key;
          topCell = document.createElement('div');
          topCell.className = 'month-cell';
          topCell.textContent = topMeta.label;
          topCell.style.width = '0px';
          topBand.appendChild(topCell);
        }
        if (topCell) topCell.style.width = `${parseFloat(topCell.style.width) + col.width}px`;

        const cell = document.createElement('div');
        cell.className = `day-cell${this.isWeekendColumn(col) ? ' weekend' : ''}`;
        cell.style.width = `${col.width}px`;
        cell.style.minWidth = `${col.width}px`;
        cell.style.maxWidth = `${col.width}px`;
        cell.textContent = this.getBottomBandLabel(col);
        bottomBand.appendChild(cell);
      });

      this.ui.timelineHead.style.width = `${this.totalTimelineWidth}px`;
      this.ui.timelineHead.innerHTML = '';
      this.ui.timelineHead.appendChild(topBand);
      this.ui.timelineHead.appendChild(bottomBand);
    }

    renderRowsAndGrid() {
      this.viewportWidth = this.totalTimelineWidth;
      this.totalContentHeight = this.visibleRows.length * this.rowHeight;

      this.ui.labelPane.innerHTML = '';
      const labelSurface = document.createElement('div');
      labelSurface.style.position = 'relative';
      labelSurface.style.height = `${this.totalContentHeight}px`;
      labelSurface.style.minHeight = `${this.totalContentHeight}px`;
      this.ui.labelPane.appendChild(labelSurface);
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
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0, 0);

      this.timelineCols.forEach((col) => {
        const x = this.dateToX(col.start);
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

      const todayLine = document.createElement('div');
      todayLine.className = 'today-line';
      todayLine.style.left = `${todayX}px`;
      bg.appendChild(todayLine);
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
      this.renderDependencies(range.start, range.end);
      this.renderConflicts();
    }

    renderVisibleRows(startIndex, endIndex) {
      const labelFragment = document.createDocumentFragment();
      const rowLineFragment = document.createDocumentFragment();

      for (let index = startIndex; index < endIndex; index += 1) {
        const row = this.visibleRows[index];
        if (!row) continue;

        const rowTop = index * this.rowHeight;
        const labelRow = document.createElement('div');
        labelRow.className = 'lve-label-row';
        labelRow.style.position = 'absolute';
        labelRow.style.left = '0';
        labelRow.style.right = '0';
        labelRow.style.top = `${rowTop}px`;
        labelRow.style.height = `${this.rowHeight}px`;
        labelRow.style.paddingLeft = `${8 + row.level * 16}px`;
        labelRow.dataset.rowId = row.rowId;

        const expander = document.createElement('button');
        expander.className = 'row-expander';
        expander.textContent = row.hasChildren ? (this.expandedRows.has(row.rowId) || row.isExpanded ? '▾' : '▸') : '•';
        expander.disabled = !row.hasChildren;
        expander.addEventListener('click', () => {
          if (!row.hasChildren) return;
          if (this.expandedRows.has(row.rowId)) this.expandedRows.delete(row.rowId);
          else this.expandedRows.add(row.rowId);
          this.log('Interaction', 'info', 'Row toggle', { rowId: row.rowId });
          this.render();
        });

        const textWrap = document.createElement('div');
        textWrap.className = 'row-text-wrap';
        textWrap.innerHTML = `<div class="key">${row.keyText || ''}</div><div class="desc">${row.descriptionText || ''}</div>`;
        labelRow.appendChild(expander);
        labelRow.appendChild(textWrap);
        this.addTooltipHandlers(labelRow, row.tooltipTitle, row.tooltipFields);
        labelFragment.appendChild(labelRow);

        const hLine = document.createElement('div');
        hLine.className = 'hline';
        hLine.style.top = `${rowTop + this.rowHeight - 1}px`;
        rowLineFragment.appendChild(hLine);
      }

      this.ui.labelSurface.appendChild(labelFragment);
      this.ui.gridRowLayer.appendChild(rowLineFragment);
    }

    renderBars(startIndex, endIndex) {
      const fragment = document.createDocumentFragment();

      for (let rowIndex = startIndex; rowIndex < endIndex; rowIndex += 1) {
        const row = this.visibleRows[rowIndex];
        if (!row) continue;

        const rowBars = this.barMapByRow.get(row.rowId) || [];
        rowBars.forEach((bar) => {
          const start = toDate(bar.start);
          const end = toDate(bar.end);
          if (!start || !end) return;
          const xStart = this.dateToX(start);
          const xEnd = this.dateToX(end);
          const width = Math.max(6, xEnd - xStart);
          const top = rowIndex * this.rowHeight + (bar.depth > 0 ? 11 : 8);
          const height = bar.depth > 0 ? 12 : 18;

          const barEl = document.createElement('div');
          barEl.className = 'lve-bar';
          if (this.selectedBarId === bar.barId) barEl.classList.add('selected');
          if (this.hasConflict(bar)) barEl.classList.add('conflict');
          if (this.isBarDirty(bar)) barEl.classList.add('dirty');

          barEl.style.left = `${xStart}px`;
          barEl.style.top = `${top}px`;
          barEl.style.width = `${width}px`;
          barEl.style.height = `${height}px`;
          barEl.style.background = bar.color || '#3AAB5C';

          const progress = document.createElement('div');
          progress.className = 'lve-bar-progress';
          progress.style.width = `${clamp(bar.progressPercent || 0, 0, 100)}%`;
          progress.style.background = bar.trackColor || 'rgba(255,255,255,0.45)';
          barEl.appendChild(progress);

          const label = document.createElement('span');
          label.className = 'lve-bar-label';
          label.textContent = width > 66 ? (bar.label || '') : '';
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

    renderDependencies(startIndex, endIndex) {
      const deps = this.payload.dependencies || [];
      const svg = this.ui.dependencyLayer;
      svg.setAttribute('width', String(this.viewportWidth));
      svg.setAttribute('height', String(this.totalContentHeight));

      const visibleRowIds = new Set();
      for (let index = startIndex; index < endIndex; index += 1) {
        const row = this.visibleRows[index];
        if (row) visibleRowIds.add(row.rowId);
      }

      const marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker');
      marker.setAttribute('id', 'lve-arrow');
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

      deps.forEach((dep) => {
        const sourceBar = this.barByDependencyKey.get(dep.sourceKey);
        const targetBar = this.barByDependencyKey.get(dep.targetKey);
        if (!sourceBar || !targetBar) return;
        if (!visibleRowIds.has(sourceBar.rowId) && !visibleRowIds.has(targetBar.rowId)) return;

        const sourceRowIndex = this.rowIndexById.get(sourceBar.rowId);
        const targetRowIndex = this.rowIndexById.get(targetBar.rowId);
        if (sourceRowIndex === undefined || targetRowIndex === undefined) return;

        const sourceDate = toDate(sourceBar.end || sourceBar.start);
        const targetDate = toDate(targetBar.start);
        if (!sourceDate || !targetDate) return;

        const sx = this.dateToX(sourceDate);
        const tx = this.dateToX(targetDate);
        const sy = sourceRowIndex * this.rowHeight + 18;
        const ty = targetRowIndex * this.rowHeight + 18;
        const mid = sx + Math.max(14, Math.min(38, Math.abs(tx - sx) / 2));

        const arrow = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        arrow.setAttribute('d', `M ${sx} ${sy} L ${mid} ${sy} L ${mid} ${ty} L ${tx} ${ty}`);
        arrow.setAttribute('fill', 'none');
        arrow.setAttribute('stroke', '#60728a');
        arrow.setAttribute('stroke-width', '1.2');
        arrow.setAttribute('marker-end', 'url(#lve-arrow)');
        svg.appendChild(arrow);
      });
    }

    hasConflict(bar) {
      return this.conflictingBarIds.has(bar.barId);
    }

    renderConflicts() {
      this.ui.labelSurface.querySelectorAll('.lve-label-row').forEach((el) => {
        el.classList.toggle('has-conflict', this.rowsWithConflict.has(el.dataset.rowId));
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

      this.dragState = {
        mode,
        bar,
        row,
        startClientX: event.clientX,
        originalStart: toDate(bar.start),
        originalEnd: toDate(bar.end),
        originalXStart: xStart,
        originalXEnd: xEnd,
        ghost: null
      };

      const rowIndex = this.rowIndexById.get(row.rowId) || 0;
      const ghost = document.createElement('div');
      ghost.className = 'lve-bar-ghost';
      ghost.style.left = `${xStart}px`;
      ghost.style.top = `${rowIndex * this.rowHeight + (bar.depth > 0 ? 11 : 8)}px`;
      ghost.style.width = `${Math.max(6, xEnd - xStart)}px`;
      ghost.style.height = `${bar.depth > 0 ? 12 : 18}px`;
      this.ui.gridBarLayer.appendChild(ghost);
      this.dragState.ghost = ghost;
      this.log('Interaction', 'info', 'Drag start', { barId: bar.barId, mode });
      event.preventDefault();
    }

    onPointerMove(event) {
      if (!this.dragState) return;
      const deltaPx = event.clientX - this.dragState.startClientX;
      const msPerPx = this.millisecondsPerPixel();
      const deltaMs = deltaPx * msPerPx;
      const { mode, originalStart, originalEnd, ghost } = this.dragState;
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
      if (state.ghost) state.ghost.remove();
      this.dragState = null;
      if (!state.newStart || !state.newEnd) return;

      const bar = state.bar;
      const oldStart = bar.start;
      const oldEnd = bar.end;
      bar.start = state.newStart.toISOString();
      bar.end = state.newEnd.toISOString();

      this.addPendingChange(bar, 'start', oldStart, bar.start, (this.payload.setup || {}).setupId);
      this.addPendingChange(bar, 'end', oldEnd, bar.end, (this.payload.setup || {}).setupId);
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
      this.ui.saveButton.disabled = !this.dirty;
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
      this.visibleRows.forEach((row, idx) => {
        const bars = this.barMapByRow.get(row.rowId) || [];
        bars.forEach((bar) => {
          const start = toDate(bar.start);
          const end = toDate(bar.end);
          if (!start || !end) return;
          const x = this.dateToX(start) * scale;
          const w = Math.max(1, (this.dateToX(end) - this.dateToX(start)) * scale);
          const y = (idx % 20) * 2;
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
        if (title) parts.push(`<div class="title">${title}</div>`);
        (fields || []).forEach((field) => {
          parts.push(`<div class="line"><span>${field.caption || ''}</span><strong>${field.value || ''}</strong></div>`);
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
      if (!dateObj) return 0;
      const startMs = this.timelineStart.getTime();
      const endMs = this.timelineEnd.getTime();
      const ratio = (dateObj.getTime() - startMs) / Math.max(1, endMs - startMs);
      return ratio * this.totalTimelineWidth;
    }

    millisecondsPerPixel() {
      const totalMs = this.timelineEnd.getTime() - this.timelineStart.getTime();
      return totalMs / Math.max(this.totalTimelineWidth, 1);
    }

    minimumBarMs() {
      return this.zoom >= 220 ? 3600 * 1000 : 24 * 3600 * 1000;
    }
  }

  window.LVEGanttChart = LVEGanttChart;
})();