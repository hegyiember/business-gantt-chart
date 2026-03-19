(function () {
  const queue = [];
  const state = {
    initialized: false,
    chart: null,
    root: null,
    initStarted: false
  };

  function invoke(eventName, args) {
    try {
      if (window.Microsoft && Microsoft.Dynamics && Microsoft.Dynamics.NAV) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(eventName, args || []);
      }
    } catch (error) {
      console.error('[GANTT][startup-invoke-error]', eventName, error);
    }
  }

  function log(level, message, context) {
    invoke('LogMessage', ['Initialization', level, message, JSON.stringify(context || {})]);
  }

  function validParent(node) {
    if (!node || !node.tagName) return false;
    const tag = node.tagName.toUpperCase();
    return tag !== 'HEAD' && tag !== 'SCRIPT' && tag !== 'HTML';
  }

  function findRootElement() {
    const byKnownId = document.getElementById('controlAddIn');
    if (validParent(byKnownId)) return byKnownId;

    const byPrefix = document.querySelector('[id^="controlAddIn"]');
    if (validParent(byPrefix)) return byPrefix;

    const scripts = document.getElementsByTagName('script');
    const current = scripts[scripts.length - 1];
    if (current && validParent(current.parentElement)) return current.parentElement;

    if (document.body && validParent(document.body)) return document.body;

    return null;
  }

  function runQueuedActions() {
    while (queue.length) {
      const next = queue.shift();
      try {
        next();
      } catch (error) {
        log('error', 'Queued action failed', { message: error.message });
      }
    }
  }

  function initWhenDomReady() {
    if (state.initialized || state.initStarted) return;
    state.initStarted = true;

    const start = function () {
      if (!document.body) {
        log('warn', 'document.body not available; waiting for DOMContentLoaded', {});
        document.addEventListener('DOMContentLoaded', initWhenDomReady, { once: true });
        state.initStarted = false;
        return;
      }

      const root = findRootElement();
      if (!validParent(root)) {
        log('error', 'Could not resolve valid root element; refusing HEAD/script/html', {
          hasBody: !!document.body,
          resolvedTag: root && root.tagName ? root.tagName : null
        });
        state.initStarted = false;
        return;
      }

      state.root = root;
      try {
        state.chart = new window.LVEGanttChart(root);
        state.chart.init();
        state.initialized = true;
        log('info', 'Gantt initialized successfully', { tagName: root.tagName, id: root.id || '' });
        runQueuedActions();
        invoke('ControlReady', []);
      } catch (error) {
        log('error', 'Gantt initialization failed', { message: error.message, stack: error.stack || '' });
      }
    };

    if (document.readyState === 'loading' || !document.body) {
      state.initStarted = false;
      document.addEventListener('DOMContentLoaded', start, { once: true });
      return;
    }

    start();
  }

  function enqueueOrRun(action) {
    if (!state.initialized || !state.chart) {
      queue.push(action);
      initWhenDomReady();
      return;
    }
    action();
  }

  window.LoadData = function (payloadJson) {
    enqueueOrRun(function () {
      try {
        const payload = payloadJson ? JSON.parse(payloadJson) : {};
        state.chart.load(payload);
      } catch (error) {
        log('error', 'LoadData parsing failed', { message: error.message });
      }
    });
  };

  window.ShowNotification = function (messageText, level) {
    enqueueOrRun(function () {
      state.chart.showNotification(messageText || '', level || 'info');
    });
  };

  window.SetBusyState = function (captionText, isBusy) {
    enqueueOrRun(function () {
      state.chart.setBusy(captionText || '', !!isBusy);
    });
  };

  window.SetZoom = function (zoomPercent) {
    enqueueOrRun(function () {
      state.chart.setZoom(Number(zoomPercent || 100));
    });
  };

  window.RequestClientSave = function () {
    enqueueOrRun(function () {
      state.chart.requestClientSave();
    });
  };

  window.RequestClientReload = function () {
    enqueueOrRun(function () {
      state.chart.requestClientReload();
    });
  };

  initWhenDomReady();
})();
