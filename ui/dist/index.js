import { createRequire } from 'module'; const require = createRequire(import.meta.url);
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __require = /* @__PURE__ */ ((x) => typeof require !== "undefined" ? require : typeof Proxy !== "undefined" ? new Proxy(x, {
  get: (a, b) => (typeof require !== "undefined" ? require : a)[b]
}) : x)(function(x) {
  if (typeof require !== "undefined") return require.apply(this, arguments);
  throw Error('Dynamic require of "' + x + '" is not supported');
});
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __commonJS = (cb, mod) => function __require2() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// node_modules/react/cjs/react.production.min.js
var require_react_production_min = __commonJS({
  "node_modules/react/cjs/react.production.min.js"(exports) {
    "use strict";
    var l = /* @__PURE__ */ Symbol.for("react.element");
    var n = /* @__PURE__ */ Symbol.for("react.portal");
    var p = /* @__PURE__ */ Symbol.for("react.fragment");
    var q = /* @__PURE__ */ Symbol.for("react.strict_mode");
    var r = /* @__PURE__ */ Symbol.for("react.profiler");
    var t = /* @__PURE__ */ Symbol.for("react.provider");
    var u = /* @__PURE__ */ Symbol.for("react.context");
    var v = /* @__PURE__ */ Symbol.for("react.forward_ref");
    var w = /* @__PURE__ */ Symbol.for("react.suspense");
    var x = /* @__PURE__ */ Symbol.for("react.memo");
    var y = /* @__PURE__ */ Symbol.for("react.lazy");
    var z = Symbol.iterator;
    function A(a) {
      if (null === a || "object" !== typeof a) return null;
      a = z && a[z] || a["@@iterator"];
      return "function" === typeof a ? a : null;
    }
    var B = { isMounted: function() {
      return false;
    }, enqueueForceUpdate: function() {
    }, enqueueReplaceState: function() {
    }, enqueueSetState: function() {
    } };
    var C = Object.assign;
    var D = {};
    function E(a, b, e) {
      this.props = a;
      this.context = b;
      this.refs = D;
      this.updater = e || B;
    }
    E.prototype.isReactComponent = {};
    E.prototype.setState = function(a, b) {
      if ("object" !== typeof a && "function" !== typeof a && null != a) throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");
      this.updater.enqueueSetState(this, a, b, "setState");
    };
    E.prototype.forceUpdate = function(a) {
      this.updater.enqueueForceUpdate(this, a, "forceUpdate");
    };
    function F() {
    }
    F.prototype = E.prototype;
    function G(a, b, e) {
      this.props = a;
      this.context = b;
      this.refs = D;
      this.updater = e || B;
    }
    var H = G.prototype = new F();
    H.constructor = G;
    C(H, E.prototype);
    H.isPureReactComponent = true;
    var I = Array.isArray;
    var J = Object.prototype.hasOwnProperty;
    var K = { current: null };
    var L = { key: true, ref: true, __self: true, __source: true };
    function M(a, b, e) {
      var d, c = {}, k = null, h = null;
      if (null != b) for (d in void 0 !== b.ref && (h = b.ref), void 0 !== b.key && (k = "" + b.key), b) J.call(b, d) && !L.hasOwnProperty(d) && (c[d] = b[d]);
      var g = arguments.length - 2;
      if (1 === g) c.children = e;
      else if (1 < g) {
        for (var f = Array(g), m = 0; m < g; m++) f[m] = arguments[m + 2];
        c.children = f;
      }
      if (a && a.defaultProps) for (d in g = a.defaultProps, g) void 0 === c[d] && (c[d] = g[d]);
      return { $$typeof: l, type: a, key: k, ref: h, props: c, _owner: K.current };
    }
    function N(a, b) {
      return { $$typeof: l, type: a.type, key: b, ref: a.ref, props: a.props, _owner: a._owner };
    }
    function O(a) {
      return "object" === typeof a && null !== a && a.$$typeof === l;
    }
    function escape2(a) {
      var b = { "=": "=0", ":": "=2" };
      return "$" + a.replace(/[=:]/g, function(a2) {
        return b[a2];
      });
    }
    var P = /\/+/g;
    function Q(a, b) {
      return "object" === typeof a && null !== a && null != a.key ? escape2("" + a.key) : b.toString(36);
    }
    function R(a, b, e, d, c) {
      var k = typeof a;
      if ("undefined" === k || "boolean" === k) a = null;
      var h = false;
      if (null === a) h = true;
      else switch (k) {
        case "string":
        case "number":
          h = true;
          break;
        case "object":
          switch (a.$$typeof) {
            case l:
            case n:
              h = true;
          }
      }
      if (h) return h = a, c = c(h), a = "" === d ? "." + Q(h, 0) : d, I(c) ? (e = "", null != a && (e = a.replace(P, "$&/") + "/"), R(c, b, e, "", function(a2) {
        return a2;
      })) : null != c && (O(c) && (c = N(c, e + (!c.key || h && h.key === c.key ? "" : ("" + c.key).replace(P, "$&/") + "/") + a)), b.push(c)), 1;
      h = 0;
      d = "" === d ? "." : d + ":";
      if (I(a)) for (var g = 0; g < a.length; g++) {
        k = a[g];
        var f = d + Q(k, g);
        h += R(k, b, e, f, c);
      }
      else if (f = A(a), "function" === typeof f) for (a = f.call(a), g = 0; !(k = a.next()).done; ) k = k.value, f = d + Q(k, g++), h += R(k, b, e, f, c);
      else if ("object" === k) throw b = String(a), Error("Objects are not valid as a React child (found: " + ("[object Object]" === b ? "object with keys {" + Object.keys(a).join(", ") + "}" : b) + "). If you meant to render a collection of children, use an array instead.");
      return h;
    }
    function S(a, b, e) {
      if (null == a) return a;
      var d = [], c = 0;
      R(a, d, "", "", function(a2) {
        return b.call(e, a2, c++);
      });
      return d;
    }
    function T(a) {
      if (-1 === a._status) {
        var b = a._result;
        b = b();
        b.then(function(b2) {
          if (0 === a._status || -1 === a._status) a._status = 1, a._result = b2;
        }, function(b2) {
          if (0 === a._status || -1 === a._status) a._status = 2, a._result = b2;
        });
        -1 === a._status && (a._status = 0, a._result = b);
      }
      if (1 === a._status) return a._result.default;
      throw a._result;
    }
    var U = { current: null };
    var V = { transition: null };
    var W = { ReactCurrentDispatcher: U, ReactCurrentBatchConfig: V, ReactCurrentOwner: K };
    function X() {
      throw Error("act(...) is not supported in production builds of React.");
    }
    exports.Children = { map: S, forEach: function(a, b, e) {
      S(a, function() {
        b.apply(this, arguments);
      }, e);
    }, count: function(a) {
      var b = 0;
      S(a, function() {
        b++;
      });
      return b;
    }, toArray: function(a) {
      return S(a, function(a2) {
        return a2;
      }) || [];
    }, only: function(a) {
      if (!O(a)) throw Error("React.Children.only expected to receive a single React element child.");
      return a;
    } };
    exports.Component = E;
    exports.Fragment = p;
    exports.Profiler = r;
    exports.PureComponent = G;
    exports.StrictMode = q;
    exports.Suspense = w;
    exports.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = W;
    exports.act = X;
    exports.cloneElement = function(a, b, e) {
      if (null === a || void 0 === a) throw Error("React.cloneElement(...): The argument must be a React element, but you passed " + a + ".");
      var d = C({}, a.props), c = a.key, k = a.ref, h = a._owner;
      if (null != b) {
        void 0 !== b.ref && (k = b.ref, h = K.current);
        void 0 !== b.key && (c = "" + b.key);
        if (a.type && a.type.defaultProps) var g = a.type.defaultProps;
        for (f in b) J.call(b, f) && !L.hasOwnProperty(f) && (d[f] = void 0 === b[f] && void 0 !== g ? g[f] : b[f]);
      }
      var f = arguments.length - 2;
      if (1 === f) d.children = e;
      else if (1 < f) {
        g = Array(f);
        for (var m = 0; m < f; m++) g[m] = arguments[m + 2];
        d.children = g;
      }
      return { $$typeof: l, type: a.type, key: c, ref: k, props: d, _owner: h };
    };
    exports.createContext = function(a) {
      a = { $$typeof: u, _currentValue: a, _currentValue2: a, _threadCount: 0, Provider: null, Consumer: null, _defaultValue: null, _globalName: null };
      a.Provider = { $$typeof: t, _context: a };
      return a.Consumer = a;
    };
    exports.createElement = M;
    exports.createFactory = function(a) {
      var b = M.bind(null, a);
      b.type = a;
      return b;
    };
    exports.createRef = function() {
      return { current: null };
    };
    exports.forwardRef = function(a) {
      return { $$typeof: v, render: a };
    };
    exports.isValidElement = O;
    exports.lazy = function(a) {
      return { $$typeof: y, _payload: { _status: -1, _result: a }, _init: T };
    };
    exports.memo = function(a, b) {
      return { $$typeof: x, type: a, compare: void 0 === b ? null : b };
    };
    exports.startTransition = function(a) {
      var b = V.transition;
      V.transition = {};
      try {
        a();
      } finally {
        V.transition = b;
      }
    };
    exports.unstable_act = X;
    exports.useCallback = function(a, b) {
      return U.current.useCallback(a, b);
    };
    exports.useContext = function(a) {
      return U.current.useContext(a);
    };
    exports.useDebugValue = function() {
    };
    exports.useDeferredValue = function(a) {
      return U.current.useDeferredValue(a);
    };
    exports.useEffect = function(a, b) {
      return U.current.useEffect(a, b);
    };
    exports.useId = function() {
      return U.current.useId();
    };
    exports.useImperativeHandle = function(a, b, e) {
      return U.current.useImperativeHandle(a, b, e);
    };
    exports.useInsertionEffect = function(a, b) {
      return U.current.useInsertionEffect(a, b);
    };
    exports.useLayoutEffect = function(a, b) {
      return U.current.useLayoutEffect(a, b);
    };
    exports.useMemo = function(a, b) {
      return U.current.useMemo(a, b);
    };
    exports.useReducer = function(a, b, e) {
      return U.current.useReducer(a, b, e);
    };
    exports.useRef = function(a) {
      return U.current.useRef(a);
    };
    exports.useState = function(a) {
      return U.current.useState(a);
    };
    exports.useSyncExternalStore = function(a, b, e) {
      return U.current.useSyncExternalStore(a, b, e);
    };
    exports.useTransition = function() {
      return U.current.useTransition();
    };
    exports.version = "18.3.1";
  }
});

// node_modules/react/index.js
var require_react = __commonJS({
  "node_modules/react/index.js"(exports, module) {
    "use strict";
    if (true) {
      module.exports = require_react_production_min();
    } else {
      module.exports = null;
    }
  }
});

// node_modules/signal-exit/signals.js
var require_signals = __commonJS({
  "node_modules/signal-exit/signals.js"(exports, module) {
    "use strict";
    module.exports = [
      "SIGABRT",
      "SIGALRM",
      "SIGHUP",
      "SIGINT",
      "SIGTERM"
    ];
    if (process.platform !== "win32") {
      module.exports.push(
        "SIGVTALRM",
        "SIGXCPU",
        "SIGXFSZ",
        "SIGUSR2",
        "SIGTRAP",
        "SIGSYS",
        "SIGQUIT",
        "SIGIOT"
        // should detect profiler and enable/disable accordingly.
        // see #21
        // 'SIGPROF'
      );
    }
    if (process.platform === "linux") {
      module.exports.push(
        "SIGIO",
        "SIGPOLL",
        "SIGPWR",
        "SIGSTKFLT",
        "SIGUNUSED"
      );
    }
  }
});

// node_modules/signal-exit/index.js
var require_signal_exit = __commonJS({
  "node_modules/signal-exit/index.js"(exports, module) {
    "use strict";
    var process13 = global.process;
    var processOk = function(process14) {
      return process14 && typeof process14 === "object" && typeof process14.removeListener === "function" && typeof process14.emit === "function" && typeof process14.reallyExit === "function" && typeof process14.listeners === "function" && typeof process14.kill === "function" && typeof process14.pid === "number" && typeof process14.on === "function";
    };
    if (!processOk(process13)) {
      module.exports = function() {
        return function() {
        };
      };
    } else {
      assert = __require("assert");
      signals = require_signals();
      isWin = /^win/i.test(process13.platform);
      EE = __require("events");
      if (typeof EE !== "function") {
        EE = EE.EventEmitter;
      }
      if (process13.__signal_exit_emitter__) {
        emitter = process13.__signal_exit_emitter__;
      } else {
        emitter = process13.__signal_exit_emitter__ = new EE();
        emitter.count = 0;
        emitter.emitted = {};
      }
      if (!emitter.infinite) {
        emitter.setMaxListeners(Infinity);
        emitter.infinite = true;
      }
      module.exports = function(cb, opts) {
        if (!processOk(global.process)) {
          return function() {
          };
        }
        assert.equal(typeof cb, "function", "a callback must be provided for exit handler");
        if (loaded === false) {
          load();
        }
        var ev = "exit";
        if (opts && opts.alwaysLast) {
          ev = "afterexit";
        }
        var remove = function() {
          emitter.removeListener(ev, cb);
          if (emitter.listeners("exit").length === 0 && emitter.listeners("afterexit").length === 0) {
            unload();
          }
        };
        emitter.on(ev, cb);
        return remove;
      };
      unload = function unload2() {
        if (!loaded || !processOk(global.process)) {
          return;
        }
        loaded = false;
        signals.forEach(function(sig) {
          try {
            process13.removeListener(sig, sigListeners[sig]);
          } catch (er) {
          }
        });
        process13.emit = originalProcessEmit;
        process13.reallyExit = originalProcessReallyExit;
        emitter.count -= 1;
      };
      module.exports.unload = unload;
      emit = function emit2(event, code, signal) {
        if (emitter.emitted[event]) {
          return;
        }
        emitter.emitted[event] = true;
        emitter.emit(event, code, signal);
      };
      sigListeners = {};
      signals.forEach(function(sig) {
        sigListeners[sig] = function listener() {
          if (!processOk(global.process)) {
            return;
          }
          var listeners = process13.listeners(sig);
          if (listeners.length === emitter.count) {
            unload();
            emit("exit", null, sig);
            emit("afterexit", null, sig);
            if (isWin && sig === "SIGHUP") {
              sig = "SIGINT";
            }
            process13.kill(process13.pid, sig);
          }
        };
      });
      module.exports.signals = function() {
        return signals;
      };
      loaded = false;
      load = function load2() {
        if (loaded || !processOk(global.process)) {
          return;
        }
        loaded = true;
        emitter.count += 1;
        signals = signals.filter(function(sig) {
          try {
            process13.on(sig, sigListeners[sig]);
            return true;
          } catch (er) {
            return false;
          }
        });
        process13.emit = processEmit;
        process13.reallyExit = processReallyExit;
      };
      module.exports.load = load;
      originalProcessReallyExit = process13.reallyExit;
      processReallyExit = function processReallyExit2(code) {
        if (!processOk(global.process)) {
          return;
        }
        process13.exitCode = code || /* istanbul ignore next */
        0;
        emit("exit", process13.exitCode, null);
        emit("afterexit", process13.exitCode, null);
        originalProcessReallyExit.call(process13, process13.exitCode);
      };
      originalProcessEmit = process13.emit;
      processEmit = function processEmit2(ev, arg) {
        if (ev === "exit" && processOk(global.process)) {
          if (arg !== void 0) {
            process13.exitCode = arg;
          }
          var ret = originalProcessEmit.apply(this, arguments);
          emit("exit", process13.exitCode, null);
          emit("afterexit", process13.exitCode, null);
          return ret;
        } else {
          return originalProcessEmit.apply(this, arguments);
        }
      };
    }
    var assert;
    var signals;
    var isWin;
    var EE;
    var emitter;
    var unload;
    var emit;
    var sigListeners;
    var loaded;
    var load;
    var originalProcessReallyExit;
    var processReallyExit;
    var originalProcessEmit;
    var processEmit;
  }
});

// node_modules/scheduler/cjs/scheduler.production.min.js
var require_scheduler_production_min = __commonJS({
  "node_modules/scheduler/cjs/scheduler.production.min.js"(exports) {
    "use strict";
    function f(a, b) {
      var c = a.length;
      a.push(b);
      a: for (; 0 < c; ) {
        var d = c - 1 >>> 1, e = a[d];
        if (0 < g(e, b)) a[d] = b, a[c] = e, c = d;
        else break a;
      }
    }
    function h(a) {
      return 0 === a.length ? null : a[0];
    }
    function k(a) {
      if (0 === a.length) return null;
      var b = a[0], c = a.pop();
      if (c !== b) {
        a[0] = c;
        a: for (var d = 0, e = a.length, w = e >>> 1; d < w; ) {
          var m = 2 * (d + 1) - 1, C = a[m], n = m + 1, x = a[n];
          if (0 > g(C, c)) n < e && 0 > g(x, C) ? (a[d] = x, a[n] = c, d = n) : (a[d] = C, a[m] = c, d = m);
          else if (n < e && 0 > g(x, c)) a[d] = x, a[n] = c, d = n;
          else break a;
        }
      }
      return b;
    }
    function g(a, b) {
      var c = a.sortIndex - b.sortIndex;
      return 0 !== c ? c : a.id - b.id;
    }
    if ("object" === typeof performance && "function" === typeof performance.now) {
      l = performance;
      exports.unstable_now = function() {
        return l.now();
      };
    } else {
      p = Date, q = p.now();
      exports.unstable_now = function() {
        return p.now() - q;
      };
    }
    var l;
    var p;
    var q;
    var r = [];
    var t = [];
    var u = 1;
    var v = null;
    var y = 3;
    var z = false;
    var A = false;
    var B = false;
    var D = "function" === typeof setTimeout ? setTimeout : null;
    var E = "function" === typeof clearTimeout ? clearTimeout : null;
    var F = "undefined" !== typeof setImmediate ? setImmediate : null;
    "undefined" !== typeof navigator && void 0 !== navigator.scheduling && void 0 !== navigator.scheduling.isInputPending && navigator.scheduling.isInputPending.bind(navigator.scheduling);
    function G(a) {
      for (var b = h(t); null !== b; ) {
        if (null === b.callback) k(t);
        else if (b.startTime <= a) k(t), b.sortIndex = b.expirationTime, f(r, b);
        else break;
        b = h(t);
      }
    }
    function H(a) {
      B = false;
      G(a);
      if (!A) if (null !== h(r)) A = true, I(J);
      else {
        var b = h(t);
        null !== b && K(H, b.startTime - a);
      }
    }
    function J(a, b) {
      A = false;
      B && (B = false, E(L), L = -1);
      z = true;
      var c = y;
      try {
        G(b);
        for (v = h(r); null !== v && (!(v.expirationTime > b) || a && !M()); ) {
          var d = v.callback;
          if ("function" === typeof d) {
            v.callback = null;
            y = v.priorityLevel;
            var e = d(v.expirationTime <= b);
            b = exports.unstable_now();
            "function" === typeof e ? v.callback = e : v === h(r) && k(r);
            G(b);
          } else k(r);
          v = h(r);
        }
        if (null !== v) var w = true;
        else {
          var m = h(t);
          null !== m && K(H, m.startTime - b);
          w = false;
        }
        return w;
      } finally {
        v = null, y = c, z = false;
      }
    }
    var N = false;
    var O = null;
    var L = -1;
    var P = 5;
    var Q = -1;
    function M() {
      return exports.unstable_now() - Q < P ? false : true;
    }
    function R() {
      if (null !== O) {
        var a = exports.unstable_now();
        Q = a;
        var b = true;
        try {
          b = O(true, a);
        } finally {
          b ? S() : (N = false, O = null);
        }
      } else N = false;
    }
    var S;
    if ("function" === typeof F) S = function() {
      F(R);
    };
    else if ("undefined" !== typeof MessageChannel) {
      T = new MessageChannel(), U = T.port2;
      T.port1.onmessage = R;
      S = function() {
        U.postMessage(null);
      };
    } else S = function() {
      D(R, 0);
    };
    var T;
    var U;
    function I(a) {
      O = a;
      N || (N = true, S());
    }
    function K(a, b) {
      L = D(function() {
        a(exports.unstable_now());
      }, b);
    }
    exports.unstable_IdlePriority = 5;
    exports.unstable_ImmediatePriority = 1;
    exports.unstable_LowPriority = 4;
    exports.unstable_NormalPriority = 3;
    exports.unstable_Profiling = null;
    exports.unstable_UserBlockingPriority = 2;
    exports.unstable_cancelCallback = function(a) {
      a.callback = null;
    };
    exports.unstable_continueExecution = function() {
      A || z || (A = true, I(J));
    };
    exports.unstable_forceFrameRate = function(a) {
      0 > a || 125 < a ? console.error("forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported") : P = 0 < a ? Math.floor(1e3 / a) : 5;
    };
    exports.unstable_getCurrentPriorityLevel = function() {
      return y;
    };
    exports.unstable_getFirstCallbackNode = function() {
      return h(r);
    };
    exports.unstable_next = function(a) {
      switch (y) {
        case 1:
        case 2:
        case 3:
          var b = 3;
          break;
        default:
          b = y;
      }
      var c = y;
      y = b;
      try {
        return a();
      } finally {
        y = c;
      }
    };
    exports.unstable_pauseExecution = function() {
    };
    exports.unstable_requestPaint = function() {
    };
    exports.unstable_runWithPriority = function(a, b) {
      switch (a) {
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
          break;
        default:
          a = 3;
      }
      var c = y;
      y = a;
      try {
        return b();
      } finally {
        y = c;
      }
    };
    exports.unstable_scheduleCallback = function(a, b, c) {
      var d = exports.unstable_now();
      "object" === typeof c && null !== c ? (c = c.delay, c = "number" === typeof c && 0 < c ? d + c : d) : c = d;
      switch (a) {
        case 1:
          var e = -1;
          break;
        case 2:
          e = 250;
          break;
        case 5:
          e = 1073741823;
          break;
        case 4:
          e = 1e4;
          break;
        default:
          e = 5e3;
      }
      e = c + e;
      a = { id: u++, callback: b, priorityLevel: a, startTime: c, expirationTime: e, sortIndex: -1 };
      c > d ? (a.sortIndex = c, f(t, a), null === h(r) && a === h(t) && (B ? (E(L), L = -1) : B = true, K(H, c - d))) : (a.sortIndex = e, f(r, a), A || z || (A = true, I(J)));
      return a;
    };
    exports.unstable_shouldYield = M;
    exports.unstable_wrapCallback = function(a) {
      var b = y;
      return function() {
        var c = y;
        y = b;
        try {
          return a.apply(this, arguments);
        } finally {
          y = c;
        }
      };
    };
  }
});

// node_modules/scheduler/index.js
var require_scheduler = __commonJS({
  "node_modules/scheduler/index.js"(exports, module) {
    "use strict";
    if (true) {
      module.exports = require_scheduler_production_min();
    } else {
      module.exports = null;
    }
  }
});

// node_modules/react-reconciler/cjs/react-reconciler.production.min.js
var require_react_reconciler_production_min = __commonJS({
  "node_modules/react-reconciler/cjs/react-reconciler.production.min.js"(exports, module) {
    "use strict";
    module.exports = function $$$reconciler($$$hostConfig) {
      var exports2 = {};
      "use strict";
      var aa = require_react(), ba = require_scheduler(), ca = Object.assign;
      function n(a) {
        for (var b = "https://reactjs.org/docs/error-decoder.html?invariant=" + a, c = 1; c < arguments.length; c++) b += "&args[]=" + encodeURIComponent(arguments[c]);
        return "Minified React error #" + a + "; visit " + b + " for the full message or use the non-minified dev environment for full errors and additional helpful warnings.";
      }
      var da = aa.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED, ea = /* @__PURE__ */ Symbol.for("react.element"), fa = /* @__PURE__ */ Symbol.for("react.portal"), ha = /* @__PURE__ */ Symbol.for("react.fragment"), ia = /* @__PURE__ */ Symbol.for("react.strict_mode"), ja = /* @__PURE__ */ Symbol.for("react.profiler"), ka = /* @__PURE__ */ Symbol.for("react.provider"), la = /* @__PURE__ */ Symbol.for("react.context"), ma = /* @__PURE__ */ Symbol.for("react.forward_ref"), na = /* @__PURE__ */ Symbol.for("react.suspense"), oa = /* @__PURE__ */ Symbol.for("react.suspense_list"), pa = /* @__PURE__ */ Symbol.for("react.memo"), qa = /* @__PURE__ */ Symbol.for("react.lazy");
      /* @__PURE__ */ Symbol.for("react.scope");
      /* @__PURE__ */ Symbol.for("react.debug_trace_mode");
      var ra = /* @__PURE__ */ Symbol.for("react.offscreen");
      /* @__PURE__ */ Symbol.for("react.legacy_hidden");
      /* @__PURE__ */ Symbol.for("react.cache");
      /* @__PURE__ */ Symbol.for("react.tracing_marker");
      var sa = Symbol.iterator;
      function ta(a) {
        if (null === a || "object" !== typeof a) return null;
        a = sa && a[sa] || a["@@iterator"];
        return "function" === typeof a ? a : null;
      }
      function ua(a) {
        if (null == a) return null;
        if ("function" === typeof a) return a.displayName || a.name || null;
        if ("string" === typeof a) return a;
        switch (a) {
          case ha:
            return "Fragment";
          case fa:
            return "Portal";
          case ja:
            return "Profiler";
          case ia:
            return "StrictMode";
          case na:
            return "Suspense";
          case oa:
            return "SuspenseList";
        }
        if ("object" === typeof a) switch (a.$$typeof) {
          case la:
            return (a.displayName || "Context") + ".Consumer";
          case ka:
            return (a._context.displayName || "Context") + ".Provider";
          case ma:
            var b = a.render;
            a = a.displayName;
            a || (a = b.displayName || b.name || "", a = "" !== a ? "ForwardRef(" + a + ")" : "ForwardRef");
            return a;
          case pa:
            return b = a.displayName || null, null !== b ? b : ua(a.type) || "Memo";
          case qa:
            b = a._payload;
            a = a._init;
            try {
              return ua(a(b));
            } catch (c) {
            }
        }
        return null;
      }
      function va(a) {
        var b = a.type;
        switch (a.tag) {
          case 24:
            return "Cache";
          case 9:
            return (b.displayName || "Context") + ".Consumer";
          case 10:
            return (b._context.displayName || "Context") + ".Provider";
          case 18:
            return "DehydratedFragment";
          case 11:
            return a = b.render, a = a.displayName || a.name || "", b.displayName || ("" !== a ? "ForwardRef(" + a + ")" : "ForwardRef");
          case 7:
            return "Fragment";
          case 5:
            return b;
          case 4:
            return "Portal";
          case 3:
            return "Root";
          case 6:
            return "Text";
          case 16:
            return ua(b);
          case 8:
            return b === ia ? "StrictMode" : "Mode";
          case 22:
            return "Offscreen";
          case 12:
            return "Profiler";
          case 21:
            return "Scope";
          case 13:
            return "Suspense";
          case 19:
            return "SuspenseList";
          case 25:
            return "TracingMarker";
          case 1:
          case 0:
          case 17:
          case 2:
          case 14:
          case 15:
            if ("function" === typeof b) return b.displayName || b.name || null;
            if ("string" === typeof b) return b;
        }
        return null;
      }
      function wa(a) {
        var b = a, c = a;
        if (a.alternate) for (; b.return; ) b = b.return;
        else {
          a = b;
          do
            b = a, 0 !== (b.flags & 4098) && (c = b.return), a = b.return;
          while (a);
        }
        return 3 === b.tag ? c : null;
      }
      function xa(a) {
        if (wa(a) !== a) throw Error(n(188));
      }
      function za(a) {
        var b = a.alternate;
        if (!b) {
          b = wa(a);
          if (null === b) throw Error(n(188));
          return b !== a ? null : a;
        }
        for (var c = a, d = b; ; ) {
          var e = c.return;
          if (null === e) break;
          var f = e.alternate;
          if (null === f) {
            d = e.return;
            if (null !== d) {
              c = d;
              continue;
            }
            break;
          }
          if (e.child === f.child) {
            for (f = e.child; f; ) {
              if (f === c) return xa(e), a;
              if (f === d) return xa(e), b;
              f = f.sibling;
            }
            throw Error(n(188));
          }
          if (c.return !== d.return) c = e, d = f;
          else {
            for (var g = false, h = e.child; h; ) {
              if (h === c) {
                g = true;
                c = e;
                d = f;
                break;
              }
              if (h === d) {
                g = true;
                d = e;
                c = f;
                break;
              }
              h = h.sibling;
            }
            if (!g) {
              for (h = f.child; h; ) {
                if (h === c) {
                  g = true;
                  c = f;
                  d = e;
                  break;
                }
                if (h === d) {
                  g = true;
                  d = f;
                  c = e;
                  break;
                }
                h = h.sibling;
              }
              if (!g) throw Error(n(189));
            }
          }
          if (c.alternate !== d) throw Error(n(190));
        }
        if (3 !== c.tag) throw Error(n(188));
        return c.stateNode.current === c ? a : b;
      }
      function Aa(a) {
        a = za(a);
        return null !== a ? Ba(a) : null;
      }
      function Ba(a) {
        if (5 === a.tag || 6 === a.tag) return a;
        for (a = a.child; null !== a; ) {
          var b = Ba(a);
          if (null !== b) return b;
          a = a.sibling;
        }
        return null;
      }
      function Ca(a) {
        if (5 === a.tag || 6 === a.tag) return a;
        for (a = a.child; null !== a; ) {
          if (4 !== a.tag) {
            var b = Ca(a);
            if (null !== b) return b;
          }
          a = a.sibling;
        }
        return null;
      }
      var Da = Array.isArray, Ea = $$$hostConfig.getPublicInstance, Fa = $$$hostConfig.getRootHostContext, Ga = $$$hostConfig.getChildHostContext, Ha = $$$hostConfig.prepareForCommit, Ia = $$$hostConfig.resetAfterCommit, Ja = $$$hostConfig.createInstance, Ka = $$$hostConfig.appendInitialChild, La = $$$hostConfig.finalizeInitialChildren, Ma = $$$hostConfig.prepareUpdate, Na = $$$hostConfig.shouldSetTextContent, Oa = $$$hostConfig.createTextInstance, Pa = $$$hostConfig.scheduleTimeout, Qa = $$$hostConfig.cancelTimeout, Ra = $$$hostConfig.noTimeout, Sa = $$$hostConfig.isPrimaryRenderer, Ta = $$$hostConfig.supportsMutation, Ua = $$$hostConfig.supportsPersistence, Va = $$$hostConfig.supportsHydration, Wa = $$$hostConfig.getInstanceFromNode, Xa = $$$hostConfig.preparePortalMount, Ya = $$$hostConfig.getCurrentEventPriority, Za = $$$hostConfig.detachDeletedInstance, $a = $$$hostConfig.supportsMicrotasks, ab = $$$hostConfig.scheduleMicrotask, bb = $$$hostConfig.supportsTestSelectors, cb = $$$hostConfig.findFiberRoot, db = $$$hostConfig.getBoundingRect, eb = $$$hostConfig.getTextContent, fb = $$$hostConfig.isHiddenSubtree, gb = $$$hostConfig.matchAccessibilityRole, hb = $$$hostConfig.setFocusIfFocusable, ib = $$$hostConfig.setupIntersectionObserver, jb = $$$hostConfig.appendChild, kb = $$$hostConfig.appendChildToContainer, lb = $$$hostConfig.commitTextUpdate, mb = $$$hostConfig.commitMount, nb = $$$hostConfig.commitUpdate, ob = $$$hostConfig.insertBefore, pb = $$$hostConfig.insertInContainerBefore, qb = $$$hostConfig.removeChild, rb = $$$hostConfig.removeChildFromContainer, sb = $$$hostConfig.resetTextContent, tb = $$$hostConfig.hideInstance, ub = $$$hostConfig.hideTextInstance, vb = $$$hostConfig.unhideInstance, wb = $$$hostConfig.unhideTextInstance, xb = $$$hostConfig.clearContainer, yb = $$$hostConfig.cloneInstance, zb = $$$hostConfig.createContainerChildSet, Ab = $$$hostConfig.appendChildToContainerChildSet, Bb = $$$hostConfig.finalizeContainerChildren, Cb = $$$hostConfig.replaceContainerChildren, Eb = $$$hostConfig.cloneHiddenInstance, Fb = $$$hostConfig.cloneHiddenTextInstance, Gb = $$$hostConfig.canHydrateInstance, Hb = $$$hostConfig.canHydrateTextInstance, Ib = $$$hostConfig.canHydrateSuspenseInstance, Jb = $$$hostConfig.isSuspenseInstancePending, Kb = $$$hostConfig.isSuspenseInstanceFallback, Lb = $$$hostConfig.getSuspenseInstanceFallbackErrorDetails, Mb = $$$hostConfig.registerSuspenseInstanceRetry, Nb = $$$hostConfig.getNextHydratableSibling, Ob = $$$hostConfig.getFirstHydratableChild, Pb = $$$hostConfig.getFirstHydratableChildWithinContainer, Qb = $$$hostConfig.getFirstHydratableChildWithinSuspenseInstance, Rb = $$$hostConfig.hydrateInstance, Sb = $$$hostConfig.hydrateTextInstance, Tb = $$$hostConfig.hydrateSuspenseInstance, Ub = $$$hostConfig.getNextHydratableInstanceAfterSuspenseInstance, Vb = $$$hostConfig.commitHydratedContainer, Wb = $$$hostConfig.commitHydratedSuspenseInstance, Xb = $$$hostConfig.clearSuspenseBoundary, Yb = $$$hostConfig.clearSuspenseBoundaryFromContainer, Zb = $$$hostConfig.shouldDeleteUnhydratedTailInstances, $b = $$$hostConfig.didNotMatchHydratedContainerTextInstance, ac = $$$hostConfig.didNotMatchHydratedTextInstance, bc;
      function cc(a) {
        if (void 0 === bc) try {
          throw Error();
        } catch (c) {
          var b = c.stack.trim().match(/\n( *(at )?)/);
          bc = b && b[1] || "";
        }
        return "\n" + bc + a;
      }
      var dc = false;
      function ec(a, b) {
        if (!a || dc) return "";
        dc = true;
        var c = Error.prepareStackTrace;
        Error.prepareStackTrace = void 0;
        try {
          if (b) if (b = function() {
            throw Error();
          }, Object.defineProperty(b.prototype, "props", { set: function() {
            throw Error();
          } }), "object" === typeof Reflect && Reflect.construct) {
            try {
              Reflect.construct(b, []);
            } catch (l) {
              var d = l;
            }
            Reflect.construct(a, [], b);
          } else {
            try {
              b.call();
            } catch (l) {
              d = l;
            }
            a.call(b.prototype);
          }
          else {
            try {
              throw Error();
            } catch (l) {
              d = l;
            }
            a();
          }
        } catch (l) {
          if (l && d && "string" === typeof l.stack) {
            for (var e = l.stack.split("\n"), f = d.stack.split("\n"), g = e.length - 1, h = f.length - 1; 1 <= g && 0 <= h && e[g] !== f[h]; ) h--;
            for (; 1 <= g && 0 <= h; g--, h--) if (e[g] !== f[h]) {
              if (1 !== g || 1 !== h) {
                do
                  if (g--, h--, 0 > h || e[g] !== f[h]) {
                    var k = "\n" + e[g].replace(" at new ", " at ");
                    a.displayName && k.includes("<anonymous>") && (k = k.replace("<anonymous>", a.displayName));
                    return k;
                  }
                while (1 <= g && 0 <= h);
              }
              break;
            }
          }
        } finally {
          dc = false, Error.prepareStackTrace = c;
        }
        return (a = a ? a.displayName || a.name : "") ? cc(a) : "";
      }
      var fc = Object.prototype.hasOwnProperty, gc = [], hc = -1;
      function ic(a) {
        return { current: a };
      }
      function q(a) {
        0 > hc || (a.current = gc[hc], gc[hc] = null, hc--);
      }
      function v(a, b) {
        hc++;
        gc[hc] = a.current;
        a.current = b;
      }
      var jc = {}, x = ic(jc), z = ic(false), kc = jc;
      function mc(a, b) {
        var c = a.type.contextTypes;
        if (!c) return jc;
        var d = a.stateNode;
        if (d && d.__reactInternalMemoizedUnmaskedChildContext === b) return d.__reactInternalMemoizedMaskedChildContext;
        var e = {}, f;
        for (f in c) e[f] = b[f];
        d && (a = a.stateNode, a.__reactInternalMemoizedUnmaskedChildContext = b, a.__reactInternalMemoizedMaskedChildContext = e);
        return e;
      }
      function A(a) {
        a = a.childContextTypes;
        return null !== a && void 0 !== a;
      }
      function nc() {
        q(z);
        q(x);
      }
      function oc(a, b, c) {
        if (x.current !== jc) throw Error(n(168));
        v(x, b);
        v(z, c);
      }
      function pc(a, b, c) {
        var d = a.stateNode;
        b = b.childContextTypes;
        if ("function" !== typeof d.getChildContext) return c;
        d = d.getChildContext();
        for (var e in d) if (!(e in b)) throw Error(n(108, va(a) || "Unknown", e));
        return ca({}, c, d);
      }
      function qc(a) {
        a = (a = a.stateNode) && a.__reactInternalMemoizedMergedChildContext || jc;
        kc = x.current;
        v(x, a);
        v(z, z.current);
        return true;
      }
      function rc(a, b, c) {
        var d = a.stateNode;
        if (!d) throw Error(n(169));
        c ? (a = pc(a, b, kc), d.__reactInternalMemoizedMergedChildContext = a, q(z), q(x), v(x, a)) : q(z);
        v(z, c);
      }
      var tc = Math.clz32 ? Math.clz32 : sc, uc = Math.log, vc = Math.LN2;
      function sc(a) {
        a >>>= 0;
        return 0 === a ? 32 : 31 - (uc(a) / vc | 0) | 0;
      }
      var wc = 64, xc = 4194304;
      function yc(a) {
        switch (a & -a) {
          case 1:
            return 1;
          case 2:
            return 2;
          case 4:
            return 4;
          case 8:
            return 8;
          case 16:
            return 16;
          case 32:
            return 32;
          case 64:
          case 128:
          case 256:
          case 512:
          case 1024:
          case 2048:
          case 4096:
          case 8192:
          case 16384:
          case 32768:
          case 65536:
          case 131072:
          case 262144:
          case 524288:
          case 1048576:
          case 2097152:
            return a & 4194240;
          case 4194304:
          case 8388608:
          case 16777216:
          case 33554432:
          case 67108864:
            return a & 130023424;
          case 134217728:
            return 134217728;
          case 268435456:
            return 268435456;
          case 536870912:
            return 536870912;
          case 1073741824:
            return 1073741824;
          default:
            return a;
        }
      }
      function zc(a, b) {
        var c = a.pendingLanes;
        if (0 === c) return 0;
        var d = 0, e = a.suspendedLanes, f = a.pingedLanes, g = c & 268435455;
        if (0 !== g) {
          var h = g & ~e;
          0 !== h ? d = yc(h) : (f &= g, 0 !== f && (d = yc(f)));
        } else g = c & ~e, 0 !== g ? d = yc(g) : 0 !== f && (d = yc(f));
        if (0 === d) return 0;
        if (0 !== b && b !== d && 0 === (b & e) && (e = d & -d, f = b & -b, e >= f || 16 === e && 0 !== (f & 4194240))) return b;
        0 !== (d & 4) && (d |= c & 16);
        b = a.entangledLanes;
        if (0 !== b) for (a = a.entanglements, b &= d; 0 < b; ) c = 31 - tc(b), e = 1 << c, d |= a[c], b &= ~e;
        return d;
      }
      function Ac(a, b) {
        switch (a) {
          case 1:
          case 2:
          case 4:
            return b + 250;
          case 8:
          case 16:
          case 32:
          case 64:
          case 128:
          case 256:
          case 512:
          case 1024:
          case 2048:
          case 4096:
          case 8192:
          case 16384:
          case 32768:
          case 65536:
          case 131072:
          case 262144:
          case 524288:
          case 1048576:
          case 2097152:
            return b + 5e3;
          case 4194304:
          case 8388608:
          case 16777216:
          case 33554432:
          case 67108864:
            return -1;
          case 134217728:
          case 268435456:
          case 536870912:
          case 1073741824:
            return -1;
          default:
            return -1;
        }
      }
      function Bc(a, b) {
        for (var c = a.suspendedLanes, d = a.pingedLanes, e = a.expirationTimes, f = a.pendingLanes; 0 < f; ) {
          var g = 31 - tc(f), h = 1 << g, k = e[g];
          if (-1 === k) {
            if (0 === (h & c) || 0 !== (h & d)) e[g] = Ac(h, b);
          } else k <= b && (a.expiredLanes |= h);
          f &= ~h;
        }
      }
      function Cc(a) {
        a = a.pendingLanes & -1073741825;
        return 0 !== a ? a : a & 1073741824 ? 1073741824 : 0;
      }
      function Dc() {
        var a = wc;
        wc <<= 1;
        0 === (wc & 4194240) && (wc = 64);
        return a;
      }
      function Ec(a) {
        for (var b = [], c = 0; 31 > c; c++) b.push(a);
        return b;
      }
      function Fc(a, b, c) {
        a.pendingLanes |= b;
        536870912 !== b && (a.suspendedLanes = 0, a.pingedLanes = 0);
        a = a.eventTimes;
        b = 31 - tc(b);
        a[b] = c;
      }
      function Gc(a, b) {
        var c = a.pendingLanes & ~b;
        a.pendingLanes = b;
        a.suspendedLanes = 0;
        a.pingedLanes = 0;
        a.expiredLanes &= b;
        a.mutableReadLanes &= b;
        a.entangledLanes &= b;
        b = a.entanglements;
        var d = a.eventTimes;
        for (a = a.expirationTimes; 0 < c; ) {
          var e = 31 - tc(c), f = 1 << e;
          b[e] = 0;
          d[e] = -1;
          a[e] = -1;
          c &= ~f;
        }
      }
      function Hc(a, b) {
        var c = a.entangledLanes |= b;
        for (a = a.entanglements; c; ) {
          var d = 31 - tc(c), e = 1 << d;
          e & b | a[d] & b && (a[d] |= b);
          c &= ~e;
        }
      }
      var C = 0;
      function Ic(a) {
        a &= -a;
        return 1 < a ? 4 < a ? 0 !== (a & 268435455) ? 16 : 536870912 : 4 : 1;
      }
      var Jc = ba.unstable_scheduleCallback, Kc = ba.unstable_cancelCallback, Lc = ba.unstable_shouldYield, Mc = ba.unstable_requestPaint, D = ba.unstable_now, Nc = ba.unstable_ImmediatePriority, Oc = ba.unstable_UserBlockingPriority, Pc = ba.unstable_NormalPriority, Qc = ba.unstable_IdlePriority, Rc = null, Sc = null;
      function Tc(a) {
        if (Sc && "function" === typeof Sc.onCommitFiberRoot) try {
          Sc.onCommitFiberRoot(Rc, a, void 0, 128 === (a.current.flags & 128));
        } catch (b) {
        }
      }
      function Uc(a, b) {
        return a === b && (0 !== a || 1 / a === 1 / b) || a !== a && b !== b;
      }
      var Vc = "function" === typeof Object.is ? Object.is : Uc, Wc = null, Xc = false, Yc = false;
      function Zc(a) {
        null === Wc ? Wc = [a] : Wc.push(a);
      }
      function $c(a) {
        Xc = true;
        Zc(a);
      }
      function ad() {
        if (!Yc && null !== Wc) {
          Yc = true;
          var a = 0, b = C;
          try {
            var c = Wc;
            for (C = 1; a < c.length; a++) {
              var d = c[a];
              do
                d = d(true);
              while (null !== d);
            }
            Wc = null;
            Xc = false;
          } catch (e) {
            throw null !== Wc && (Wc = Wc.slice(a + 1)), Jc(Nc, ad), e;
          } finally {
            C = b, Yc = false;
          }
        }
        return null;
      }
      var bd = [], cd = 0, dd = null, ed = 0, fd = [], gd = 0, hd = null, id = 1, jd = "";
      function kd(a, b) {
        bd[cd++] = ed;
        bd[cd++] = dd;
        dd = a;
        ed = b;
      }
      function ld(a, b, c) {
        fd[gd++] = id;
        fd[gd++] = jd;
        fd[gd++] = hd;
        hd = a;
        var d = id;
        a = jd;
        var e = 32 - tc(d) - 1;
        d &= ~(1 << e);
        c += 1;
        var f = 32 - tc(b) + e;
        if (30 < f) {
          var g = e - e % 5;
          f = (d & (1 << g) - 1).toString(32);
          d >>= g;
          e -= g;
          id = 1 << 32 - tc(b) + e | c << e | d;
          jd = f + a;
        } else id = 1 << f | c << e | d, jd = a;
      }
      function md(a) {
        null !== a.return && (kd(a, 1), ld(a, 1, 0));
      }
      function nd(a) {
        for (; a === dd; ) dd = bd[--cd], bd[cd] = null, ed = bd[--cd], bd[cd] = null;
        for (; a === hd; ) hd = fd[--gd], fd[gd] = null, jd = fd[--gd], fd[gd] = null, id = fd[--gd], fd[gd] = null;
      }
      var od = null, pd = null, F = false, qd = false, rd = null;
      function sd(a, b) {
        var c = td(5, null, null, 0);
        c.elementType = "DELETED";
        c.stateNode = b;
        c.return = a;
        b = a.deletions;
        null === b ? (a.deletions = [c], a.flags |= 16) : b.push(c);
      }
      function ud(a, b) {
        switch (a.tag) {
          case 5:
            return b = Gb(b, a.type, a.pendingProps), null !== b ? (a.stateNode = b, od = a, pd = Ob(b), true) : false;
          case 6:
            return b = Hb(b, a.pendingProps), null !== b ? (a.stateNode = b, od = a, pd = null, true) : false;
          case 13:
            b = Ib(b);
            if (null !== b) {
              var c = null !== hd ? { id, overflow: jd } : null;
              a.memoizedState = { dehydrated: b, treeContext: c, retryLane: 1073741824 };
              c = td(18, null, null, 0);
              c.stateNode = b;
              c.return = a;
              a.child = c;
              od = a;
              pd = null;
              return true;
            }
            return false;
          default:
            return false;
        }
      }
      function vd(a) {
        return 0 !== (a.mode & 1) && 0 === (a.flags & 128);
      }
      function wd(a) {
        if (F) {
          var b = pd;
          if (b) {
            var c = b;
            if (!ud(a, b)) {
              if (vd(a)) throw Error(n(418));
              b = Nb(c);
              var d = od;
              b && ud(a, b) ? sd(d, c) : (a.flags = a.flags & -4097 | 2, F = false, od = a);
            }
          } else {
            if (vd(a)) throw Error(n(418));
            a.flags = a.flags & -4097 | 2;
            F = false;
            od = a;
          }
        }
      }
      function xd(a) {
        for (a = a.return; null !== a && 5 !== a.tag && 3 !== a.tag && 13 !== a.tag; ) a = a.return;
        od = a;
      }
      function yd(a) {
        if (!Va || a !== od) return false;
        if (!F) return xd(a), F = true, false;
        if (3 !== a.tag && (5 !== a.tag || Zb(a.type) && !Na(a.type, a.memoizedProps))) {
          var b = pd;
          if (b) {
            if (vd(a)) throw zd(), Error(n(418));
            for (; b; ) sd(a, b), b = Nb(b);
          }
        }
        xd(a);
        if (13 === a.tag) {
          if (!Va) throw Error(n(316));
          a = a.memoizedState;
          a = null !== a ? a.dehydrated : null;
          if (!a) throw Error(n(317));
          pd = Ub(a);
        } else pd = od ? Nb(a.stateNode) : null;
        return true;
      }
      function zd() {
        for (var a = pd; a; ) a = Nb(a);
      }
      function Ad() {
        Va && (pd = od = null, qd = F = false);
      }
      function Bd(a) {
        null === rd ? rd = [a] : rd.push(a);
      }
      var Cd = da.ReactCurrentBatchConfig;
      function Dd(a, b) {
        if (Vc(a, b)) return true;
        if ("object" !== typeof a || null === a || "object" !== typeof b || null === b) return false;
        var c = Object.keys(a), d = Object.keys(b);
        if (c.length !== d.length) return false;
        for (d = 0; d < c.length; d++) {
          var e = c[d];
          if (!fc.call(b, e) || !Vc(a[e], b[e])) return false;
        }
        return true;
      }
      function Ed(a) {
        switch (a.tag) {
          case 5:
            return cc(a.type);
          case 16:
            return cc("Lazy");
          case 13:
            return cc("Suspense");
          case 19:
            return cc("SuspenseList");
          case 0:
          case 2:
          case 15:
            return a = ec(a.type, false), a;
          case 11:
            return a = ec(a.type.render, false), a;
          case 1:
            return a = ec(a.type, true), a;
          default:
            return "";
        }
      }
      function Fd(a, b, c) {
        a = c.ref;
        if (null !== a && "function" !== typeof a && "object" !== typeof a) {
          if (c._owner) {
            c = c._owner;
            if (c) {
              if (1 !== c.tag) throw Error(n(309));
              var d = c.stateNode;
            }
            if (!d) throw Error(n(147, a));
            var e = d, f = "" + a;
            if (null !== b && null !== b.ref && "function" === typeof b.ref && b.ref._stringRef === f) return b.ref;
            b = function(a2) {
              var b2 = e.refs;
              null === a2 ? delete b2[f] : b2[f] = a2;
            };
            b._stringRef = f;
            return b;
          }
          if ("string" !== typeof a) throw Error(n(284));
          if (!c._owner) throw Error(n(290, a));
        }
        return a;
      }
      function Gd(a, b) {
        a = Object.prototype.toString.call(b);
        throw Error(n(31, "[object Object]" === a ? "object with keys {" + Object.keys(b).join(", ") + "}" : a));
      }
      function Hd(a) {
        var b = a._init;
        return b(a._payload);
      }
      function Id(a) {
        function b(b2, c2) {
          if (a) {
            var d2 = b2.deletions;
            null === d2 ? (b2.deletions = [c2], b2.flags |= 16) : d2.push(c2);
          }
        }
        function c(c2, d2) {
          if (!a) return null;
          for (; null !== d2; ) b(c2, d2), d2 = d2.sibling;
          return null;
        }
        function d(a2, b2) {
          for (a2 = /* @__PURE__ */ new Map(); null !== b2; ) null !== b2.key ? a2.set(b2.key, b2) : a2.set(b2.index, b2), b2 = b2.sibling;
          return a2;
        }
        function e(a2, b2) {
          a2 = Jd(a2, b2);
          a2.index = 0;
          a2.sibling = null;
          return a2;
        }
        function f(b2, c2, d2) {
          b2.index = d2;
          if (!a) return b2.flags |= 1048576, c2;
          d2 = b2.alternate;
          if (null !== d2) return d2 = d2.index, d2 < c2 ? (b2.flags |= 2, c2) : d2;
          b2.flags |= 2;
          return c2;
        }
        function g(b2) {
          a && null === b2.alternate && (b2.flags |= 2);
          return b2;
        }
        function h(a2, b2, c2, d2) {
          if (null === b2 || 6 !== b2.tag) return b2 = Kd(c2, a2.mode, d2), b2.return = a2, b2;
          b2 = e(b2, c2);
          b2.return = a2;
          return b2;
        }
        function k(a2, b2, c2, d2) {
          var f2 = c2.type;
          if (f2 === ha) return m(a2, b2, c2.props.children, d2, c2.key);
          if (null !== b2 && (b2.elementType === f2 || "object" === typeof f2 && null !== f2 && f2.$$typeof === qa && Hd(f2) === b2.type)) return d2 = e(b2, c2.props), d2.ref = Fd(a2, b2, c2), d2.return = a2, d2;
          d2 = Ld(c2.type, c2.key, c2.props, null, a2.mode, d2);
          d2.ref = Fd(a2, b2, c2);
          d2.return = a2;
          return d2;
        }
        function l(a2, b2, c2, d2) {
          if (null === b2 || 4 !== b2.tag || b2.stateNode.containerInfo !== c2.containerInfo || b2.stateNode.implementation !== c2.implementation) return b2 = Md(c2, a2.mode, d2), b2.return = a2, b2;
          b2 = e(b2, c2.children || []);
          b2.return = a2;
          return b2;
        }
        function m(a2, b2, c2, d2, f2) {
          if (null === b2 || 7 !== b2.tag) return b2 = Nd(c2, a2.mode, d2, f2), b2.return = a2, b2;
          b2 = e(b2, c2);
          b2.return = a2;
          return b2;
        }
        function r(a2, b2, c2) {
          if ("string" === typeof b2 && "" !== b2 || "number" === typeof b2) return b2 = Kd("" + b2, a2.mode, c2), b2.return = a2, b2;
          if ("object" === typeof b2 && null !== b2) {
            switch (b2.$$typeof) {
              case ea:
                return c2 = Ld(b2.type, b2.key, b2.props, null, a2.mode, c2), c2.ref = Fd(a2, null, b2), c2.return = a2, c2;
              case fa:
                return b2 = Md(b2, a2.mode, c2), b2.return = a2, b2;
              case qa:
                var d2 = b2._init;
                return r(a2, d2(b2._payload), c2);
            }
            if (Da(b2) || ta(b2)) return b2 = Nd(b2, a2.mode, c2, null), b2.return = a2, b2;
            Gd(a2, b2);
          }
          return null;
        }
        function p(a2, b2, c2, d2) {
          var e2 = null !== b2 ? b2.key : null;
          if ("string" === typeof c2 && "" !== c2 || "number" === typeof c2) return null !== e2 ? null : h(a2, b2, "" + c2, d2);
          if ("object" === typeof c2 && null !== c2) {
            switch (c2.$$typeof) {
              case ea:
                return c2.key === e2 ? k(a2, b2, c2, d2) : null;
              case fa:
                return c2.key === e2 ? l(a2, b2, c2, d2) : null;
              case qa:
                return e2 = c2._init, p(
                  a2,
                  b2,
                  e2(c2._payload),
                  d2
                );
            }
            if (Da(c2) || ta(c2)) return null !== e2 ? null : m(a2, b2, c2, d2, null);
            Gd(a2, c2);
          }
          return null;
        }
        function B(a2, b2, c2, d2, e2) {
          if ("string" === typeof d2 && "" !== d2 || "number" === typeof d2) return a2 = a2.get(c2) || null, h(b2, a2, "" + d2, e2);
          if ("object" === typeof d2 && null !== d2) {
            switch (d2.$$typeof) {
              case ea:
                return a2 = a2.get(null === d2.key ? c2 : d2.key) || null, k(b2, a2, d2, e2);
              case fa:
                return a2 = a2.get(null === d2.key ? c2 : d2.key) || null, l(b2, a2, d2, e2);
              case qa:
                var f2 = d2._init;
                return B(a2, b2, c2, f2(d2._payload), e2);
            }
            if (Da(d2) || ta(d2)) return a2 = a2.get(c2) || null, m(b2, a2, d2, e2, null);
            Gd(b2, d2);
          }
          return null;
        }
        function w(e2, g2, h2, k2) {
          for (var l2 = null, m2 = null, u = g2, t = g2 = 0, E = null; null !== u && t < h2.length; t++) {
            u.index > t ? (E = u, u = null) : E = u.sibling;
            var y = p(e2, u, h2[t], k2);
            if (null === y) {
              null === u && (u = E);
              break;
            }
            a && u && null === y.alternate && b(e2, u);
            g2 = f(y, g2, t);
            null === m2 ? l2 = y : m2.sibling = y;
            m2 = y;
            u = E;
          }
          if (t === h2.length) return c(e2, u), F && kd(e2, t), l2;
          if (null === u) {
            for (; t < h2.length; t++) u = r(e2, h2[t], k2), null !== u && (g2 = f(u, g2, t), null === m2 ? l2 = u : m2.sibling = u, m2 = u);
            F && kd(e2, t);
            return l2;
          }
          for (u = d(e2, u); t < h2.length; t++) E = B(u, e2, t, h2[t], k2), null !== E && (a && null !== E.alternate && u.delete(null === E.key ? t : E.key), g2 = f(E, g2, t), null === m2 ? l2 = E : m2.sibling = E, m2 = E);
          a && u.forEach(function(a2) {
            return b(e2, a2);
          });
          F && kd(e2, t);
          return l2;
        }
        function Y(e2, g2, h2, k2) {
          var l2 = ta(h2);
          if ("function" !== typeof l2) throw Error(n(150));
          h2 = l2.call(h2);
          if (null == h2) throw Error(n(151));
          for (var u = l2 = null, m2 = g2, t = g2 = 0, E = null, y = h2.next(); null !== m2 && !y.done; t++, y = h2.next()) {
            m2.index > t ? (E = m2, m2 = null) : E = m2.sibling;
            var w2 = p(e2, m2, y.value, k2);
            if (null === w2) {
              null === m2 && (m2 = E);
              break;
            }
            a && m2 && null === w2.alternate && b(e2, m2);
            g2 = f(w2, g2, t);
            null === u ? l2 = w2 : u.sibling = w2;
            u = w2;
            m2 = E;
          }
          if (y.done) return c(
            e2,
            m2
          ), F && kd(e2, t), l2;
          if (null === m2) {
            for (; !y.done; t++, y = h2.next()) y = r(e2, y.value, k2), null !== y && (g2 = f(y, g2, t), null === u ? l2 = y : u.sibling = y, u = y);
            F && kd(e2, t);
            return l2;
          }
          for (m2 = d(e2, m2); !y.done; t++, y = h2.next()) y = B(m2, e2, t, y.value, k2), null !== y && (a && null !== y.alternate && m2.delete(null === y.key ? t : y.key), g2 = f(y, g2, t), null === u ? l2 = y : u.sibling = y, u = y);
          a && m2.forEach(function(a2) {
            return b(e2, a2);
          });
          F && kd(e2, t);
          return l2;
        }
        function ya(a2, d2, f2, h2) {
          "object" === typeof f2 && null !== f2 && f2.type === ha && null === f2.key && (f2 = f2.props.children);
          if ("object" === typeof f2 && null !== f2) {
            switch (f2.$$typeof) {
              case ea:
                a: {
                  for (var k2 = f2.key, l2 = d2; null !== l2; ) {
                    if (l2.key === k2) {
                      k2 = f2.type;
                      if (k2 === ha) {
                        if (7 === l2.tag) {
                          c(a2, l2.sibling);
                          d2 = e(l2, f2.props.children);
                          d2.return = a2;
                          a2 = d2;
                          break a;
                        }
                      } else if (l2.elementType === k2 || "object" === typeof k2 && null !== k2 && k2.$$typeof === qa && Hd(k2) === l2.type) {
                        c(a2, l2.sibling);
                        d2 = e(l2, f2.props);
                        d2.ref = Fd(a2, l2, f2);
                        d2.return = a2;
                        a2 = d2;
                        break a;
                      }
                      c(a2, l2);
                      break;
                    } else b(a2, l2);
                    l2 = l2.sibling;
                  }
                  f2.type === ha ? (d2 = Nd(f2.props.children, a2.mode, h2, f2.key), d2.return = a2, a2 = d2) : (h2 = Ld(f2.type, f2.key, f2.props, null, a2.mode, h2), h2.ref = Fd(a2, d2, f2), h2.return = a2, a2 = h2);
                }
                return g(a2);
              case fa:
                a: {
                  for (l2 = f2.key; null !== d2; ) {
                    if (d2.key === l2) if (4 === d2.tag && d2.stateNode.containerInfo === f2.containerInfo && d2.stateNode.implementation === f2.implementation) {
                      c(a2, d2.sibling);
                      d2 = e(d2, f2.children || []);
                      d2.return = a2;
                      a2 = d2;
                      break a;
                    } else {
                      c(a2, d2);
                      break;
                    }
                    else b(a2, d2);
                    d2 = d2.sibling;
                  }
                  d2 = Md(f2, a2.mode, h2);
                  d2.return = a2;
                  a2 = d2;
                }
                return g(a2);
              case qa:
                return l2 = f2._init, ya(a2, d2, l2(f2._payload), h2);
            }
            if (Da(f2)) return w(a2, d2, f2, h2);
            if (ta(f2)) return Y(a2, d2, f2, h2);
            Gd(a2, f2);
          }
          return "string" === typeof f2 && "" !== f2 || "number" === typeof f2 ? (f2 = "" + f2, null !== d2 && 6 === d2.tag ? (c(a2, d2.sibling), d2 = e(d2, f2), d2.return = a2, a2 = d2) : (c(a2, d2), d2 = Kd(f2, a2.mode, h2), d2.return = a2, a2 = d2), g(a2)) : c(a2, d2);
        }
        return ya;
      }
      var Od = Id(true), Pd = Id(false), Qd = ic(null), Rd = null, Sd = null, Td = null;
      function Ud() {
        Td = Sd = Rd = null;
      }
      function Vd(a, b, c) {
        Sa ? (v(Qd, b._currentValue), b._currentValue = c) : (v(Qd, b._currentValue2), b._currentValue2 = c);
      }
      function Wd(a) {
        var b = Qd.current;
        q(Qd);
        Sa ? a._currentValue = b : a._currentValue2 = b;
      }
      function Xd(a, b, c) {
        for (; null !== a; ) {
          var d = a.alternate;
          (a.childLanes & b) !== b ? (a.childLanes |= b, null !== d && (d.childLanes |= b)) : null !== d && (d.childLanes & b) !== b && (d.childLanes |= b);
          if (a === c) break;
          a = a.return;
        }
      }
      function Yd(a, b) {
        Rd = a;
        Td = Sd = null;
        a = a.dependencies;
        null !== a && null !== a.firstContext && (0 !== (a.lanes & b) && (G = true), a.firstContext = null);
      }
      function Zd(a) {
        var b = Sa ? a._currentValue : a._currentValue2;
        if (Td !== a) if (a = { context: a, memoizedValue: b, next: null }, null === Sd) {
          if (null === Rd) throw Error(n(308));
          Sd = a;
          Rd.dependencies = { lanes: 0, firstContext: a };
        } else Sd = Sd.next = a;
        return b;
      }
      var $d = null;
      function ae(a) {
        null === $d ? $d = [a] : $d.push(a);
      }
      function be(a, b, c, d) {
        var e = b.interleaved;
        null === e ? (c.next = c, ae(b)) : (c.next = e.next, e.next = c);
        b.interleaved = c;
        return ce(a, d);
      }
      function ce(a, b) {
        a.lanes |= b;
        var c = a.alternate;
        null !== c && (c.lanes |= b);
        c = a;
        for (a = a.return; null !== a; ) a.childLanes |= b, c = a.alternate, null !== c && (c.childLanes |= b), c = a, a = a.return;
        return 3 === c.tag ? c.stateNode : null;
      }
      var de = false;
      function ee(a) {
        a.updateQueue = { baseState: a.memoizedState, firstBaseUpdate: null, lastBaseUpdate: null, shared: { pending: null, interleaved: null, lanes: 0 }, effects: null };
      }
      function fe(a, b) {
        a = a.updateQueue;
        b.updateQueue === a && (b.updateQueue = { baseState: a.baseState, firstBaseUpdate: a.firstBaseUpdate, lastBaseUpdate: a.lastBaseUpdate, shared: a.shared, effects: a.effects });
      }
      function ge(a, b) {
        return { eventTime: a, lane: b, tag: 0, payload: null, callback: null, next: null };
      }
      function he(a, b, c) {
        var d = a.updateQueue;
        if (null === d) return null;
        d = d.shared;
        if (0 !== (H & 2)) {
          var e = d.pending;
          null === e ? b.next = b : (b.next = e.next, e.next = b);
          d.pending = b;
          return ce(a, c);
        }
        e = d.interleaved;
        null === e ? (b.next = b, ae(d)) : (b.next = e.next, e.next = b);
        d.interleaved = b;
        return ce(a, c);
      }
      function ie(a, b, c) {
        b = b.updateQueue;
        if (null !== b && (b = b.shared, 0 !== (c & 4194240))) {
          var d = b.lanes;
          d &= a.pendingLanes;
          c |= d;
          b.lanes = c;
          Hc(a, c);
        }
      }
      function je(a, b) {
        var c = a.updateQueue, d = a.alternate;
        if (null !== d && (d = d.updateQueue, c === d)) {
          var e = null, f = null;
          c = c.firstBaseUpdate;
          if (null !== c) {
            do {
              var g = { eventTime: c.eventTime, lane: c.lane, tag: c.tag, payload: c.payload, callback: c.callback, next: null };
              null === f ? e = f = g : f = f.next = g;
              c = c.next;
            } while (null !== c);
            null === f ? e = f = b : f = f.next = b;
          } else e = f = b;
          c = { baseState: d.baseState, firstBaseUpdate: e, lastBaseUpdate: f, shared: d.shared, effects: d.effects };
          a.updateQueue = c;
          return;
        }
        a = c.lastBaseUpdate;
        null === a ? c.firstBaseUpdate = b : a.next = b;
        c.lastBaseUpdate = b;
      }
      function ke(a, b, c, d) {
        var e = a.updateQueue;
        de = false;
        var f = e.firstBaseUpdate, g = e.lastBaseUpdate, h = e.shared.pending;
        if (null !== h) {
          e.shared.pending = null;
          var k = h, l = k.next;
          k.next = null;
          null === g ? f = l : g.next = l;
          g = k;
          var m = a.alternate;
          null !== m && (m = m.updateQueue, h = m.lastBaseUpdate, h !== g && (null === h ? m.firstBaseUpdate = l : h.next = l, m.lastBaseUpdate = k));
        }
        if (null !== f) {
          var r = e.baseState;
          g = 0;
          m = l = k = null;
          h = f;
          do {
            var p = h.lane, B = h.eventTime;
            if ((d & p) === p) {
              null !== m && (m = m.next = {
                eventTime: B,
                lane: 0,
                tag: h.tag,
                payload: h.payload,
                callback: h.callback,
                next: null
              });
              a: {
                var w = a, Y = h;
                p = b;
                B = c;
                switch (Y.tag) {
                  case 1:
                    w = Y.payload;
                    if ("function" === typeof w) {
                      r = w.call(B, r, p);
                      break a;
                    }
                    r = w;
                    break a;
                  case 3:
                    w.flags = w.flags & -65537 | 128;
                  case 0:
                    w = Y.payload;
                    p = "function" === typeof w ? w.call(B, r, p) : w;
                    if (null === p || void 0 === p) break a;
                    r = ca({}, r, p);
                    break a;
                  case 2:
                    de = true;
                }
              }
              null !== h.callback && 0 !== h.lane && (a.flags |= 64, p = e.effects, null === p ? e.effects = [h] : p.push(h));
            } else B = { eventTime: B, lane: p, tag: h.tag, payload: h.payload, callback: h.callback, next: null }, null === m ? (l = m = B, k = r) : m = m.next = B, g |= p;
            h = h.next;
            if (null === h) if (h = e.shared.pending, null === h) break;
            else p = h, h = p.next, p.next = null, e.lastBaseUpdate = p, e.shared.pending = null;
          } while (1);
          null === m && (k = r);
          e.baseState = k;
          e.firstBaseUpdate = l;
          e.lastBaseUpdate = m;
          b = e.shared.interleaved;
          if (null !== b) {
            e = b;
            do
              g |= e.lane, e = e.next;
            while (e !== b);
          } else null === f && (e.shared.lanes = 0);
          le |= g;
          a.lanes = g;
          a.memoizedState = r;
        }
      }
      function me(a, b, c) {
        a = b.effects;
        b.effects = null;
        if (null !== a) for (b = 0; b < a.length; b++) {
          var d = a[b], e = d.callback;
          if (null !== e) {
            d.callback = null;
            d = c;
            if ("function" !== typeof e) throw Error(n(191, e));
            e.call(d);
          }
        }
      }
      var ne = {}, oe = ic(ne), pe = ic(ne), qe = ic(ne);
      function re(a) {
        if (a === ne) throw Error(n(174));
        return a;
      }
      function se(a, b) {
        v(qe, b);
        v(pe, a);
        v(oe, ne);
        a = Fa(b);
        q(oe);
        v(oe, a);
      }
      function te() {
        q(oe);
        q(pe);
        q(qe);
      }
      function ue(a) {
        var b = re(qe.current), c = re(oe.current);
        b = Ga(c, a.type, b);
        c !== b && (v(pe, a), v(oe, b));
      }
      function ve(a) {
        pe.current === a && (q(oe), q(pe));
      }
      var I = ic(0);
      function we(a) {
        for (var b = a; null !== b; ) {
          if (13 === b.tag) {
            var c = b.memoizedState;
            if (null !== c && (c = c.dehydrated, null === c || Jb(c) || Kb(c))) return b;
          } else if (19 === b.tag && void 0 !== b.memoizedProps.revealOrder) {
            if (0 !== (b.flags & 128)) return b;
          } else if (null !== b.child) {
            b.child.return = b;
            b = b.child;
            continue;
          }
          if (b === a) break;
          for (; null === b.sibling; ) {
            if (null === b.return || b.return === a) return null;
            b = b.return;
          }
          b.sibling.return = b.return;
          b = b.sibling;
        }
        return null;
      }
      var xe = [];
      function ye() {
        for (var a = 0; a < xe.length; a++) {
          var b = xe[a];
          Sa ? b._workInProgressVersionPrimary = null : b._workInProgressVersionSecondary = null;
        }
        xe.length = 0;
      }
      var ze = da.ReactCurrentDispatcher, Ae = da.ReactCurrentBatchConfig, Be = 0, J = null, K = null, L = null, Ce = false, De = false, Ee = 0, Fe = 0;
      function M() {
        throw Error(n(321));
      }
      function Ge(a, b) {
        if (null === b) return false;
        for (var c = 0; c < b.length && c < a.length; c++) if (!Vc(a[c], b[c])) return false;
        return true;
      }
      function He(a, b, c, d, e, f) {
        Be = f;
        J = b;
        b.memoizedState = null;
        b.updateQueue = null;
        b.lanes = 0;
        ze.current = null === a || null === a.memoizedState ? Ie : Je;
        a = c(d, e);
        if (De) {
          f = 0;
          do {
            De = false;
            Ee = 0;
            if (25 <= f) throw Error(n(301));
            f += 1;
            L = K = null;
            b.updateQueue = null;
            ze.current = Ke;
            a = c(d, e);
          } while (De);
        }
        ze.current = Le;
        b = null !== K && null !== K.next;
        Be = 0;
        L = K = J = null;
        Ce = false;
        if (b) throw Error(n(300));
        return a;
      }
      function Me() {
        var a = 0 !== Ee;
        Ee = 0;
        return a;
      }
      function Ne() {
        var a = { memoizedState: null, baseState: null, baseQueue: null, queue: null, next: null };
        null === L ? J.memoizedState = L = a : L = L.next = a;
        return L;
      }
      function Oe() {
        if (null === K) {
          var a = J.alternate;
          a = null !== a ? a.memoizedState : null;
        } else a = K.next;
        var b = null === L ? J.memoizedState : L.next;
        if (null !== b) L = b, K = a;
        else {
          if (null === a) throw Error(n(310));
          K = a;
          a = { memoizedState: K.memoizedState, baseState: K.baseState, baseQueue: K.baseQueue, queue: K.queue, next: null };
          null === L ? J.memoizedState = L = a : L = L.next = a;
        }
        return L;
      }
      function Pe(a, b) {
        return "function" === typeof b ? b(a) : b;
      }
      function Qe(a) {
        var b = Oe(), c = b.queue;
        if (null === c) throw Error(n(311));
        c.lastRenderedReducer = a;
        var d = K, e = d.baseQueue, f = c.pending;
        if (null !== f) {
          if (null !== e) {
            var g = e.next;
            e.next = f.next;
            f.next = g;
          }
          d.baseQueue = e = f;
          c.pending = null;
        }
        if (null !== e) {
          f = e.next;
          d = d.baseState;
          var h = g = null, k = null, l = f;
          do {
            var m = l.lane;
            if ((Be & m) === m) null !== k && (k = k.next = { lane: 0, action: l.action, hasEagerState: l.hasEagerState, eagerState: l.eagerState, next: null }), d = l.hasEagerState ? l.eagerState : a(d, l.action);
            else {
              var r = {
                lane: m,
                action: l.action,
                hasEagerState: l.hasEagerState,
                eagerState: l.eagerState,
                next: null
              };
              null === k ? (h = k = r, g = d) : k = k.next = r;
              J.lanes |= m;
              le |= m;
            }
            l = l.next;
          } while (null !== l && l !== f);
          null === k ? g = d : k.next = h;
          Vc(d, b.memoizedState) || (G = true);
          b.memoizedState = d;
          b.baseState = g;
          b.baseQueue = k;
          c.lastRenderedState = d;
        }
        a = c.interleaved;
        if (null !== a) {
          e = a;
          do
            f = e.lane, J.lanes |= f, le |= f, e = e.next;
          while (e !== a);
        } else null === e && (c.lanes = 0);
        return [b.memoizedState, c.dispatch];
      }
      function Re(a) {
        var b = Oe(), c = b.queue;
        if (null === c) throw Error(n(311));
        c.lastRenderedReducer = a;
        var d = c.dispatch, e = c.pending, f = b.memoizedState;
        if (null !== e) {
          c.pending = null;
          var g = e = e.next;
          do
            f = a(f, g.action), g = g.next;
          while (g !== e);
          Vc(f, b.memoizedState) || (G = true);
          b.memoizedState = f;
          null === b.baseQueue && (b.baseState = f);
          c.lastRenderedState = f;
        }
        return [f, d];
      }
      function Se() {
      }
      function Te(a, b) {
        var c = J, d = Oe(), e = b(), f = !Vc(d.memoizedState, e);
        f && (d.memoizedState = e, G = true);
        d = d.queue;
        Ue(Ve.bind(null, c, d, a), [a]);
        if (d.getSnapshot !== b || f || null !== L && L.memoizedState.tag & 1) {
          c.flags |= 2048;
          We(9, Xe.bind(null, c, d, e, b), void 0, null);
          if (null === N) throw Error(n(349));
          0 !== (Be & 30) || Ye(c, b, e);
        }
        return e;
      }
      function Ye(a, b, c) {
        a.flags |= 16384;
        a = { getSnapshot: b, value: c };
        b = J.updateQueue;
        null === b ? (b = { lastEffect: null, stores: null }, J.updateQueue = b, b.stores = [a]) : (c = b.stores, null === c ? b.stores = [a] : c.push(a));
      }
      function Xe(a, b, c, d) {
        b.value = c;
        b.getSnapshot = d;
        Ze(b) && $e(a);
      }
      function Ve(a, b, c) {
        return c(function() {
          Ze(b) && $e(a);
        });
      }
      function Ze(a) {
        var b = a.getSnapshot;
        a = a.value;
        try {
          var c = b();
          return !Vc(a, c);
        } catch (d) {
          return true;
        }
      }
      function $e(a) {
        var b = ce(a, 1);
        null !== b && af(b, a, 1, -1);
      }
      function bf(a) {
        var b = Ne();
        "function" === typeof a && (a = a());
        b.memoizedState = b.baseState = a;
        a = { pending: null, interleaved: null, lanes: 0, dispatch: null, lastRenderedReducer: Pe, lastRenderedState: a };
        b.queue = a;
        a = a.dispatch = cf.bind(null, J, a);
        return [b.memoizedState, a];
      }
      function We(a, b, c, d) {
        a = { tag: a, create: b, destroy: c, deps: d, next: null };
        b = J.updateQueue;
        null === b ? (b = { lastEffect: null, stores: null }, J.updateQueue = b, b.lastEffect = a.next = a) : (c = b.lastEffect, null === c ? b.lastEffect = a.next = a : (d = c.next, c.next = a, a.next = d, b.lastEffect = a));
        return a;
      }
      function df() {
        return Oe().memoizedState;
      }
      function ef(a, b, c, d) {
        var e = Ne();
        J.flags |= a;
        e.memoizedState = We(1 | b, c, void 0, void 0 === d ? null : d);
      }
      function ff(a, b, c, d) {
        var e = Oe();
        d = void 0 === d ? null : d;
        var f = void 0;
        if (null !== K) {
          var g = K.memoizedState;
          f = g.destroy;
          if (null !== d && Ge(d, g.deps)) {
            e.memoizedState = We(b, c, f, d);
            return;
          }
        }
        J.flags |= a;
        e.memoizedState = We(1 | b, c, f, d);
      }
      function gf(a, b) {
        return ef(8390656, 8, a, b);
      }
      function Ue(a, b) {
        return ff(2048, 8, a, b);
      }
      function hf(a, b) {
        return ff(4, 2, a, b);
      }
      function jf(a, b) {
        return ff(4, 4, a, b);
      }
      function kf(a, b) {
        if ("function" === typeof b) return a = a(), b(a), function() {
          b(null);
        };
        if (null !== b && void 0 !== b) return a = a(), b.current = a, function() {
          b.current = null;
        };
      }
      function lf(a, b, c) {
        c = null !== c && void 0 !== c ? c.concat([a]) : null;
        return ff(4, 4, kf.bind(null, b, a), c);
      }
      function mf() {
      }
      function nf(a, b) {
        var c = Oe();
        b = void 0 === b ? null : b;
        var d = c.memoizedState;
        if (null !== d && null !== b && Ge(b, d[1])) return d[0];
        c.memoizedState = [a, b];
        return a;
      }
      function of(a, b) {
        var c = Oe();
        b = void 0 === b ? null : b;
        var d = c.memoizedState;
        if (null !== d && null !== b && Ge(b, d[1])) return d[0];
        a = a();
        c.memoizedState = [a, b];
        return a;
      }
      function pf(a, b, c) {
        if (0 === (Be & 21)) return a.baseState && (a.baseState = false, G = true), a.memoizedState = c;
        Vc(c, b) || (c = Dc(), J.lanes |= c, le |= c, a.baseState = true);
        return b;
      }
      function qf(a, b) {
        var c = C;
        C = 0 !== c && 4 > c ? c : 4;
        a(true);
        var d = Ae.transition;
        Ae.transition = {};
        try {
          a(false), b();
        } finally {
          C = c, Ae.transition = d;
        }
      }
      function rf() {
        return Oe().memoizedState;
      }
      function sf(a, b, c) {
        var d = tf(a);
        c = { lane: d, action: c, hasEagerState: false, eagerState: null, next: null };
        if (uf(a)) vf(b, c);
        else if (c = be(a, b, c, d), null !== c) {
          var e = O();
          af(c, a, d, e);
          wf(c, b, d);
        }
      }
      function cf(a, b, c) {
        var d = tf(a), e = { lane: d, action: c, hasEagerState: false, eagerState: null, next: null };
        if (uf(a)) vf(b, e);
        else {
          var f = a.alternate;
          if (0 === a.lanes && (null === f || 0 === f.lanes) && (f = b.lastRenderedReducer, null !== f)) try {
            var g = b.lastRenderedState, h = f(g, c);
            e.hasEagerState = true;
            e.eagerState = h;
            if (Vc(h, g)) {
              var k = b.interleaved;
              null === k ? (e.next = e, ae(b)) : (e.next = k.next, k.next = e);
              b.interleaved = e;
              return;
            }
          } catch (l) {
          } finally {
          }
          c = be(a, b, e, d);
          null !== c && (e = O(), af(c, a, d, e), wf(c, b, d));
        }
      }
      function uf(a) {
        var b = a.alternate;
        return a === J || null !== b && b === J;
      }
      function vf(a, b) {
        De = Ce = true;
        var c = a.pending;
        null === c ? b.next = b : (b.next = c.next, c.next = b);
        a.pending = b;
      }
      function wf(a, b, c) {
        if (0 !== (c & 4194240)) {
          var d = b.lanes;
          d &= a.pendingLanes;
          c |= d;
          b.lanes = c;
          Hc(a, c);
        }
      }
      var Le = { readContext: Zd, useCallback: M, useContext: M, useEffect: M, useImperativeHandle: M, useInsertionEffect: M, useLayoutEffect: M, useMemo: M, useReducer: M, useRef: M, useState: M, useDebugValue: M, useDeferredValue: M, useTransition: M, useMutableSource: M, useSyncExternalStore: M, useId: M, unstable_isNewReconciler: false }, Ie = { readContext: Zd, useCallback: function(a, b) {
        Ne().memoizedState = [a, void 0 === b ? null : b];
        return a;
      }, useContext: Zd, useEffect: gf, useImperativeHandle: function(a, b, c) {
        c = null !== c && void 0 !== c ? c.concat([a]) : null;
        return ef(
          4194308,
          4,
          kf.bind(null, b, a),
          c
        );
      }, useLayoutEffect: function(a, b) {
        return ef(4194308, 4, a, b);
      }, useInsertionEffect: function(a, b) {
        return ef(4, 2, a, b);
      }, useMemo: function(a, b) {
        var c = Ne();
        b = void 0 === b ? null : b;
        a = a();
        c.memoizedState = [a, b];
        return a;
      }, useReducer: function(a, b, c) {
        var d = Ne();
        b = void 0 !== c ? c(b) : b;
        d.memoizedState = d.baseState = b;
        a = { pending: null, interleaved: null, lanes: 0, dispatch: null, lastRenderedReducer: a, lastRenderedState: b };
        d.queue = a;
        a = a.dispatch = sf.bind(null, J, a);
        return [d.memoizedState, a];
      }, useRef: function(a) {
        var b = Ne();
        a = { current: a };
        return b.memoizedState = a;
      }, useState: bf, useDebugValue: mf, useDeferredValue: function(a) {
        return Ne().memoizedState = a;
      }, useTransition: function() {
        var a = bf(false), b = a[0];
        a = qf.bind(null, a[1]);
        Ne().memoizedState = a;
        return [b, a];
      }, useMutableSource: function() {
      }, useSyncExternalStore: function(a, b, c) {
        var d = J, e = Ne();
        if (F) {
          if (void 0 === c) throw Error(n(407));
          c = c();
        } else {
          c = b();
          if (null === N) throw Error(n(349));
          0 !== (Be & 30) || Ye(d, b, c);
        }
        e.memoizedState = c;
        var f = { value: c, getSnapshot: b };
        e.queue = f;
        gf(Ve.bind(
          null,
          d,
          f,
          a
        ), [a]);
        d.flags |= 2048;
        We(9, Xe.bind(null, d, f, c, b), void 0, null);
        return c;
      }, useId: function() {
        var a = Ne(), b = N.identifierPrefix;
        if (F) {
          var c = jd;
          var d = id;
          c = (d & ~(1 << 32 - tc(d) - 1)).toString(32) + c;
          b = ":" + b + "R" + c;
          c = Ee++;
          0 < c && (b += "H" + c.toString(32));
          b += ":";
        } else c = Fe++, b = ":" + b + "r" + c.toString(32) + ":";
        return a.memoizedState = b;
      }, unstable_isNewReconciler: false }, Je = {
        readContext: Zd,
        useCallback: nf,
        useContext: Zd,
        useEffect: Ue,
        useImperativeHandle: lf,
        useInsertionEffect: hf,
        useLayoutEffect: jf,
        useMemo: of,
        useReducer: Qe,
        useRef: df,
        useState: function() {
          return Qe(Pe);
        },
        useDebugValue: mf,
        useDeferredValue: function(a) {
          var b = Oe();
          return pf(b, K.memoizedState, a);
        },
        useTransition: function() {
          var a = Qe(Pe)[0], b = Oe().memoizedState;
          return [a, b];
        },
        useMutableSource: Se,
        useSyncExternalStore: Te,
        useId: rf,
        unstable_isNewReconciler: false
      }, Ke = { readContext: Zd, useCallback: nf, useContext: Zd, useEffect: Ue, useImperativeHandle: lf, useInsertionEffect: hf, useLayoutEffect: jf, useMemo: of, useReducer: Re, useRef: df, useState: function() {
        return Re(Pe);
      }, useDebugValue: mf, useDeferredValue: function(a) {
        var b = Oe();
        return null === K ? b.memoizedState = a : pf(b, K.memoizedState, a);
      }, useTransition: function() {
        var a = Re(Pe)[0], b = Oe().memoizedState;
        return [a, b];
      }, useMutableSource: Se, useSyncExternalStore: Te, useId: rf, unstable_isNewReconciler: false };
      function xf(a, b) {
        if (a && a.defaultProps) {
          b = ca({}, b);
          a = a.defaultProps;
          for (var c in a) void 0 === b[c] && (b[c] = a[c]);
          return b;
        }
        return b;
      }
      function yf(a, b, c, d) {
        b = a.memoizedState;
        c = c(d, b);
        c = null === c || void 0 === c ? b : ca({}, b, c);
        a.memoizedState = c;
        0 === a.lanes && (a.updateQueue.baseState = c);
      }
      var zf = { isMounted: function(a) {
        return (a = a._reactInternals) ? wa(a) === a : false;
      }, enqueueSetState: function(a, b, c) {
        a = a._reactInternals;
        var d = O(), e = tf(a), f = ge(d, e);
        f.payload = b;
        void 0 !== c && null !== c && (f.callback = c);
        b = he(a, f, e);
        null !== b && (af(b, a, e, d), ie(b, a, e));
      }, enqueueReplaceState: function(a, b, c) {
        a = a._reactInternals;
        var d = O(), e = tf(a), f = ge(d, e);
        f.tag = 1;
        f.payload = b;
        void 0 !== c && null !== c && (f.callback = c);
        b = he(a, f, e);
        null !== b && (af(b, a, e, d), ie(b, a, e));
      }, enqueueForceUpdate: function(a, b) {
        a = a._reactInternals;
        var c = O(), d = tf(a), e = ge(c, d);
        e.tag = 2;
        void 0 !== b && null !== b && (e.callback = b);
        b = he(a, e, d);
        null !== b && (af(b, a, d, c), ie(b, a, d));
      } };
      function Af(a, b, c, d, e, f, g) {
        a = a.stateNode;
        return "function" === typeof a.shouldComponentUpdate ? a.shouldComponentUpdate(d, f, g) : b.prototype && b.prototype.isPureReactComponent ? !Dd(c, d) || !Dd(e, f) : true;
      }
      function Bf(a, b, c) {
        var d = false, e = jc;
        var f = b.contextType;
        "object" === typeof f && null !== f ? f = Zd(f) : (e = A(b) ? kc : x.current, d = b.contextTypes, f = (d = null !== d && void 0 !== d) ? mc(a, e) : jc);
        b = new b(c, f);
        a.memoizedState = null !== b.state && void 0 !== b.state ? b.state : null;
        b.updater = zf;
        a.stateNode = b;
        b._reactInternals = a;
        d && (a = a.stateNode, a.__reactInternalMemoizedUnmaskedChildContext = e, a.__reactInternalMemoizedMaskedChildContext = f);
        return b;
      }
      function Cf(a, b, c, d) {
        a = b.state;
        "function" === typeof b.componentWillReceiveProps && b.componentWillReceiveProps(c, d);
        "function" === typeof b.UNSAFE_componentWillReceiveProps && b.UNSAFE_componentWillReceiveProps(c, d);
        b.state !== a && zf.enqueueReplaceState(b, b.state, null);
      }
      function Df(a, b, c, d) {
        var e = a.stateNode;
        e.props = c;
        e.state = a.memoizedState;
        e.refs = {};
        ee(a);
        var f = b.contextType;
        "object" === typeof f && null !== f ? e.context = Zd(f) : (f = A(b) ? kc : x.current, e.context = mc(a, f));
        e.state = a.memoizedState;
        f = b.getDerivedStateFromProps;
        "function" === typeof f && (yf(a, b, f, c), e.state = a.memoizedState);
        "function" === typeof b.getDerivedStateFromProps || "function" === typeof e.getSnapshotBeforeUpdate || "function" !== typeof e.UNSAFE_componentWillMount && "function" !== typeof e.componentWillMount || (b = e.state, "function" === typeof e.componentWillMount && e.componentWillMount(), "function" === typeof e.UNSAFE_componentWillMount && e.UNSAFE_componentWillMount(), b !== e.state && zf.enqueueReplaceState(e, e.state, null), ke(a, c, e, d), e.state = a.memoizedState);
        "function" === typeof e.componentDidMount && (a.flags |= 4194308);
      }
      function Ef(a, b) {
        try {
          var c = "", d = b;
          do
            c += Ed(d), d = d.return;
          while (d);
          var e = c;
        } catch (f) {
          e = "\nError generating stack: " + f.message + "\n" + f.stack;
        }
        return { value: a, source: b, stack: e, digest: null };
      }
      function Ff(a, b, c) {
        return { value: a, source: null, stack: null != c ? c : null, digest: null != b ? b : null };
      }
      function Gf(a, b) {
        try {
          console.error(b.value);
        } catch (c) {
          setTimeout(function() {
            throw c;
          });
        }
      }
      var Hf = "function" === typeof WeakMap ? WeakMap : Map;
      function If(a, b, c) {
        c = ge(-1, c);
        c.tag = 3;
        c.payload = { element: null };
        var d = b.value;
        c.callback = function() {
          Jf || (Jf = true, Kf = d);
          Gf(a, b);
        };
        return c;
      }
      function Lf(a, b, c) {
        c = ge(-1, c);
        c.tag = 3;
        var d = a.type.getDerivedStateFromError;
        if ("function" === typeof d) {
          var e = b.value;
          c.payload = function() {
            return d(e);
          };
          c.callback = function() {
            Gf(a, b);
          };
        }
        var f = a.stateNode;
        null !== f && "function" === typeof f.componentDidCatch && (c.callback = function() {
          Gf(a, b);
          "function" !== typeof d && (null === Mf ? Mf = /* @__PURE__ */ new Set([this]) : Mf.add(this));
          var c2 = b.stack;
          this.componentDidCatch(b.value, { componentStack: null !== c2 ? c2 : "" });
        });
        return c;
      }
      function Nf(a, b, c) {
        var d = a.pingCache;
        if (null === d) {
          d = a.pingCache = new Hf();
          var e = /* @__PURE__ */ new Set();
          d.set(b, e);
        } else e = d.get(b), void 0 === e && (e = /* @__PURE__ */ new Set(), d.set(b, e));
        e.has(c) || (e.add(c), a = Of.bind(null, a, b, c), b.then(a, a));
      }
      function Pf(a) {
        do {
          var b;
          if (b = 13 === a.tag) b = a.memoizedState, b = null !== b ? null !== b.dehydrated ? true : false : true;
          if (b) return a;
          a = a.return;
        } while (null !== a);
        return null;
      }
      function Qf(a, b, c, d, e) {
        if (0 === (a.mode & 1)) return a === b ? a.flags |= 65536 : (a.flags |= 128, c.flags |= 131072, c.flags &= -52805, 1 === c.tag && (null === c.alternate ? c.tag = 17 : (b = ge(-1, 1), b.tag = 2, he(c, b, 1))), c.lanes |= 1), a;
        a.flags |= 65536;
        a.lanes = e;
        return a;
      }
      var Rf = da.ReactCurrentOwner, G = false;
      function P(a, b, c, d) {
        b.child = null === a ? Pd(b, null, c, d) : Od(b, a.child, c, d);
      }
      function Sf(a, b, c, d, e) {
        c = c.render;
        var f = b.ref;
        Yd(b, e);
        d = He(a, b, c, d, f, e);
        c = Me();
        if (null !== a && !G) return b.updateQueue = a.updateQueue, b.flags &= -2053, a.lanes &= ~e, Tf(a, b, e);
        F && c && md(b);
        b.flags |= 1;
        P(a, b, d, e);
        return b.child;
      }
      function Uf(a, b, c, d, e) {
        if (null === a) {
          var f = c.type;
          if ("function" === typeof f && !Vf(f) && void 0 === f.defaultProps && null === c.compare && void 0 === c.defaultProps) return b.tag = 15, b.type = f, Wf(a, b, f, d, e);
          a = Ld(c.type, null, d, b, b.mode, e);
          a.ref = b.ref;
          a.return = b;
          return b.child = a;
        }
        f = a.child;
        if (0 === (a.lanes & e)) {
          var g = f.memoizedProps;
          c = c.compare;
          c = null !== c ? c : Dd;
          if (c(g, d) && a.ref === b.ref) return Tf(a, b, e);
        }
        b.flags |= 1;
        a = Jd(f, d);
        a.ref = b.ref;
        a.return = b;
        return b.child = a;
      }
      function Wf(a, b, c, d, e) {
        if (null !== a) {
          var f = a.memoizedProps;
          if (Dd(f, d) && a.ref === b.ref) if (G = false, b.pendingProps = d = f, 0 !== (a.lanes & e)) 0 !== (a.flags & 131072) && (G = true);
          else return b.lanes = a.lanes, Tf(a, b, e);
        }
        return Xf(a, b, c, d, e);
      }
      function Yf(a, b, c) {
        var d = b.pendingProps, e = d.children, f = null !== a ? a.memoizedState : null;
        if ("hidden" === d.mode) if (0 === (b.mode & 1)) b.memoizedState = { baseLanes: 0, cachePool: null, transitions: null }, v(Zf, $f), $f |= c;
        else {
          if (0 === (c & 1073741824)) return a = null !== f ? f.baseLanes | c : c, b.lanes = b.childLanes = 1073741824, b.memoizedState = { baseLanes: a, cachePool: null, transitions: null }, b.updateQueue = null, v(Zf, $f), $f |= a, null;
          b.memoizedState = { baseLanes: 0, cachePool: null, transitions: null };
          d = null !== f ? f.baseLanes : c;
          v(Zf, $f);
          $f |= d;
        }
        else null !== f ? (d = f.baseLanes | c, b.memoizedState = null) : d = c, v(Zf, $f), $f |= d;
        P(a, b, e, c);
        return b.child;
      }
      function ag(a, b) {
        var c = b.ref;
        if (null === a && null !== c || null !== a && a.ref !== c) b.flags |= 512, b.flags |= 2097152;
      }
      function Xf(a, b, c, d, e) {
        var f = A(c) ? kc : x.current;
        f = mc(b, f);
        Yd(b, e);
        c = He(a, b, c, d, f, e);
        d = Me();
        if (null !== a && !G) return b.updateQueue = a.updateQueue, b.flags &= -2053, a.lanes &= ~e, Tf(a, b, e);
        F && d && md(b);
        b.flags |= 1;
        P(a, b, c, e);
        return b.child;
      }
      function bg(a, b, c, d, e) {
        if (A(c)) {
          var f = true;
          qc(b);
        } else f = false;
        Yd(b, e);
        if (null === b.stateNode) cg(a, b), Bf(b, c, d), Df(b, c, d, e), d = true;
        else if (null === a) {
          var g = b.stateNode, h = b.memoizedProps;
          g.props = h;
          var k = g.context, l = c.contextType;
          "object" === typeof l && null !== l ? l = Zd(l) : (l = A(c) ? kc : x.current, l = mc(b, l));
          var m = c.getDerivedStateFromProps, r = "function" === typeof m || "function" === typeof g.getSnapshotBeforeUpdate;
          r || "function" !== typeof g.UNSAFE_componentWillReceiveProps && "function" !== typeof g.componentWillReceiveProps || (h !== d || k !== l) && Cf(b, g, d, l);
          de = false;
          var p = b.memoizedState;
          g.state = p;
          ke(b, d, g, e);
          k = b.memoizedState;
          h !== d || p !== k || z.current || de ? ("function" === typeof m && (yf(b, c, m, d), k = b.memoizedState), (h = de || Af(b, c, h, d, p, k, l)) ? (r || "function" !== typeof g.UNSAFE_componentWillMount && "function" !== typeof g.componentWillMount || ("function" === typeof g.componentWillMount && g.componentWillMount(), "function" === typeof g.UNSAFE_componentWillMount && g.UNSAFE_componentWillMount()), "function" === typeof g.componentDidMount && (b.flags |= 4194308)) : ("function" === typeof g.componentDidMount && (b.flags |= 4194308), b.memoizedProps = d, b.memoizedState = k), g.props = d, g.state = k, g.context = l, d = h) : ("function" === typeof g.componentDidMount && (b.flags |= 4194308), d = false);
        } else {
          g = b.stateNode;
          fe(a, b);
          h = b.memoizedProps;
          l = b.type === b.elementType ? h : xf(b.type, h);
          g.props = l;
          r = b.pendingProps;
          p = g.context;
          k = c.contextType;
          "object" === typeof k && null !== k ? k = Zd(k) : (k = A(c) ? kc : x.current, k = mc(b, k));
          var B = c.getDerivedStateFromProps;
          (m = "function" === typeof B || "function" === typeof g.getSnapshotBeforeUpdate) || "function" !== typeof g.UNSAFE_componentWillReceiveProps && "function" !== typeof g.componentWillReceiveProps || (h !== r || p !== k) && Cf(b, g, d, k);
          de = false;
          p = b.memoizedState;
          g.state = p;
          ke(b, d, g, e);
          var w = b.memoizedState;
          h !== r || p !== w || z.current || de ? ("function" === typeof B && (yf(b, c, B, d), w = b.memoizedState), (l = de || Af(b, c, l, d, p, w, k) || false) ? (m || "function" !== typeof g.UNSAFE_componentWillUpdate && "function" !== typeof g.componentWillUpdate || ("function" === typeof g.componentWillUpdate && g.componentWillUpdate(d, w, k), "function" === typeof g.UNSAFE_componentWillUpdate && g.UNSAFE_componentWillUpdate(d, w, k)), "function" === typeof g.componentDidUpdate && (b.flags |= 4), "function" === typeof g.getSnapshotBeforeUpdate && (b.flags |= 1024)) : ("function" !== typeof g.componentDidUpdate || h === a.memoizedProps && p === a.memoizedState || (b.flags |= 4), "function" !== typeof g.getSnapshotBeforeUpdate || h === a.memoizedProps && p === a.memoizedState || (b.flags |= 1024), b.memoizedProps = d, b.memoizedState = w), g.props = d, g.state = w, g.context = k, d = l) : ("function" !== typeof g.componentDidUpdate || h === a.memoizedProps && p === a.memoizedState || (b.flags |= 4), "function" !== typeof g.getSnapshotBeforeUpdate || h === a.memoizedProps && p === a.memoizedState || (b.flags |= 1024), d = false);
        }
        return dg(a, b, c, d, f, e);
      }
      function dg(a, b, c, d, e, f) {
        ag(a, b);
        var g = 0 !== (b.flags & 128);
        if (!d && !g) return e && rc(b, c, false), Tf(a, b, f);
        d = b.stateNode;
        Rf.current = b;
        var h = g && "function" !== typeof c.getDerivedStateFromError ? null : d.render();
        b.flags |= 1;
        null !== a && g ? (b.child = Od(b, a.child, null, f), b.child = Od(b, null, h, f)) : P(a, b, h, f);
        b.memoizedState = d.state;
        e && rc(b, c, true);
        return b.child;
      }
      function eg(a) {
        var b = a.stateNode;
        b.pendingContext ? oc(a, b.pendingContext, b.pendingContext !== b.context) : b.context && oc(a, b.context, false);
        se(a, b.containerInfo);
      }
      function fg(a, b, c, d, e) {
        Ad();
        Bd(e);
        b.flags |= 256;
        P(a, b, c, d);
        return b.child;
      }
      var gg = { dehydrated: null, treeContext: null, retryLane: 0 };
      function hg(a) {
        return { baseLanes: a, cachePool: null, transitions: null };
      }
      function ig(a, b, c) {
        var d = b.pendingProps, e = I.current, f = false, g = 0 !== (b.flags & 128), h;
        (h = g) || (h = null !== a && null === a.memoizedState ? false : 0 !== (e & 2));
        if (h) f = true, b.flags &= -129;
        else if (null === a || null !== a.memoizedState) e |= 1;
        v(I, e & 1);
        if (null === a) {
          wd(b);
          a = b.memoizedState;
          if (null !== a && (a = a.dehydrated, null !== a)) return 0 === (b.mode & 1) ? b.lanes = 1 : Kb(a) ? b.lanes = 8 : b.lanes = 1073741824, null;
          g = d.children;
          a = d.fallback;
          return f ? (d = b.mode, f = b.child, g = { mode: "hidden", children: g }, 0 === (d & 1) && null !== f ? (f.childLanes = 0, f.pendingProps = g) : f = jg(g, d, 0, null), a = Nd(a, d, c, null), f.return = b, a.return = b, f.sibling = a, b.child = f, b.child.memoizedState = hg(c), b.memoizedState = gg, a) : kg(b, g);
        }
        e = a.memoizedState;
        if (null !== e && (h = e.dehydrated, null !== h)) return lg(a, b, g, d, h, e, c);
        if (f) {
          f = d.fallback;
          g = b.mode;
          e = a.child;
          h = e.sibling;
          var k = { mode: "hidden", children: d.children };
          0 === (g & 1) && b.child !== e ? (d = b.child, d.childLanes = 0, d.pendingProps = k, b.deletions = null) : (d = Jd(e, k), d.subtreeFlags = e.subtreeFlags & 14680064);
          null !== h ? f = Jd(h, f) : (f = Nd(f, g, c, null), f.flags |= 2);
          f.return = b;
          d.return = b;
          d.sibling = f;
          b.child = d;
          d = f;
          f = b.child;
          g = a.child.memoizedState;
          g = null === g ? hg(c) : { baseLanes: g.baseLanes | c, cachePool: null, transitions: g.transitions };
          f.memoizedState = g;
          f.childLanes = a.childLanes & ~c;
          b.memoizedState = gg;
          return d;
        }
        f = a.child;
        a = f.sibling;
        d = Jd(f, { mode: "visible", children: d.children });
        0 === (b.mode & 1) && (d.lanes = c);
        d.return = b;
        d.sibling = null;
        null !== a && (c = b.deletions, null === c ? (b.deletions = [a], b.flags |= 16) : c.push(a));
        b.child = d;
        b.memoizedState = null;
        return d;
      }
      function kg(a, b) {
        b = jg({ mode: "visible", children: b }, a.mode, 0, null);
        b.return = a;
        return a.child = b;
      }
      function mg(a, b, c, d) {
        null !== d && Bd(d);
        Od(b, a.child, null, c);
        a = kg(b, b.pendingProps.children);
        a.flags |= 2;
        b.memoizedState = null;
        return a;
      }
      function lg(a, b, c, d, e, f, g) {
        if (c) {
          if (b.flags & 256) return b.flags &= -257, d = Ff(Error(n(422))), mg(a, b, g, d);
          if (null !== b.memoizedState) return b.child = a.child, b.flags |= 128, null;
          f = d.fallback;
          e = b.mode;
          d = jg({ mode: "visible", children: d.children }, e, 0, null);
          f = Nd(f, e, g, null);
          f.flags |= 2;
          d.return = b;
          f.return = b;
          d.sibling = f;
          b.child = d;
          0 !== (b.mode & 1) && Od(b, a.child, null, g);
          b.child.memoizedState = hg(g);
          b.memoizedState = gg;
          return f;
        }
        if (0 === (b.mode & 1)) return mg(a, b, g, null);
        if (Kb(e)) return d = Lb(e).digest, f = Error(n(419)), d = Ff(
          f,
          d,
          void 0
        ), mg(a, b, g, d);
        c = 0 !== (g & a.childLanes);
        if (G || c) {
          d = N;
          if (null !== d) {
            switch (g & -g) {
              case 4:
                e = 2;
                break;
              case 16:
                e = 8;
                break;
              case 64:
              case 128:
              case 256:
              case 512:
              case 1024:
              case 2048:
              case 4096:
              case 8192:
              case 16384:
              case 32768:
              case 65536:
              case 131072:
              case 262144:
              case 524288:
              case 1048576:
              case 2097152:
              case 4194304:
              case 8388608:
              case 16777216:
              case 33554432:
              case 67108864:
                e = 32;
                break;
              case 536870912:
                e = 268435456;
                break;
              default:
                e = 0;
            }
            e = 0 !== (e & (d.suspendedLanes | g)) ? 0 : e;
            0 !== e && e !== f.retryLane && (f.retryLane = e, ce(a, e), af(
              d,
              a,
              e,
              -1
            ));
          }
          ng();
          d = Ff(Error(n(421)));
          return mg(a, b, g, d);
        }
        if (Jb(e)) return b.flags |= 128, b.child = a.child, b = og.bind(null, a), Mb(e, b), null;
        a = f.treeContext;
        Va && (pd = Qb(e), od = b, F = true, rd = null, qd = false, null !== a && (fd[gd++] = id, fd[gd++] = jd, fd[gd++] = hd, id = a.id, jd = a.overflow, hd = b));
        b = kg(b, d.children);
        b.flags |= 4096;
        return b;
      }
      function pg(a, b, c) {
        a.lanes |= b;
        var d = a.alternate;
        null !== d && (d.lanes |= b);
        Xd(a.return, b, c);
      }
      function qg(a, b, c, d, e) {
        var f = a.memoizedState;
        null === f ? a.memoizedState = { isBackwards: b, rendering: null, renderingStartTime: 0, last: d, tail: c, tailMode: e } : (f.isBackwards = b, f.rendering = null, f.renderingStartTime = 0, f.last = d, f.tail = c, f.tailMode = e);
      }
      function rg(a, b, c) {
        var d = b.pendingProps, e = d.revealOrder, f = d.tail;
        P(a, b, d.children, c);
        d = I.current;
        if (0 !== (d & 2)) d = d & 1 | 2, b.flags |= 128;
        else {
          if (null !== a && 0 !== (a.flags & 128)) a: for (a = b.child; null !== a; ) {
            if (13 === a.tag) null !== a.memoizedState && pg(a, c, b);
            else if (19 === a.tag) pg(a, c, b);
            else if (null !== a.child) {
              a.child.return = a;
              a = a.child;
              continue;
            }
            if (a === b) break a;
            for (; null === a.sibling; ) {
              if (null === a.return || a.return === b) break a;
              a = a.return;
            }
            a.sibling.return = a.return;
            a = a.sibling;
          }
          d &= 1;
        }
        v(I, d);
        if (0 === (b.mode & 1)) b.memoizedState = null;
        else switch (e) {
          case "forwards":
            c = b.child;
            for (e = null; null !== c; ) a = c.alternate, null !== a && null === we(a) && (e = c), c = c.sibling;
            c = e;
            null === c ? (e = b.child, b.child = null) : (e = c.sibling, c.sibling = null);
            qg(b, false, e, c, f);
            break;
          case "backwards":
            c = null;
            e = b.child;
            for (b.child = null; null !== e; ) {
              a = e.alternate;
              if (null !== a && null === we(a)) {
                b.child = e;
                break;
              }
              a = e.sibling;
              e.sibling = c;
              c = e;
              e = a;
            }
            qg(b, true, c, null, f);
            break;
          case "together":
            qg(b, false, null, null, void 0);
            break;
          default:
            b.memoizedState = null;
        }
        return b.child;
      }
      function cg(a, b) {
        0 === (b.mode & 1) && null !== a && (a.alternate = null, b.alternate = null, b.flags |= 2);
      }
      function Tf(a, b, c) {
        null !== a && (b.dependencies = a.dependencies);
        le |= b.lanes;
        if (0 === (c & b.childLanes)) return null;
        if (null !== a && b.child !== a.child) throw Error(n(153));
        if (null !== b.child) {
          a = b.child;
          c = Jd(a, a.pendingProps);
          b.child = c;
          for (c.return = b; null !== a.sibling; ) a = a.sibling, c = c.sibling = Jd(a, a.pendingProps), c.return = b;
          c.sibling = null;
        }
        return b.child;
      }
      function sg(a, b, c) {
        switch (b.tag) {
          case 3:
            eg(b);
            Ad();
            break;
          case 5:
            ue(b);
            break;
          case 1:
            A(b.type) && qc(b);
            break;
          case 4:
            se(b, b.stateNode.containerInfo);
            break;
          case 10:
            Vd(b, b.type._context, b.memoizedProps.value);
            break;
          case 13:
            var d = b.memoizedState;
            if (null !== d) {
              if (null !== d.dehydrated) return v(I, I.current & 1), b.flags |= 128, null;
              if (0 !== (c & b.child.childLanes)) return ig(a, b, c);
              v(I, I.current & 1);
              a = Tf(a, b, c);
              return null !== a ? a.sibling : null;
            }
            v(I, I.current & 1);
            break;
          case 19:
            d = 0 !== (c & b.childLanes);
            if (0 !== (a.flags & 128)) {
              if (d) return rg(
                a,
                b,
                c
              );
              b.flags |= 128;
            }
            var e = b.memoizedState;
            null !== e && (e.rendering = null, e.tail = null, e.lastEffect = null);
            v(I, I.current);
            if (d) break;
            else return null;
          case 22:
          case 23:
            return b.lanes = 0, Yf(a, b, c);
        }
        return Tf(a, b, c);
      }
      function tg(a) {
        a.flags |= 4;
      }
      function ug(a, b) {
        if (null !== a && a.child === b.child) return true;
        if (0 !== (b.flags & 16)) return false;
        for (a = b.child; null !== a; ) {
          if (0 !== (a.flags & 12854) || 0 !== (a.subtreeFlags & 12854)) return false;
          a = a.sibling;
        }
        return true;
      }
      var vg, wg, xg, yg;
      if (Ta) vg = function(a, b) {
        for (var c = b.child; null !== c; ) {
          if (5 === c.tag || 6 === c.tag) Ka(a, c.stateNode);
          else if (4 !== c.tag && null !== c.child) {
            c.child.return = c;
            c = c.child;
            continue;
          }
          if (c === b) break;
          for (; null === c.sibling; ) {
            if (null === c.return || c.return === b) return;
            c = c.return;
          }
          c.sibling.return = c.return;
          c = c.sibling;
        }
      }, wg = function() {
      }, xg = function(a, b, c, d, e) {
        a = a.memoizedProps;
        if (a !== d) {
          var f = b.stateNode, g = re(oe.current);
          c = Ma(f, c, a, d, e, g);
          (b.updateQueue = c) && tg(b);
        }
      }, yg = function(a, b, c, d) {
        c !== d && tg(b);
      };
      else if (Ua) {
        vg = function(a, b, c, d) {
          for (var e = b.child; null !== e; ) {
            if (5 === e.tag) {
              var f = e.stateNode;
              c && d && (f = Eb(f, e.type, e.memoizedProps, e));
              Ka(a, f);
            } else if (6 === e.tag) f = e.stateNode, c && d && (f = Fb(f, e.memoizedProps, e)), Ka(a, f);
            else if (4 !== e.tag) {
              if (22 === e.tag && null !== e.memoizedState) f = e.child, null !== f && (f.return = e), vg(a, e, true, true);
              else if (null !== e.child) {
                e.child.return = e;
                e = e.child;
                continue;
              }
            }
            if (e === b) break;
            for (; null === e.sibling; ) {
              if (null === e.return || e.return === b) return;
              e = e.return;
            }
            e.sibling.return = e.return;
            e = e.sibling;
          }
        };
        var zg = function(a, b, c, d) {
          for (var e = b.child; null !== e; ) {
            if (5 === e.tag) {
              var f = e.stateNode;
              c && d && (f = Eb(f, e.type, e.memoizedProps, e));
              Ab(a, f);
            } else if (6 === e.tag) f = e.stateNode, c && d && (f = Fb(f, e.memoizedProps, e)), Ab(a, f);
            else if (4 !== e.tag) {
              if (22 === e.tag && null !== e.memoizedState) f = e.child, null !== f && (f.return = e), zg(a, e, true, true);
              else if (null !== e.child) {
                e.child.return = e;
                e = e.child;
                continue;
              }
            }
            if (e === b) break;
            for (; null === e.sibling; ) {
              if (null === e.return || e.return === b) return;
              e = e.return;
            }
            e.sibling.return = e.return;
            e = e.sibling;
          }
        };
        wg = function(a, b) {
          var c = b.stateNode;
          if (!ug(a, b)) {
            a = c.containerInfo;
            var d = zb(a);
            zg(d, b, false, false);
            c.pendingChildren = d;
            tg(b);
            Bb(a, d);
          }
        };
        xg = function(a, b, c, d, e) {
          var f = a.stateNode, g = a.memoizedProps;
          if ((a = ug(a, b)) && g === d) b.stateNode = f;
          else {
            var h = b.stateNode, k = re(oe.current), l = null;
            g !== d && (l = Ma(h, c, g, d, e, k));
            a && null === l ? b.stateNode = f : (f = yb(f, l, c, g, d, b, a, h), La(f, c, d, e, k) && tg(b), b.stateNode = f, a ? tg(b) : vg(f, b, false, false));
          }
        };
        yg = function(a, b, c, d) {
          c !== d ? (a = re(qe.current), c = re(oe.current), b.stateNode = Oa(d, a, c, b), tg(b)) : b.stateNode = a.stateNode;
        };
      } else wg = function() {
      }, xg = function() {
      }, yg = function() {
      };
      function Ag(a, b) {
        if (!F) switch (a.tailMode) {
          case "hidden":
            b = a.tail;
            for (var c = null; null !== b; ) null !== b.alternate && (c = b), b = b.sibling;
            null === c ? a.tail = null : c.sibling = null;
            break;
          case "collapsed":
            c = a.tail;
            for (var d = null; null !== c; ) null !== c.alternate && (d = c), c = c.sibling;
            null === d ? b || null === a.tail ? a.tail = null : a.tail.sibling = null : d.sibling = null;
        }
      }
      function Q(a) {
        var b = null !== a.alternate && a.alternate.child === a.child, c = 0, d = 0;
        if (b) for (var e = a.child; null !== e; ) c |= e.lanes | e.childLanes, d |= e.subtreeFlags & 14680064, d |= e.flags & 14680064, e.return = a, e = e.sibling;
        else for (e = a.child; null !== e; ) c |= e.lanes | e.childLanes, d |= e.subtreeFlags, d |= e.flags, e.return = a, e = e.sibling;
        a.subtreeFlags |= d;
        a.childLanes = c;
        return b;
      }
      function Bg(a, b, c) {
        var d = b.pendingProps;
        nd(b);
        switch (b.tag) {
          case 2:
          case 16:
          case 15:
          case 0:
          case 11:
          case 7:
          case 8:
          case 12:
          case 9:
          case 14:
            return Q(b), null;
          case 1:
            return A(b.type) && nc(), Q(b), null;
          case 3:
            c = b.stateNode;
            te();
            q(z);
            q(x);
            ye();
            c.pendingContext && (c.context = c.pendingContext, c.pendingContext = null);
            if (null === a || null === a.child) yd(b) ? tg(b) : null === a || a.memoizedState.isDehydrated && 0 === (b.flags & 256) || (b.flags |= 1024, null !== rd && (Cg(rd), rd = null));
            wg(a, b);
            Q(b);
            return null;
          case 5:
            ve(b);
            c = re(qe.current);
            var e = b.type;
            if (null !== a && null != b.stateNode) xg(a, b, e, d, c), a.ref !== b.ref && (b.flags |= 512, b.flags |= 2097152);
            else {
              if (!d) {
                if (null === b.stateNode) throw Error(n(166));
                Q(b);
                return null;
              }
              a = re(oe.current);
              if (yd(b)) {
                if (!Va) throw Error(n(175));
                a = Rb(b.stateNode, b.type, b.memoizedProps, c, a, b, !qd);
                b.updateQueue = a;
                null !== a && tg(b);
              } else {
                var f = Ja(e, d, c, a, b);
                vg(f, b, false, false);
                b.stateNode = f;
                La(f, e, d, c, a) && tg(b);
              }
              null !== b.ref && (b.flags |= 512, b.flags |= 2097152);
            }
            Q(b);
            return null;
          case 6:
            if (a && null != b.stateNode) yg(a, b, a.memoizedProps, d);
            else {
              if ("string" !== typeof d && null === b.stateNode) throw Error(n(166));
              a = re(qe.current);
              c = re(oe.current);
              if (yd(b)) {
                if (!Va) throw Error(n(176));
                a = b.stateNode;
                c = b.memoizedProps;
                if (d = Sb(a, c, b, !qd)) {
                  if (e = od, null !== e) switch (e.tag) {
                    case 3:
                      $b(e.stateNode.containerInfo, a, c, 0 !== (e.mode & 1));
                      break;
                    case 5:
                      ac(e.type, e.memoizedProps, e.stateNode, a, c, 0 !== (e.mode & 1));
                  }
                }
                d && tg(b);
              } else b.stateNode = Oa(d, a, c, b);
            }
            Q(b);
            return null;
          case 13:
            q(I);
            d = b.memoizedState;
            if (null === a || null !== a.memoizedState && null !== a.memoizedState.dehydrated) {
              if (F && null !== pd && 0 !== (b.mode & 1) && 0 === (b.flags & 128)) zd(), Ad(), b.flags |= 98560, e = false;
              else if (e = yd(b), null !== d && null !== d.dehydrated) {
                if (null === a) {
                  if (!e) throw Error(n(318));
                  if (!Va) throw Error(n(344));
                  e = b.memoizedState;
                  e = null !== e ? e.dehydrated : null;
                  if (!e) throw Error(n(317));
                  Tb(e, b);
                } else Ad(), 0 === (b.flags & 128) && (b.memoizedState = null), b.flags |= 4;
                Q(b);
                e = false;
              } else null !== rd && (Cg(rd), rd = null), e = true;
              if (!e) return b.flags & 65536 ? b : null;
            }
            if (0 !== (b.flags & 128)) return b.lanes = c, b;
            c = null !== d;
            c !== (null !== a && null !== a.memoizedState) && c && (b.child.flags |= 8192, 0 !== (b.mode & 1) && (null === a || 0 !== (I.current & 1) ? 0 === R && (R = 3) : ng()));
            null !== b.updateQueue && (b.flags |= 4);
            Q(b);
            return null;
          case 4:
            return te(), wg(a, b), null === a && Xa(b.stateNode.containerInfo), Q(b), null;
          case 10:
            return Wd(b.type._context), Q(b), null;
          case 17:
            return A(b.type) && nc(), Q(b), null;
          case 19:
            q(I);
            e = b.memoizedState;
            if (null === e) return Q(b), null;
            d = 0 !== (b.flags & 128);
            f = e.rendering;
            if (null === f) if (d) Ag(e, false);
            else {
              if (0 !== R || null !== a && 0 !== (a.flags & 128)) for (a = b.child; null !== a; ) {
                f = we(a);
                if (null !== f) {
                  b.flags |= 128;
                  Ag(e, false);
                  a = f.updateQueue;
                  null !== a && (b.updateQueue = a, b.flags |= 4);
                  b.subtreeFlags = 0;
                  a = c;
                  for (c = b.child; null !== c; ) d = c, e = a, d.flags &= 14680066, f = d.alternate, null === f ? (d.childLanes = 0, d.lanes = e, d.child = null, d.subtreeFlags = 0, d.memoizedProps = null, d.memoizedState = null, d.updateQueue = null, d.dependencies = null, d.stateNode = null) : (d.childLanes = f.childLanes, d.lanes = f.lanes, d.child = f.child, d.subtreeFlags = 0, d.deletions = null, d.memoizedProps = f.memoizedProps, d.memoizedState = f.memoizedState, d.updateQueue = f.updateQueue, d.type = f.type, e = f.dependencies, d.dependencies = null === e ? null : { lanes: e.lanes, firstContext: e.firstContext }), c = c.sibling;
                  v(I, I.current & 1 | 2);
                  return b.child;
                }
                a = a.sibling;
              }
              null !== e.tail && D() > Dg && (b.flags |= 128, d = true, Ag(e, false), b.lanes = 4194304);
            }
            else {
              if (!d) if (a = we(f), null !== a) {
                if (b.flags |= 128, d = true, a = a.updateQueue, null !== a && (b.updateQueue = a, b.flags |= 4), Ag(e, true), null === e.tail && "hidden" === e.tailMode && !f.alternate && !F) return Q(b), null;
              } else 2 * D() - e.renderingStartTime > Dg && 1073741824 !== c && (b.flags |= 128, d = true, Ag(e, false), b.lanes = 4194304);
              e.isBackwards ? (f.sibling = b.child, b.child = f) : (a = e.last, null !== a ? a.sibling = f : b.child = f, e.last = f);
            }
            if (null !== e.tail) return b = e.tail, e.rendering = b, e.tail = b.sibling, e.renderingStartTime = D(), b.sibling = null, a = I.current, v(I, d ? a & 1 | 2 : a & 1), b;
            Q(b);
            return null;
          case 22:
          case 23:
            return Eg(), c = null !== b.memoizedState, null !== a && null !== a.memoizedState !== c && (b.flags |= 8192), c && 0 !== (b.mode & 1) ? 0 !== ($f & 1073741824) && (Q(b), Ta && b.subtreeFlags & 6 && (b.flags |= 8192)) : Q(b), null;
          case 24:
            return null;
          case 25:
            return null;
        }
        throw Error(n(
          156,
          b.tag
        ));
      }
      function Fg(a, b) {
        nd(b);
        switch (b.tag) {
          case 1:
            return A(b.type) && nc(), a = b.flags, a & 65536 ? (b.flags = a & -65537 | 128, b) : null;
          case 3:
            return te(), q(z), q(x), ye(), a = b.flags, 0 !== (a & 65536) && 0 === (a & 128) ? (b.flags = a & -65537 | 128, b) : null;
          case 5:
            return ve(b), null;
          case 13:
            q(I);
            a = b.memoizedState;
            if (null !== a && null !== a.dehydrated) {
              if (null === b.alternate) throw Error(n(340));
              Ad();
            }
            a = b.flags;
            return a & 65536 ? (b.flags = a & -65537 | 128, b) : null;
          case 19:
            return q(I), null;
          case 4:
            return te(), null;
          case 10:
            return Wd(b.type._context), null;
          case 22:
          case 23:
            return Eg(), null;
          case 24:
            return null;
          default:
            return null;
        }
      }
      var Gg = false, S = false, Hg = "function" === typeof WeakSet ? WeakSet : Set, T = null;
      function Ig(a, b) {
        var c = a.ref;
        if (null !== c) if ("function" === typeof c) try {
          c(null);
        } catch (d) {
          U(a, b, d);
        }
        else c.current = null;
      }
      function Jg(a, b, c) {
        try {
          c();
        } catch (d) {
          U(a, b, d);
        }
      }
      var Kg = false;
      function Lg(a, b) {
        Ha(a.containerInfo);
        for (T = b; null !== T; ) if (a = T, b = a.child, 0 !== (a.subtreeFlags & 1028) && null !== b) b.return = a, T = b;
        else for (; null !== T; ) {
          a = T;
          try {
            var c = a.alternate;
            if (0 !== (a.flags & 1024)) switch (a.tag) {
              case 0:
              case 11:
              case 15:
                break;
              case 1:
                if (null !== c) {
                  var d = c.memoizedProps, e = c.memoizedState, f = a.stateNode, g = f.getSnapshotBeforeUpdate(a.elementType === a.type ? d : xf(a.type, d), e);
                  f.__reactInternalSnapshotBeforeUpdate = g;
                }
                break;
              case 3:
                Ta && xb(a.stateNode.containerInfo);
                break;
              case 5:
              case 6:
              case 4:
              case 17:
                break;
              default:
                throw Error(n(163));
            }
          } catch (h) {
            U(a, a.return, h);
          }
          b = a.sibling;
          if (null !== b) {
            b.return = a.return;
            T = b;
            break;
          }
          T = a.return;
        }
        c = Kg;
        Kg = false;
        return c;
      }
      function Mg(a, b, c) {
        var d = b.updateQueue;
        d = null !== d ? d.lastEffect : null;
        if (null !== d) {
          var e = d = d.next;
          do {
            if ((e.tag & a) === a) {
              var f = e.destroy;
              e.destroy = void 0;
              void 0 !== f && Jg(b, c, f);
            }
            e = e.next;
          } while (e !== d);
        }
      }
      function Ng(a, b) {
        b = b.updateQueue;
        b = null !== b ? b.lastEffect : null;
        if (null !== b) {
          var c = b = b.next;
          do {
            if ((c.tag & a) === a) {
              var d = c.create;
              c.destroy = d();
            }
            c = c.next;
          } while (c !== b);
        }
      }
      function Og(a) {
        var b = a.ref;
        if (null !== b) {
          var c = a.stateNode;
          switch (a.tag) {
            case 5:
              a = Ea(c);
              break;
            default:
              a = c;
          }
          "function" === typeof b ? b(a) : b.current = a;
        }
      }
      function Pg(a) {
        var b = a.alternate;
        null !== b && (a.alternate = null, Pg(b));
        a.child = null;
        a.deletions = null;
        a.sibling = null;
        5 === a.tag && (b = a.stateNode, null !== b && Za(b));
        a.stateNode = null;
        a.return = null;
        a.dependencies = null;
        a.memoizedProps = null;
        a.memoizedState = null;
        a.pendingProps = null;
        a.stateNode = null;
        a.updateQueue = null;
      }
      function Qg(a) {
        return 5 === a.tag || 3 === a.tag || 4 === a.tag;
      }
      function Rg(a) {
        a: for (; ; ) {
          for (; null === a.sibling; ) {
            if (null === a.return || Qg(a.return)) return null;
            a = a.return;
          }
          a.sibling.return = a.return;
          for (a = a.sibling; 5 !== a.tag && 6 !== a.tag && 18 !== a.tag; ) {
            if (a.flags & 2) continue a;
            if (null === a.child || 4 === a.tag) continue a;
            else a.child.return = a, a = a.child;
          }
          if (!(a.flags & 2)) return a.stateNode;
        }
      }
      function Sg(a, b, c) {
        var d = a.tag;
        if (5 === d || 6 === d) a = a.stateNode, b ? pb(c, a, b) : kb(c, a);
        else if (4 !== d && (a = a.child, null !== a)) for (Sg(a, b, c), a = a.sibling; null !== a; ) Sg(a, b, c), a = a.sibling;
      }
      function Tg(a, b, c) {
        var d = a.tag;
        if (5 === d || 6 === d) a = a.stateNode, b ? ob(c, a, b) : jb(c, a);
        else if (4 !== d && (a = a.child, null !== a)) for (Tg(a, b, c), a = a.sibling; null !== a; ) Tg(a, b, c), a = a.sibling;
      }
      var V = null, Ug = false;
      function Vg(a, b, c) {
        for (c = c.child; null !== c; ) Wg(a, b, c), c = c.sibling;
      }
      function Wg(a, b, c) {
        if (Sc && "function" === typeof Sc.onCommitFiberUnmount) try {
          Sc.onCommitFiberUnmount(Rc, c);
        } catch (h) {
        }
        switch (c.tag) {
          case 5:
            S || Ig(c, b);
          case 6:
            if (Ta) {
              var d = V, e = Ug;
              V = null;
              Vg(a, b, c);
              V = d;
              Ug = e;
              null !== V && (Ug ? rb(V, c.stateNode) : qb(V, c.stateNode));
            } else Vg(a, b, c);
            break;
          case 18:
            Ta && null !== V && (Ug ? Yb(V, c.stateNode) : Xb(V, c.stateNode));
            break;
          case 4:
            Ta ? (d = V, e = Ug, V = c.stateNode.containerInfo, Ug = true, Vg(a, b, c), V = d, Ug = e) : (Ua && (d = c.stateNode.containerInfo, e = zb(d), Cb(d, e)), Vg(a, b, c));
            break;
          case 0:
          case 11:
          case 14:
          case 15:
            if (!S && (d = c.updateQueue, null !== d && (d = d.lastEffect, null !== d))) {
              e = d = d.next;
              do {
                var f = e, g = f.destroy;
                f = f.tag;
                void 0 !== g && (0 !== (f & 2) ? Jg(c, b, g) : 0 !== (f & 4) && Jg(c, b, g));
                e = e.next;
              } while (e !== d);
            }
            Vg(a, b, c);
            break;
          case 1:
            if (!S && (Ig(c, b), d = c.stateNode, "function" === typeof d.componentWillUnmount)) try {
              d.props = c.memoizedProps, d.state = c.memoizedState, d.componentWillUnmount();
            } catch (h) {
              U(c, b, h);
            }
            Vg(a, b, c);
            break;
          case 21:
            Vg(a, b, c);
            break;
          case 22:
            c.mode & 1 ? (S = (d = S) || null !== c.memoizedState, Vg(a, b, c), S = d) : Vg(a, b, c);
            break;
          default:
            Vg(
              a,
              b,
              c
            );
        }
      }
      function Xg(a) {
        var b = a.updateQueue;
        if (null !== b) {
          a.updateQueue = null;
          var c = a.stateNode;
          null === c && (c = a.stateNode = new Hg());
          b.forEach(function(b2) {
            var d = Yg.bind(null, a, b2);
            c.has(b2) || (c.add(b2), b2.then(d, d));
          });
        }
      }
      function Zg(a, b) {
        var c = b.deletions;
        if (null !== c) for (var d = 0; d < c.length; d++) {
          var e = c[d];
          try {
            var f = a, g = b;
            if (Ta) {
              var h = g;
              a: for (; null !== h; ) {
                switch (h.tag) {
                  case 5:
                    V = h.stateNode;
                    Ug = false;
                    break a;
                  case 3:
                    V = h.stateNode.containerInfo;
                    Ug = true;
                    break a;
                  case 4:
                    V = h.stateNode.containerInfo;
                    Ug = true;
                    break a;
                }
                h = h.return;
              }
              if (null === V) throw Error(n(160));
              Wg(f, g, e);
              V = null;
              Ug = false;
            } else Wg(f, g, e);
            var k = e.alternate;
            null !== k && (k.return = null);
            e.return = null;
          } catch (l) {
            U(e, b, l);
          }
        }
        if (b.subtreeFlags & 12854) for (b = b.child; null !== b; ) $g(b, a), b = b.sibling;
      }
      function $g(a, b) {
        var c = a.alternate, d = a.flags;
        switch (a.tag) {
          case 0:
          case 11:
          case 14:
          case 15:
            Zg(b, a);
            ah(a);
            if (d & 4) {
              try {
                Mg(3, a, a.return), Ng(3, a);
              } catch (p) {
                U(a, a.return, p);
              }
              try {
                Mg(5, a, a.return);
              } catch (p) {
                U(a, a.return, p);
              }
            }
            break;
          case 1:
            Zg(b, a);
            ah(a);
            d & 512 && null !== c && Ig(c, c.return);
            break;
          case 5:
            Zg(b, a);
            ah(a);
            d & 512 && null !== c && Ig(c, c.return);
            if (Ta) {
              if (a.flags & 32) {
                var e = a.stateNode;
                try {
                  sb(e);
                } catch (p) {
                  U(a, a.return, p);
                }
              }
              if (d & 4 && (e = a.stateNode, null != e)) {
                var f = a.memoizedProps;
                c = null !== c ? c.memoizedProps : f;
                d = a.type;
                b = a.updateQueue;
                a.updateQueue = null;
                if (null !== b) try {
                  nb(e, b, d, c, f, a);
                } catch (p) {
                  U(a, a.return, p);
                }
              }
            }
            break;
          case 6:
            Zg(b, a);
            ah(a);
            if (d & 4 && Ta) {
              if (null === a.stateNode) throw Error(n(162));
              e = a.stateNode;
              f = a.memoizedProps;
              c = null !== c ? c.memoizedProps : f;
              try {
                lb(e, c, f);
              } catch (p) {
                U(a, a.return, p);
              }
            }
            break;
          case 3:
            Zg(b, a);
            ah(a);
            if (d & 4) {
              if (Ta && Va && null !== c && c.memoizedState.isDehydrated) try {
                Vb(b.containerInfo);
              } catch (p) {
                U(a, a.return, p);
              }
              if (Ua) {
                e = b.containerInfo;
                f = b.pendingChildren;
                try {
                  Cb(e, f);
                } catch (p) {
                  U(a, a.return, p);
                }
              }
            }
            break;
          case 4:
            Zg(
              b,
              a
            );
            ah(a);
            if (d & 4 && Ua) {
              f = a.stateNode;
              e = f.containerInfo;
              f = f.pendingChildren;
              try {
                Cb(e, f);
              } catch (p) {
                U(a, a.return, p);
              }
            }
            break;
          case 13:
            Zg(b, a);
            ah(a);
            e = a.child;
            e.flags & 8192 && (f = null !== e.memoizedState, e.stateNode.isHidden = f, !f || null !== e.alternate && null !== e.alternate.memoizedState || (bh = D()));
            d & 4 && Xg(a);
            break;
          case 22:
            var g = null !== c && null !== c.memoizedState;
            a.mode & 1 ? (S = (c = S) || g, Zg(b, a), S = c) : Zg(b, a);
            ah(a);
            if (d & 8192) {
              c = null !== a.memoizedState;
              if ((a.stateNode.isHidden = c) && !g && 0 !== (a.mode & 1)) for (T = a, d = a.child; null !== d; ) {
                for (b = T = d; null !== T; ) {
                  g = T;
                  var h = g.child;
                  switch (g.tag) {
                    case 0:
                    case 11:
                    case 14:
                    case 15:
                      Mg(4, g, g.return);
                      break;
                    case 1:
                      Ig(g, g.return);
                      var k = g.stateNode;
                      if ("function" === typeof k.componentWillUnmount) {
                        var l = g, m = g.return;
                        try {
                          var r = l;
                          k.props = r.memoizedProps;
                          k.state = r.memoizedState;
                          k.componentWillUnmount();
                        } catch (p) {
                          U(l, m, p);
                        }
                      }
                      break;
                    case 5:
                      Ig(g, g.return);
                      break;
                    case 22:
                      if (null !== g.memoizedState) {
                        ch(b);
                        continue;
                      }
                  }
                  null !== h ? (h.return = g, T = h) : ch(b);
                }
                d = d.sibling;
              }
              if (Ta) {
                a: if (d = null, Ta) for (b = a; ; ) {
                  if (5 === b.tag) {
                    if (null === d) {
                      d = b;
                      try {
                        e = b.stateNode, c ? tb(e) : vb(b.stateNode, b.memoizedProps);
                      } catch (p) {
                        U(a, a.return, p);
                      }
                    }
                  } else if (6 === b.tag) {
                    if (null === d) try {
                      f = b.stateNode, c ? ub(f) : wb(f, b.memoizedProps);
                    } catch (p) {
                      U(a, a.return, p);
                    }
                  } else if ((22 !== b.tag && 23 !== b.tag || null === b.memoizedState || b === a) && null !== b.child) {
                    b.child.return = b;
                    b = b.child;
                    continue;
                  }
                  if (b === a) break a;
                  for (; null === b.sibling; ) {
                    if (null === b.return || b.return === a) break a;
                    d === b && (d = null);
                    b = b.return;
                  }
                  d === b && (d = null);
                  b.sibling.return = b.return;
                  b = b.sibling;
                }
              }
            }
            break;
          case 19:
            Zg(b, a);
            ah(a);
            d & 4 && Xg(a);
            break;
          case 21:
            break;
          default:
            Zg(b, a), ah(a);
        }
      }
      function ah(a) {
        var b = a.flags;
        if (b & 2) {
          try {
            if (Ta) {
              b: {
                for (var c = a.return; null !== c; ) {
                  if (Qg(c)) {
                    var d = c;
                    break b;
                  }
                  c = c.return;
                }
                throw Error(n(160));
              }
              switch (d.tag) {
                case 5:
                  var e = d.stateNode;
                  d.flags & 32 && (sb(e), d.flags &= -33);
                  var f = Rg(a);
                  Tg(a, f, e);
                  break;
                case 3:
                case 4:
                  var g = d.stateNode.containerInfo, h = Rg(a);
                  Sg(a, h, g);
                  break;
                default:
                  throw Error(n(161));
              }
            }
          } catch (k) {
            U(a, a.return, k);
          }
          a.flags &= -3;
        }
        b & 4096 && (a.flags &= -4097);
      }
      function dh(a, b, c) {
        T = a;
        eh(a, b, c);
      }
      function eh(a, b, c) {
        for (var d = 0 !== (a.mode & 1); null !== T; ) {
          var e = T, f = e.child;
          if (22 === e.tag && d) {
            var g = null !== e.memoizedState || Gg;
            if (!g) {
              var h = e.alternate, k = null !== h && null !== h.memoizedState || S;
              h = Gg;
              var l = S;
              Gg = g;
              if ((S = k) && !l) for (T = e; null !== T; ) g = T, k = g.child, 22 === g.tag && null !== g.memoizedState ? fh(e) : null !== k ? (k.return = g, T = k) : fh(e);
              for (; null !== f; ) T = f, eh(f, b, c), f = f.sibling;
              T = e;
              Gg = h;
              S = l;
            }
            gh(a, b, c);
          } else 0 !== (e.subtreeFlags & 8772) && null !== f ? (f.return = e, T = f) : gh(a, b, c);
        }
      }
      function gh(a) {
        for (; null !== T; ) {
          var b = T;
          if (0 !== (b.flags & 8772)) {
            var c = b.alternate;
            try {
              if (0 !== (b.flags & 8772)) switch (b.tag) {
                case 0:
                case 11:
                case 15:
                  S || Ng(5, b);
                  break;
                case 1:
                  var d = b.stateNode;
                  if (b.flags & 4 && !S) if (null === c) d.componentDidMount();
                  else {
                    var e = b.elementType === b.type ? c.memoizedProps : xf(b.type, c.memoizedProps);
                    d.componentDidUpdate(e, c.memoizedState, d.__reactInternalSnapshotBeforeUpdate);
                  }
                  var f = b.updateQueue;
                  null !== f && me(b, f, d);
                  break;
                case 3:
                  var g = b.updateQueue;
                  if (null !== g) {
                    c = null;
                    if (null !== b.child) switch (b.child.tag) {
                      case 5:
                        c = Ea(b.child.stateNode);
                        break;
                      case 1:
                        c = b.child.stateNode;
                    }
                    me(b, g, c);
                  }
                  break;
                case 5:
                  var h = b.stateNode;
                  null === c && b.flags & 4 && mb(h, b.type, b.memoizedProps, b);
                  break;
                case 6:
                  break;
                case 4:
                  break;
                case 12:
                  break;
                case 13:
                  if (Va && null === b.memoizedState) {
                    var k = b.alternate;
                    if (null !== k) {
                      var l = k.memoizedState;
                      if (null !== l) {
                        var m = l.dehydrated;
                        null !== m && Wb(m);
                      }
                    }
                  }
                  break;
                case 19:
                case 17:
                case 21:
                case 22:
                case 23:
                case 25:
                  break;
                default:
                  throw Error(n(163));
              }
              S || b.flags & 512 && Og(b);
            } catch (r) {
              U(b, b.return, r);
            }
          }
          if (b === a) {
            T = null;
            break;
          }
          c = b.sibling;
          if (null !== c) {
            c.return = b.return;
            T = c;
            break;
          }
          T = b.return;
        }
      }
      function ch(a) {
        for (; null !== T; ) {
          var b = T;
          if (b === a) {
            T = null;
            break;
          }
          var c = b.sibling;
          if (null !== c) {
            c.return = b.return;
            T = c;
            break;
          }
          T = b.return;
        }
      }
      function fh(a) {
        for (; null !== T; ) {
          var b = T;
          try {
            switch (b.tag) {
              case 0:
              case 11:
              case 15:
                var c = b.return;
                try {
                  Ng(4, b);
                } catch (k) {
                  U(b, c, k);
                }
                break;
              case 1:
                var d = b.stateNode;
                if ("function" === typeof d.componentDidMount) {
                  var e = b.return;
                  try {
                    d.componentDidMount();
                  } catch (k) {
                    U(b, e, k);
                  }
                }
                var f = b.return;
                try {
                  Og(b);
                } catch (k) {
                  U(b, f, k);
                }
                break;
              case 5:
                var g = b.return;
                try {
                  Og(b);
                } catch (k) {
                  U(b, g, k);
                }
            }
          } catch (k) {
            U(b, b.return, k);
          }
          if (b === a) {
            T = null;
            break;
          }
          var h = b.sibling;
          if (null !== h) {
            h.return = b.return;
            T = h;
            break;
          }
          T = b.return;
        }
      }
      var hh = 0, ih = 1, jh = 2, kh = 3, lh = 4;
      if ("function" === typeof Symbol && Symbol.for) {
        var mh = Symbol.for;
        hh = mh("selector.component");
        ih = mh("selector.has_pseudo_class");
        jh = mh("selector.role");
        kh = mh("selector.test_id");
        lh = mh("selector.text");
      }
      function nh(a) {
        var b = Wa(a);
        if (null != b) {
          if ("string" !== typeof b.memoizedProps["data-testname"]) throw Error(n(364));
          return b;
        }
        a = cb(a);
        if (null === a) throw Error(n(362));
        return a.stateNode.current;
      }
      function oh(a, b) {
        switch (b.$$typeof) {
          case hh:
            if (a.type === b.value) return true;
            break;
          case ih:
            a: {
              b = b.value;
              a = [a, 0];
              for (var c = 0; c < a.length; ) {
                var d = a[c++], e = a[c++], f = b[e];
                if (5 !== d.tag || !fb(d)) {
                  for (; null != f && oh(d, f); ) e++, f = b[e];
                  if (e === b.length) {
                    b = true;
                    break a;
                  } else for (d = d.child; null !== d; ) a.push(d, e), d = d.sibling;
                }
              }
              b = false;
            }
            return b;
          case jh:
            if (5 === a.tag && gb(a.stateNode, b.value)) return true;
            break;
          case lh:
            if (5 === a.tag || 6 === a.tag) {
              if (a = eb(a), null !== a && 0 <= a.indexOf(b.value)) return true;
            }
            break;
          case kh:
            if (5 === a.tag && (a = a.memoizedProps["data-testname"], "string" === typeof a && a.toLowerCase() === b.value.toLowerCase())) return true;
            break;
          default:
            throw Error(n(365));
        }
        return false;
      }
      function ph(a) {
        switch (a.$$typeof) {
          case hh:
            return "<" + (ua(a.value) || "Unknown") + ">";
          case ih:
            return ":has(" + (ph(a) || "") + ")";
          case jh:
            return '[role="' + a.value + '"]';
          case lh:
            return '"' + a.value + '"';
          case kh:
            return '[data-testname="' + a.value + '"]';
          default:
            throw Error(n(365));
        }
      }
      function qh(a, b) {
        var c = [];
        a = [a, 0];
        for (var d = 0; d < a.length; ) {
          var e = a[d++], f = a[d++], g = b[f];
          if (5 !== e.tag || !fb(e)) {
            for (; null != g && oh(e, g); ) f++, g = b[f];
            if (f === b.length) c.push(e);
            else for (e = e.child; null !== e; ) a.push(e, f), e = e.sibling;
          }
        }
        return c;
      }
      function rh(a, b) {
        if (!bb) throw Error(n(363));
        a = nh(a);
        a = qh(a, b);
        b = [];
        a = Array.from(a);
        for (var c = 0; c < a.length; ) {
          var d = a[c++];
          if (5 === d.tag) fb(d) || b.push(d.stateNode);
          else for (d = d.child; null !== d; ) a.push(d), d = d.sibling;
        }
        return b;
      }
      var sh = Math.ceil, th = da.ReactCurrentDispatcher, uh = da.ReactCurrentOwner, W = da.ReactCurrentBatchConfig, H = 0, N = null, X = null, Z = 0, $f = 0, Zf = ic(0), R = 0, vh = null, le = 0, wh = 0, xh = 0, yh = null, zh = null, bh = 0, Dg = Infinity, Ah = null;
      function Bh() {
        Dg = D() + 500;
      }
      var Jf = false, Kf = null, Mf = null, Ch = false, Dh = null, Eh = 0, Fh = 0, Gh = null, Hh = -1, Ih = 0;
      function O() {
        return 0 !== (H & 6) ? D() : -1 !== Hh ? Hh : Hh = D();
      }
      function tf(a) {
        if (0 === (a.mode & 1)) return 1;
        if (0 !== (H & 2) && 0 !== Z) return Z & -Z;
        if (null !== Cd.transition) return 0 === Ih && (Ih = Dc()), Ih;
        a = C;
        return 0 !== a ? a : Ya();
      }
      function af(a, b, c, d) {
        if (50 < Fh) throw Fh = 0, Gh = null, Error(n(185));
        Fc(a, c, d);
        if (0 === (H & 2) || a !== N) a === N && (0 === (H & 2) && (wh |= c), 4 === R && Jh(a, Z)), Kh(a, d), 1 === c && 0 === H && 0 === (b.mode & 1) && (Bh(), Xc && ad());
      }
      function Kh(a, b) {
        var c = a.callbackNode;
        Bc(a, b);
        var d = zc(a, a === N ? Z : 0);
        if (0 === d) null !== c && Kc(c), a.callbackNode = null, a.callbackPriority = 0;
        else if (b = d & -d, a.callbackPriority !== b) {
          null != c && Kc(c);
          if (1 === b) 0 === a.tag ? $c(Lh.bind(null, a)) : Zc(Lh.bind(null, a)), $a ? ab(function() {
            0 === (H & 6) && ad();
          }) : Jc(Nc, ad), c = null;
          else {
            switch (Ic(d)) {
              case 1:
                c = Nc;
                break;
              case 4:
                c = Oc;
                break;
              case 16:
                c = Pc;
                break;
              case 536870912:
                c = Qc;
                break;
              default:
                c = Pc;
            }
            c = Mh(c, Nh.bind(null, a));
          }
          a.callbackPriority = b;
          a.callbackNode = c;
        }
      }
      function Nh(a, b) {
        Hh = -1;
        Ih = 0;
        if (0 !== (H & 6)) throw Error(n(327));
        var c = a.callbackNode;
        if (Oh() && a.callbackNode !== c) return null;
        var d = zc(a, a === N ? Z : 0);
        if (0 === d) return null;
        if (0 !== (d & 30) || 0 !== (d & a.expiredLanes) || b) b = Ph(a, d);
        else {
          b = d;
          var e = H;
          H |= 2;
          var f = Qh();
          if (N !== a || Z !== b) Ah = null, Bh(), Rh(a, b);
          do
            try {
              Sh();
              break;
            } catch (h) {
              Th(a, h);
            }
          while (1);
          Ud();
          th.current = f;
          H = e;
          null !== X ? b = 0 : (N = null, Z = 0, b = R);
        }
        if (0 !== b) {
          2 === b && (e = Cc(a), 0 !== e && (d = e, b = Uh(a, e)));
          if (1 === b) throw c = vh, Rh(a, 0), Jh(a, d), Kh(a, D()), c;
          if (6 === b) Jh(a, d);
          else {
            e = a.current.alternate;
            if (0 === (d & 30) && !Vh(e) && (b = Ph(a, d), 2 === b && (f = Cc(a), 0 !== f && (d = f, b = Uh(a, f))), 1 === b)) throw c = vh, Rh(a, 0), Jh(a, d), Kh(a, D()), c;
            a.finishedWork = e;
            a.finishedLanes = d;
            switch (b) {
              case 0:
              case 1:
                throw Error(n(345));
              case 2:
                Wh(a, zh, Ah);
                break;
              case 3:
                Jh(a, d);
                if ((d & 130023424) === d && (b = bh + 500 - D(), 10 < b)) {
                  if (0 !== zc(a, 0)) break;
                  e = a.suspendedLanes;
                  if ((e & d) !== d) {
                    O();
                    a.pingedLanes |= a.suspendedLanes & e;
                    break;
                  }
                  a.timeoutHandle = Pa(Wh.bind(null, a, zh, Ah), b);
                  break;
                }
                Wh(a, zh, Ah);
                break;
              case 4:
                Jh(a, d);
                if ((d & 4194240) === d) break;
                b = a.eventTimes;
                for (e = -1; 0 < d; ) {
                  var g = 31 - tc(d);
                  f = 1 << g;
                  g = b[g];
                  g > e && (e = g);
                  d &= ~f;
                }
                d = e;
                d = D() - d;
                d = (120 > d ? 120 : 480 > d ? 480 : 1080 > d ? 1080 : 1920 > d ? 1920 : 3e3 > d ? 3e3 : 4320 > d ? 4320 : 1960 * sh(d / 1960)) - d;
                if (10 < d) {
                  a.timeoutHandle = Pa(Wh.bind(null, a, zh, Ah), d);
                  break;
                }
                Wh(a, zh, Ah);
                break;
              case 5:
                Wh(a, zh, Ah);
                break;
              default:
                throw Error(n(329));
            }
          }
        }
        Kh(a, D());
        return a.callbackNode === c ? Nh.bind(null, a) : null;
      }
      function Uh(a, b) {
        var c = yh;
        a.current.memoizedState.isDehydrated && (Rh(a, b).flags |= 256);
        a = Ph(a, b);
        2 !== a && (b = zh, zh = c, null !== b && Cg(b));
        return a;
      }
      function Cg(a) {
        null === zh ? zh = a : zh.push.apply(zh, a);
      }
      function Vh(a) {
        for (var b = a; ; ) {
          if (b.flags & 16384) {
            var c = b.updateQueue;
            if (null !== c && (c = c.stores, null !== c)) for (var d = 0; d < c.length; d++) {
              var e = c[d], f = e.getSnapshot;
              e = e.value;
              try {
                if (!Vc(f(), e)) return false;
              } catch (g) {
                return false;
              }
            }
          }
          c = b.child;
          if (b.subtreeFlags & 16384 && null !== c) c.return = b, b = c;
          else {
            if (b === a) break;
            for (; null === b.sibling; ) {
              if (null === b.return || b.return === a) return true;
              b = b.return;
            }
            b.sibling.return = b.return;
            b = b.sibling;
          }
        }
        return true;
      }
      function Jh(a, b) {
        b &= ~xh;
        b &= ~wh;
        a.suspendedLanes |= b;
        a.pingedLanes &= ~b;
        for (a = a.expirationTimes; 0 < b; ) {
          var c = 31 - tc(b), d = 1 << c;
          a[c] = -1;
          b &= ~d;
        }
      }
      function Lh(a) {
        if (0 !== (H & 6)) throw Error(n(327));
        Oh();
        var b = zc(a, 0);
        if (0 === (b & 1)) return Kh(a, D()), null;
        var c = Ph(a, b);
        if (0 !== a.tag && 2 === c) {
          var d = Cc(a);
          0 !== d && (b = d, c = Uh(a, d));
        }
        if (1 === c) throw c = vh, Rh(a, 0), Jh(a, b), Kh(a, D()), c;
        if (6 === c) throw Error(n(345));
        a.finishedWork = a.current.alternate;
        a.finishedLanes = b;
        Wh(a, zh, Ah);
        Kh(a, D());
        return null;
      }
      function Xh(a) {
        null !== Dh && 0 === Dh.tag && 0 === (H & 6) && Oh();
        var b = H;
        H |= 1;
        var c = W.transition, d = C;
        try {
          if (W.transition = null, C = 1, a) return a();
        } finally {
          C = d, W.transition = c, H = b, 0 === (H & 6) && ad();
        }
      }
      function Eg() {
        $f = Zf.current;
        q(Zf);
      }
      function Rh(a, b) {
        a.finishedWork = null;
        a.finishedLanes = 0;
        var c = a.timeoutHandle;
        c !== Ra && (a.timeoutHandle = Ra, Qa(c));
        if (null !== X) for (c = X.return; null !== c; ) {
          var d = c;
          nd(d);
          switch (d.tag) {
            case 1:
              d = d.type.childContextTypes;
              null !== d && void 0 !== d && nc();
              break;
            case 3:
              te();
              q(z);
              q(x);
              ye();
              break;
            case 5:
              ve(d);
              break;
            case 4:
              te();
              break;
            case 13:
              q(I);
              break;
            case 19:
              q(I);
              break;
            case 10:
              Wd(d.type._context);
              break;
            case 22:
            case 23:
              Eg();
          }
          c = c.return;
        }
        N = a;
        X = a = Jd(a.current, null);
        Z = $f = b;
        R = 0;
        vh = null;
        xh = wh = le = 0;
        zh = yh = null;
        if (null !== $d) {
          for (b = 0; b < $d.length; b++) if (c = $d[b], d = c.interleaved, null !== d) {
            c.interleaved = null;
            var e = d.next, f = c.pending;
            if (null !== f) {
              var g = f.next;
              f.next = e;
              d.next = g;
            }
            c.pending = d;
          }
          $d = null;
        }
        return a;
      }
      function Th(a, b) {
        do {
          var c = X;
          try {
            Ud();
            ze.current = Le;
            if (Ce) {
              for (var d = J.memoizedState; null !== d; ) {
                var e = d.queue;
                null !== e && (e.pending = null);
                d = d.next;
              }
              Ce = false;
            }
            Be = 0;
            L = K = J = null;
            De = false;
            Ee = 0;
            uh.current = null;
            if (null === c || null === c.return) {
              R = 1;
              vh = b;
              X = null;
              break;
            }
            a: {
              var f = a, g = c.return, h = c, k = b;
              b = Z;
              h.flags |= 32768;
              if (null !== k && "object" === typeof k && "function" === typeof k.then) {
                var l = k, m = h, r = m.tag;
                if (0 === (m.mode & 1) && (0 === r || 11 === r || 15 === r)) {
                  var p = m.alternate;
                  p ? (m.updateQueue = p.updateQueue, m.memoizedState = p.memoizedState, m.lanes = p.lanes) : (m.updateQueue = null, m.memoizedState = null);
                }
                var B = Pf(g);
                if (null !== B) {
                  B.flags &= -257;
                  Qf(B, g, h, f, b);
                  B.mode & 1 && Nf(f, l, b);
                  b = B;
                  k = l;
                  var w = b.updateQueue;
                  if (null === w) {
                    var Y = /* @__PURE__ */ new Set();
                    Y.add(k);
                    b.updateQueue = Y;
                  } else w.add(k);
                  break a;
                } else {
                  if (0 === (b & 1)) {
                    Nf(f, l, b);
                    ng();
                    break a;
                  }
                  k = Error(n(426));
                }
              } else if (F && h.mode & 1) {
                var ya = Pf(g);
                if (null !== ya) {
                  0 === (ya.flags & 65536) && (ya.flags |= 256);
                  Qf(ya, g, h, f, b);
                  Bd(Ef(k, h));
                  break a;
                }
              }
              f = k = Ef(k, h);
              4 !== R && (R = 2);
              null === yh ? yh = [f] : yh.push(f);
              f = g;
              do {
                switch (f.tag) {
                  case 3:
                    f.flags |= 65536;
                    b &= -b;
                    f.lanes |= b;
                    var E = If(f, k, b);
                    je(f, E);
                    break a;
                  case 1:
                    h = k;
                    var u = f.type, t = f.stateNode;
                    if (0 === (f.flags & 128) && ("function" === typeof u.getDerivedStateFromError || null !== t && "function" === typeof t.componentDidCatch && (null === Mf || !Mf.has(t)))) {
                      f.flags |= 65536;
                      b &= -b;
                      f.lanes |= b;
                      var Db = Lf(f, h, b);
                      je(f, Db);
                      break a;
                    }
                }
                f = f.return;
              } while (null !== f);
            }
            Yh(c);
          } catch (lc) {
            b = lc;
            X === c && null !== c && (X = c = c.return);
            continue;
          }
          break;
        } while (1);
      }
      function Qh() {
        var a = th.current;
        th.current = Le;
        return null === a ? Le : a;
      }
      function ng() {
        if (0 === R || 3 === R || 2 === R) R = 4;
        null === N || 0 === (le & 268435455) && 0 === (wh & 268435455) || Jh(N, Z);
      }
      function Ph(a, b) {
        var c = H;
        H |= 2;
        var d = Qh();
        if (N !== a || Z !== b) Ah = null, Rh(a, b);
        do
          try {
            Zh();
            break;
          } catch (e) {
            Th(a, e);
          }
        while (1);
        Ud();
        H = c;
        th.current = d;
        if (null !== X) throw Error(n(261));
        N = null;
        Z = 0;
        return R;
      }
      function Zh() {
        for (; null !== X; ) $h(X);
      }
      function Sh() {
        for (; null !== X && !Lc(); ) $h(X);
      }
      function $h(a) {
        var b = ai(a.alternate, a, $f);
        a.memoizedProps = a.pendingProps;
        null === b ? Yh(a) : X = b;
        uh.current = null;
      }
      function Yh(a) {
        var b = a;
        do {
          var c = b.alternate;
          a = b.return;
          if (0 === (b.flags & 32768)) {
            if (c = Bg(c, b, $f), null !== c) {
              X = c;
              return;
            }
          } else {
            c = Fg(c, b);
            if (null !== c) {
              c.flags &= 32767;
              X = c;
              return;
            }
            if (null !== a) a.flags |= 32768, a.subtreeFlags = 0, a.deletions = null;
            else {
              R = 6;
              X = null;
              return;
            }
          }
          b = b.sibling;
          if (null !== b) {
            X = b;
            return;
          }
          X = b = a;
        } while (null !== b);
        0 === R && (R = 5);
      }
      function Wh(a, b, c) {
        var d = C, e = W.transition;
        try {
          W.transition = null, C = 1, bi(a, b, c, d);
        } finally {
          W.transition = e, C = d;
        }
        return null;
      }
      function bi(a, b, c, d) {
        do
          Oh();
        while (null !== Dh);
        if (0 !== (H & 6)) throw Error(n(327));
        c = a.finishedWork;
        var e = a.finishedLanes;
        if (null === c) return null;
        a.finishedWork = null;
        a.finishedLanes = 0;
        if (c === a.current) throw Error(n(177));
        a.callbackNode = null;
        a.callbackPriority = 0;
        var f = c.lanes | c.childLanes;
        Gc(a, f);
        a === N && (X = N = null, Z = 0);
        0 === (c.subtreeFlags & 2064) && 0 === (c.flags & 2064) || Ch || (Ch = true, Mh(Pc, function() {
          Oh();
          return null;
        }));
        f = 0 !== (c.flags & 15990);
        if (0 !== (c.subtreeFlags & 15990) || f) {
          f = W.transition;
          W.transition = null;
          var g = C;
          C = 1;
          var h = H;
          H |= 4;
          uh.current = null;
          Lg(a, c);
          $g(c, a);
          Ia(a.containerInfo);
          a.current = c;
          dh(c, a, e);
          Mc();
          H = h;
          C = g;
          W.transition = f;
        } else a.current = c;
        Ch && (Ch = false, Dh = a, Eh = e);
        f = a.pendingLanes;
        0 === f && (Mf = null);
        Tc(c.stateNode, d);
        Kh(a, D());
        if (null !== b) for (d = a.onRecoverableError, c = 0; c < b.length; c++) e = b[c], d(e.value, { componentStack: e.stack, digest: e.digest });
        if (Jf) throw Jf = false, a = Kf, Kf = null, a;
        0 !== (Eh & 1) && 0 !== a.tag && Oh();
        f = a.pendingLanes;
        0 !== (f & 1) ? a === Gh ? Fh++ : (Fh = 0, Gh = a) : Fh = 0;
        ad();
        return null;
      }
      function Oh() {
        if (null !== Dh) {
          var a = Ic(Eh), b = W.transition, c = C;
          try {
            W.transition = null;
            C = 16 > a ? 16 : a;
            if (null === Dh) var d = false;
            else {
              a = Dh;
              Dh = null;
              Eh = 0;
              if (0 !== (H & 6)) throw Error(n(331));
              var e = H;
              H |= 4;
              for (T = a.current; null !== T; ) {
                var f = T, g = f.child;
                if (0 !== (T.flags & 16)) {
                  var h = f.deletions;
                  if (null !== h) {
                    for (var k = 0; k < h.length; k++) {
                      var l = h[k];
                      for (T = l; null !== T; ) {
                        var m = T;
                        switch (m.tag) {
                          case 0:
                          case 11:
                          case 15:
                            Mg(8, m, f);
                        }
                        var r = m.child;
                        if (null !== r) r.return = m, T = r;
                        else for (; null !== T; ) {
                          m = T;
                          var p = m.sibling, B = m.return;
                          Pg(m);
                          if (m === l) {
                            T = null;
                            break;
                          }
                          if (null !== p) {
                            p.return = B;
                            T = p;
                            break;
                          }
                          T = B;
                        }
                      }
                    }
                    var w = f.alternate;
                    if (null !== w) {
                      var Y = w.child;
                      if (null !== Y) {
                        w.child = null;
                        do {
                          var ya = Y.sibling;
                          Y.sibling = null;
                          Y = ya;
                        } while (null !== Y);
                      }
                    }
                    T = f;
                  }
                }
                if (0 !== (f.subtreeFlags & 2064) && null !== g) g.return = f, T = g;
                else b: for (; null !== T; ) {
                  f = T;
                  if (0 !== (f.flags & 2048)) switch (f.tag) {
                    case 0:
                    case 11:
                    case 15:
                      Mg(9, f, f.return);
                  }
                  var E = f.sibling;
                  if (null !== E) {
                    E.return = f.return;
                    T = E;
                    break b;
                  }
                  T = f.return;
                }
              }
              var u = a.current;
              for (T = u; null !== T; ) {
                g = T;
                var t = g.child;
                if (0 !== (g.subtreeFlags & 2064) && null !== t) t.return = g, T = t;
                else b: for (g = u; null !== T; ) {
                  h = T;
                  if (0 !== (h.flags & 2048)) try {
                    switch (h.tag) {
                      case 0:
                      case 11:
                      case 15:
                        Ng(9, h);
                    }
                  } catch (lc) {
                    U(h, h.return, lc);
                  }
                  if (h === g) {
                    T = null;
                    break b;
                  }
                  var Db = h.sibling;
                  if (null !== Db) {
                    Db.return = h.return;
                    T = Db;
                    break b;
                  }
                  T = h.return;
                }
              }
              H = e;
              ad();
              if (Sc && "function" === typeof Sc.onPostCommitFiberRoot) try {
                Sc.onPostCommitFiberRoot(Rc, a);
              } catch (lc) {
              }
              d = true;
            }
            return d;
          } finally {
            C = c, W.transition = b;
          }
        }
        return false;
      }
      function ci(a, b, c) {
        b = Ef(c, b);
        b = If(a, b, 1);
        a = he(a, b, 1);
        b = O();
        null !== a && (Fc(a, 1, b), Kh(a, b));
      }
      function U(a, b, c) {
        if (3 === a.tag) ci(a, a, c);
        else for (; null !== b; ) {
          if (3 === b.tag) {
            ci(b, a, c);
            break;
          } else if (1 === b.tag) {
            var d = b.stateNode;
            if ("function" === typeof b.type.getDerivedStateFromError || "function" === typeof d.componentDidCatch && (null === Mf || !Mf.has(d))) {
              a = Ef(c, a);
              a = Lf(b, a, 1);
              b = he(b, a, 1);
              a = O();
              null !== b && (Fc(b, 1, a), Kh(b, a));
              break;
            }
          }
          b = b.return;
        }
      }
      function Of(a, b, c) {
        var d = a.pingCache;
        null !== d && d.delete(b);
        b = O();
        a.pingedLanes |= a.suspendedLanes & c;
        N === a && (Z & c) === c && (4 === R || 3 === R && (Z & 130023424) === Z && 500 > D() - bh ? Rh(a, 0) : xh |= c);
        Kh(a, b);
      }
      function di(a, b) {
        0 === b && (0 === (a.mode & 1) ? b = 1 : (b = xc, xc <<= 1, 0 === (xc & 130023424) && (xc = 4194304)));
        var c = O();
        a = ce(a, b);
        null !== a && (Fc(a, b, c), Kh(a, c));
      }
      function og(a) {
        var b = a.memoizedState, c = 0;
        null !== b && (c = b.retryLane);
        di(a, c);
      }
      function Yg(a, b) {
        var c = 0;
        switch (a.tag) {
          case 13:
            var d = a.stateNode;
            var e = a.memoizedState;
            null !== e && (c = e.retryLane);
            break;
          case 19:
            d = a.stateNode;
            break;
          default:
            throw Error(n(314));
        }
        null !== d && d.delete(b);
        di(a, c);
      }
      var ai;
      ai = function(a, b, c) {
        if (null !== a) if (a.memoizedProps !== b.pendingProps || z.current) G = true;
        else {
          if (0 === (a.lanes & c) && 0 === (b.flags & 128)) return G = false, sg(a, b, c);
          G = 0 !== (a.flags & 131072) ? true : false;
        }
        else G = false, F && 0 !== (b.flags & 1048576) && ld(b, ed, b.index);
        b.lanes = 0;
        switch (b.tag) {
          case 2:
            var d = b.type;
            cg(a, b);
            a = b.pendingProps;
            var e = mc(b, x.current);
            Yd(b, c);
            e = He(null, b, d, a, e, c);
            var f = Me();
            b.flags |= 1;
            "object" === typeof e && null !== e && "function" === typeof e.render && void 0 === e.$$typeof ? (b.tag = 1, b.memoizedState = null, b.updateQueue = null, A(d) ? (f = true, qc(b)) : f = false, b.memoizedState = null !== e.state && void 0 !== e.state ? e.state : null, ee(b), e.updater = zf, b.stateNode = e, e._reactInternals = b, Df(b, d, a, c), b = dg(null, b, d, true, f, c)) : (b.tag = 0, F && f && md(b), P(null, b, e, c), b = b.child);
            return b;
          case 16:
            d = b.elementType;
            a: {
              cg(a, b);
              a = b.pendingProps;
              e = d._init;
              d = e(d._payload);
              b.type = d;
              e = b.tag = ei(d);
              a = xf(d, a);
              switch (e) {
                case 0:
                  b = Xf(null, b, d, a, c);
                  break a;
                case 1:
                  b = bg(null, b, d, a, c);
                  break a;
                case 11:
                  b = Sf(null, b, d, a, c);
                  break a;
                case 14:
                  b = Uf(null, b, d, xf(d.type, a), c);
                  break a;
              }
              throw Error(n(
                306,
                d,
                ""
              ));
            }
            return b;
          case 0:
            return d = b.type, e = b.pendingProps, e = b.elementType === d ? e : xf(d, e), Xf(a, b, d, e, c);
          case 1:
            return d = b.type, e = b.pendingProps, e = b.elementType === d ? e : xf(d, e), bg(a, b, d, e, c);
          case 3:
            a: {
              eg(b);
              if (null === a) throw Error(n(387));
              d = b.pendingProps;
              f = b.memoizedState;
              e = f.element;
              fe(a, b);
              ke(b, d, null, c);
              var g = b.memoizedState;
              d = g.element;
              if (Va && f.isDehydrated) if (f = { element: d, isDehydrated: false, cache: g.cache, pendingSuspenseBoundaries: g.pendingSuspenseBoundaries, transitions: g.transitions }, b.updateQueue.baseState = f, b.memoizedState = f, b.flags & 256) {
                e = Ef(Error(n(423)), b);
                b = fg(a, b, d, c, e);
                break a;
              } else if (d !== e) {
                e = Ef(Error(n(424)), b);
                b = fg(a, b, d, c, e);
                break a;
              } else for (Va && (pd = Pb(b.stateNode.containerInfo), od = b, F = true, rd = null, qd = false), c = Pd(b, null, d, c), b.child = c; c; ) c.flags = c.flags & -3 | 4096, c = c.sibling;
              else {
                Ad();
                if (d === e) {
                  b = Tf(a, b, c);
                  break a;
                }
                P(a, b, d, c);
              }
              b = b.child;
            }
            return b;
          case 5:
            return ue(b), null === a && wd(b), d = b.type, e = b.pendingProps, f = null !== a ? a.memoizedProps : null, g = e.children, Na(d, e) ? g = null : null !== f && Na(d, f) && (b.flags |= 32), ag(a, b), P(a, b, g, c), b.child;
          case 6:
            return null === a && wd(b), null;
          case 13:
            return ig(a, b, c);
          case 4:
            return se(b, b.stateNode.containerInfo), d = b.pendingProps, null === a ? b.child = Od(b, null, d, c) : P(a, b, d, c), b.child;
          case 11:
            return d = b.type, e = b.pendingProps, e = b.elementType === d ? e : xf(d, e), Sf(a, b, d, e, c);
          case 7:
            return P(a, b, b.pendingProps, c), b.child;
          case 8:
            return P(a, b, b.pendingProps.children, c), b.child;
          case 12:
            return P(a, b, b.pendingProps.children, c), b.child;
          case 10:
            a: {
              d = b.type._context;
              e = b.pendingProps;
              f = b.memoizedProps;
              g = e.value;
              Vd(b, d, g);
              if (null !== f) if (Vc(f.value, g)) {
                if (f.children === e.children && !z.current) {
                  b = Tf(a, b, c);
                  break a;
                }
              } else for (f = b.child, null !== f && (f.return = b); null !== f; ) {
                var h = f.dependencies;
                if (null !== h) {
                  g = f.child;
                  for (var k = h.firstContext; null !== k; ) {
                    if (k.context === d) {
                      if (1 === f.tag) {
                        k = ge(-1, c & -c);
                        k.tag = 2;
                        var l = f.updateQueue;
                        if (null !== l) {
                          l = l.shared;
                          var m = l.pending;
                          null === m ? k.next = k : (k.next = m.next, m.next = k);
                          l.pending = k;
                        }
                      }
                      f.lanes |= c;
                      k = f.alternate;
                      null !== k && (k.lanes |= c);
                      Xd(f.return, c, b);
                      h.lanes |= c;
                      break;
                    }
                    k = k.next;
                  }
                } else if (10 === f.tag) g = f.type === b.type ? null : f.child;
                else if (18 === f.tag) {
                  g = f.return;
                  if (null === g) throw Error(n(341));
                  g.lanes |= c;
                  h = g.alternate;
                  null !== h && (h.lanes |= c);
                  Xd(g, c, b);
                  g = f.sibling;
                } else g = f.child;
                if (null !== g) g.return = f;
                else for (g = f; null !== g; ) {
                  if (g === b) {
                    g = null;
                    break;
                  }
                  f = g.sibling;
                  if (null !== f) {
                    f.return = g.return;
                    g = f;
                    break;
                  }
                  g = g.return;
                }
                f = g;
              }
              P(a, b, e.children, c);
              b = b.child;
            }
            return b;
          case 9:
            return e = b.type, d = b.pendingProps.children, Yd(b, c), e = Zd(e), d = d(e), b.flags |= 1, P(a, b, d, c), b.child;
          case 14:
            return d = b.type, e = xf(d, b.pendingProps), e = xf(d.type, e), Uf(a, b, d, e, c);
          case 15:
            return Wf(a, b, b.type, b.pendingProps, c);
          case 17:
            return d = b.type, e = b.pendingProps, e = b.elementType === d ? e : xf(d, e), cg(a, b), b.tag = 1, A(d) ? (a = true, qc(b)) : a = false, Yd(b, c), Bf(b, d, e), Df(b, d, e, c), dg(null, b, d, true, a, c);
          case 19:
            return rg(a, b, c);
          case 22:
            return Yf(a, b, c);
        }
        throw Error(n(156, b.tag));
      };
      function Mh(a, b) {
        return Jc(a, b);
      }
      function fi(a, b, c, d) {
        this.tag = a;
        this.key = c;
        this.sibling = this.child = this.return = this.stateNode = this.type = this.elementType = null;
        this.index = 0;
        this.ref = null;
        this.pendingProps = b;
        this.dependencies = this.memoizedState = this.updateQueue = this.memoizedProps = null;
        this.mode = d;
        this.subtreeFlags = this.flags = 0;
        this.deletions = null;
        this.childLanes = this.lanes = 0;
        this.alternate = null;
      }
      function td(a, b, c, d) {
        return new fi(a, b, c, d);
      }
      function Vf(a) {
        a = a.prototype;
        return !(!a || !a.isReactComponent);
      }
      function ei(a) {
        if ("function" === typeof a) return Vf(a) ? 1 : 0;
        if (void 0 !== a && null !== a) {
          a = a.$$typeof;
          if (a === ma) return 11;
          if (a === pa) return 14;
        }
        return 2;
      }
      function Jd(a, b) {
        var c = a.alternate;
        null === c ? (c = td(a.tag, b, a.key, a.mode), c.elementType = a.elementType, c.type = a.type, c.stateNode = a.stateNode, c.alternate = a, a.alternate = c) : (c.pendingProps = b, c.type = a.type, c.flags = 0, c.subtreeFlags = 0, c.deletions = null);
        c.flags = a.flags & 14680064;
        c.childLanes = a.childLanes;
        c.lanes = a.lanes;
        c.child = a.child;
        c.memoizedProps = a.memoizedProps;
        c.memoizedState = a.memoizedState;
        c.updateQueue = a.updateQueue;
        b = a.dependencies;
        c.dependencies = null === b ? null : { lanes: b.lanes, firstContext: b.firstContext };
        c.sibling = a.sibling;
        c.index = a.index;
        c.ref = a.ref;
        return c;
      }
      function Ld(a, b, c, d, e, f) {
        var g = 2;
        d = a;
        if ("function" === typeof a) Vf(a) && (g = 1);
        else if ("string" === typeof a) g = 5;
        else a: switch (a) {
          case ha:
            return Nd(c.children, e, f, b);
          case ia:
            g = 8;
            e |= 8;
            break;
          case ja:
            return a = td(12, c, b, e | 2), a.elementType = ja, a.lanes = f, a;
          case na:
            return a = td(13, c, b, e), a.elementType = na, a.lanes = f, a;
          case oa:
            return a = td(19, c, b, e), a.elementType = oa, a.lanes = f, a;
          case ra:
            return jg(c, e, f, b);
          default:
            if ("object" === typeof a && null !== a) switch (a.$$typeof) {
              case ka:
                g = 10;
                break a;
              case la:
                g = 9;
                break a;
              case ma:
                g = 11;
                break a;
              case pa:
                g = 14;
                break a;
              case qa:
                g = 16;
                d = null;
                break a;
            }
            throw Error(n(130, null == a ? a : typeof a, ""));
        }
        b = td(g, c, b, e);
        b.elementType = a;
        b.type = d;
        b.lanes = f;
        return b;
      }
      function Nd(a, b, c, d) {
        a = td(7, a, d, b);
        a.lanes = c;
        return a;
      }
      function jg(a, b, c, d) {
        a = td(22, a, d, b);
        a.elementType = ra;
        a.lanes = c;
        a.stateNode = { isHidden: false };
        return a;
      }
      function Kd(a, b, c) {
        a = td(6, a, null, b);
        a.lanes = c;
        return a;
      }
      function Md(a, b, c) {
        b = td(4, null !== a.children ? a.children : [], a.key, b);
        b.lanes = c;
        b.stateNode = { containerInfo: a.containerInfo, pendingChildren: null, implementation: a.implementation };
        return b;
      }
      function gi(a, b, c, d, e) {
        this.tag = b;
        this.containerInfo = a;
        this.finishedWork = this.pingCache = this.current = this.pendingChildren = null;
        this.timeoutHandle = Ra;
        this.callbackNode = this.pendingContext = this.context = null;
        this.callbackPriority = 0;
        this.eventTimes = Ec(0);
        this.expirationTimes = Ec(-1);
        this.entangledLanes = this.finishedLanes = this.mutableReadLanes = this.expiredLanes = this.pingedLanes = this.suspendedLanes = this.pendingLanes = 0;
        this.entanglements = Ec(0);
        this.identifierPrefix = d;
        this.onRecoverableError = e;
        Va && (this.mutableSourceEagerHydrationData = null);
      }
      function hi(a, b, c, d, e, f, g, h, k) {
        a = new gi(a, b, c, h, k);
        1 === b ? (b = 1, true === f && (b |= 8)) : b = 0;
        f = td(3, null, null, b);
        a.current = f;
        f.stateNode = a;
        f.memoizedState = { element: d, isDehydrated: c, cache: null, transitions: null, pendingSuspenseBoundaries: null };
        ee(f);
        return a;
      }
      function ii(a) {
        if (!a) return jc;
        a = a._reactInternals;
        a: {
          if (wa(a) !== a || 1 !== a.tag) throw Error(n(170));
          var b = a;
          do {
            switch (b.tag) {
              case 3:
                b = b.stateNode.context;
                break a;
              case 1:
                if (A(b.type)) {
                  b = b.stateNode.__reactInternalMemoizedMergedChildContext;
                  break a;
                }
            }
            b = b.return;
          } while (null !== b);
          throw Error(n(171));
        }
        if (1 === a.tag) {
          var c = a.type;
          if (A(c)) return pc(a, c, b);
        }
        return b;
      }
      function ji(a) {
        var b = a._reactInternals;
        if (void 0 === b) {
          if ("function" === typeof a.render) throw Error(n(188));
          a = Object.keys(a).join(",");
          throw Error(n(268, a));
        }
        a = Aa(b);
        return null === a ? null : a.stateNode;
      }
      function ki(a, b) {
        a = a.memoizedState;
        if (null !== a && null !== a.dehydrated) {
          var c = a.retryLane;
          a.retryLane = 0 !== c && c < b ? c : b;
        }
      }
      function li(a, b) {
        ki(a, b);
        (a = a.alternate) && ki(a, b);
      }
      function mi(a) {
        a = Aa(a);
        return null === a ? null : a.stateNode;
      }
      function ni() {
        return null;
      }
      exports2.attemptContinuousHydration = function(a) {
        if (13 === a.tag) {
          var b = ce(a, 134217728);
          if (null !== b) {
            var c = O();
            af(b, a, 134217728, c);
          }
          li(a, 134217728);
        }
      };
      exports2.attemptDiscreteHydration = function(a) {
        if (13 === a.tag) {
          var b = ce(a, 1);
          if (null !== b) {
            var c = O();
            af(b, a, 1, c);
          }
          li(a, 1);
        }
      };
      exports2.attemptHydrationAtCurrentPriority = function(a) {
        if (13 === a.tag) {
          var b = tf(a), c = ce(a, b);
          if (null !== c) {
            var d = O();
            af(c, a, b, d);
          }
          li(a, b);
        }
      };
      exports2.attemptSynchronousHydration = function(a) {
        switch (a.tag) {
          case 3:
            var b = a.stateNode;
            if (b.current.memoizedState.isDehydrated) {
              var c = yc(b.pendingLanes);
              0 !== c && (Hc(b, c | 1), Kh(b, D()), 0 === (H & 6) && (Bh(), ad()));
            }
            break;
          case 13:
            Xh(function() {
              var b2 = ce(a, 1);
              if (null !== b2) {
                var c2 = O();
                af(b2, a, 1, c2);
              }
            }), li(a, 1);
        }
      };
      exports2.batchedUpdates = function(a, b) {
        var c = H;
        H |= 1;
        try {
          return a(b);
        } finally {
          H = c, 0 === H && (Bh(), Xc && ad());
        }
      };
      exports2.createComponentSelector = function(a) {
        return { $$typeof: hh, value: a };
      };
      exports2.createContainer = function(a, b, c, d, e, f, g) {
        return hi(a, b, false, null, c, d, e, f, g);
      };
      exports2.createHasPseudoClassSelector = function(a) {
        return { $$typeof: ih, value: a };
      };
      exports2.createHydrationContainer = function(a, b, c, d, e, f, g, h, k) {
        a = hi(c, d, true, a, e, f, g, h, k);
        a.context = ii(null);
        c = a.current;
        d = O();
        e = tf(c);
        f = ge(d, e);
        f.callback = void 0 !== b && null !== b ? b : null;
        he(c, f, e);
        a.current.lanes = e;
        Fc(a, e, d);
        Kh(a, d);
        return a;
      };
      exports2.createPortal = function(a, b, c) {
        var d = 3 < arguments.length && void 0 !== arguments[3] ? arguments[3] : null;
        return { $$typeof: fa, key: null == d ? null : "" + d, children: a, containerInfo: b, implementation: c };
      };
      exports2.createRoleSelector = function(a) {
        return { $$typeof: jh, value: a };
      };
      exports2.createTestNameSelector = function(a) {
        return { $$typeof: kh, value: a };
      };
      exports2.createTextSelector = function(a) {
        return { $$typeof: lh, value: a };
      };
      exports2.deferredUpdates = function(a) {
        var b = C, c = W.transition;
        try {
          return W.transition = null, C = 16, a();
        } finally {
          C = b, W.transition = c;
        }
      };
      exports2.discreteUpdates = function(a, b, c, d, e) {
        var f = C, g = W.transition;
        try {
          return W.transition = null, C = 1, a(b, c, d, e);
        } finally {
          C = f, W.transition = g, 0 === H && Bh();
        }
      };
      exports2.findAllNodes = rh;
      exports2.findBoundingRects = function(a, b) {
        if (!bb) throw Error(n(363));
        b = rh(a, b);
        a = [];
        for (var c = 0; c < b.length; c++) a.push(db(b[c]));
        for (b = a.length - 1; 0 < b; b--) {
          c = a[b];
          for (var d = c.x, e = d + c.width, f = c.y, g = f + c.height, h = b - 1; 0 <= h; h--) if (b !== h) {
            var k = a[h], l = k.x, m = l + k.width, r = k.y, p = r + k.height;
            if (d >= l && f >= r && e <= m && g <= p) {
              a.splice(b, 1);
              break;
            } else if (!(d !== l || c.width !== k.width || p < f || r > g)) {
              r > f && (k.height += r - f, k.y = f);
              p < g && (k.height = g - r);
              a.splice(b, 1);
              break;
            } else if (!(f !== r || c.height !== k.height || m < d || l > e)) {
              l > d && (k.width += l - d, k.x = d);
              m < e && (k.width = e - l);
              a.splice(b, 1);
              break;
            }
          }
        }
        return a;
      };
      exports2.findHostInstance = ji;
      exports2.findHostInstanceWithNoPortals = function(a) {
        a = za(a);
        a = null !== a ? Ca(a) : null;
        return null === a ? null : a.stateNode;
      };
      exports2.findHostInstanceWithWarning = function(a) {
        return ji(a);
      };
      exports2.flushControlled = function(a) {
        var b = H;
        H |= 1;
        var c = W.transition, d = C;
        try {
          W.transition = null, C = 1, a();
        } finally {
          C = d, W.transition = c, H = b, 0 === H && (Bh(), ad());
        }
      };
      exports2.flushPassiveEffects = Oh;
      exports2.flushSync = Xh;
      exports2.focusWithin = function(a, b) {
        if (!bb) throw Error(n(363));
        a = nh(a);
        b = qh(a, b);
        b = Array.from(b);
        for (a = 0; a < b.length; ) {
          var c = b[a++];
          if (!fb(c)) {
            if (5 === c.tag && hb(c.stateNode)) return true;
            for (c = c.child; null !== c; ) b.push(c), c = c.sibling;
          }
        }
        return false;
      };
      exports2.getCurrentUpdatePriority = function() {
        return C;
      };
      exports2.getFindAllNodesFailureDescription = function(a, b) {
        if (!bb) throw Error(n(363));
        var c = 0, d = [];
        a = [nh(a), 0];
        for (var e = 0; e < a.length; ) {
          var f = a[e++], g = a[e++], h = b[g];
          if (5 !== f.tag || !fb(f)) {
            if (oh(f, h) && (d.push(ph(h)), g++, g > c && (c = g)), g < b.length) for (f = f.child; null !== f; ) a.push(f, g), f = f.sibling;
          }
        }
        if (c < b.length) {
          for (a = []; c < b.length; c++) a.push(ph(b[c]));
          return "findAllNodes was able to match part of the selector:\n  " + (d.join(" > ") + "\n\nNo matching component was found for:\n  ") + a.join(" > ");
        }
        return null;
      };
      exports2.getPublicRootInstance = function(a) {
        a = a.current;
        if (!a.child) return null;
        switch (a.child.tag) {
          case 5:
            return Ea(a.child.stateNode);
          default:
            return a.child.stateNode;
        }
      };
      exports2.injectIntoDevTools = function(a) {
        a = { bundleType: a.bundleType, version: a.version, rendererPackageName: a.rendererPackageName, rendererConfig: a.rendererConfig, overrideHookState: null, overrideHookStateDeletePath: null, overrideHookStateRenamePath: null, overrideProps: null, overridePropsDeletePath: null, overridePropsRenamePath: null, setErrorHandler: null, setSuspenseHandler: null, scheduleUpdate: null, currentDispatcherRef: da.ReactCurrentDispatcher, findHostInstanceByFiber: mi, findFiberByHostInstance: a.findFiberByHostInstance || ni, findHostInstancesForRefresh: null, scheduleRefresh: null, scheduleRoot: null, setRefreshHandler: null, getCurrentFiber: null, reconcilerVersion: "18.3.1" };
        if ("undefined" === typeof __REACT_DEVTOOLS_GLOBAL_HOOK__) a = false;
        else {
          var b = __REACT_DEVTOOLS_GLOBAL_HOOK__;
          if (b.isDisabled || !b.supportsFiber) a = true;
          else {
            try {
              Rc = b.inject(a), Sc = b;
            } catch (c) {
            }
            a = b.checkDCE ? true : false;
          }
        }
        return a;
      };
      exports2.isAlreadyRendering = function() {
        return false;
      };
      exports2.observeVisibleRects = function(a, b, c, d) {
        if (!bb) throw Error(n(363));
        a = rh(a, b);
        var e = ib(a, c, d).disconnect;
        return { disconnect: function() {
          e();
        } };
      };
      exports2.registerMutableSourceForHydration = function(a, b) {
        var c = b._getVersion;
        c = c(b._source);
        null == a.mutableSourceEagerHydrationData ? a.mutableSourceEagerHydrationData = [b, c] : a.mutableSourceEagerHydrationData.push(b, c);
      };
      exports2.runWithPriority = function(a, b) {
        var c = C;
        try {
          return C = a, b();
        } finally {
          C = c;
        }
      };
      exports2.shouldError = function() {
        return null;
      };
      exports2.shouldSuspend = function() {
        return false;
      };
      exports2.updateContainer = function(a, b, c, d) {
        var e = b.current, f = O(), g = tf(e);
        c = ii(c);
        null === b.context ? b.context = c : b.pendingContext = c;
        b = ge(f, g);
        b.payload = { element: a };
        d = void 0 === d ? null : d;
        null !== d && (b.callback = d);
        a = he(e, b, g);
        null !== a && (af(a, e, g, f), ie(a, e, g));
        return g;
      };
      return exports2;
    };
  }
});

// node_modules/react-reconciler/index.js
var require_react_reconciler = __commonJS({
  "node_modules/react-reconciler/index.js"(exports, module) {
    "use strict";
    if (true) {
      module.exports = require_react_reconciler_production_min();
    } else {
      module.exports = null;
    }
  }
});

// node_modules/react-reconciler/cjs/react-reconciler-constants.production.min.js
var require_react_reconciler_constants_production_min = __commonJS({
  "node_modules/react-reconciler/cjs/react-reconciler-constants.production.min.js"(exports) {
    "use strict";
    exports.ConcurrentRoot = 1;
    exports.ContinuousEventPriority = 4;
    exports.DefaultEventPriority = 16;
    exports.DiscreteEventPriority = 1;
    exports.IdleEventPriority = 536870912;
    exports.LegacyRoot = 0;
  }
});

// node_modules/react-reconciler/constants.js
var require_constants = __commonJS({
  "node_modules/react-reconciler/constants.js"(exports, module) {
    "use strict";
    if (true) {
      module.exports = require_react_reconciler_constants_production_min();
    } else {
      module.exports = null;
    }
  }
});

// node_modules/ws/lib/constants.js
var require_constants2 = __commonJS({
  "node_modules/ws/lib/constants.js"(exports, module) {
    "use strict";
    var BINARY_TYPES = ["nodebuffer", "arraybuffer", "fragments"];
    var hasBlob = typeof Blob !== "undefined";
    if (hasBlob) BINARY_TYPES.push("blob");
    module.exports = {
      BINARY_TYPES,
      CLOSE_TIMEOUT: 3e4,
      EMPTY_BUFFER: Buffer.alloc(0),
      GUID: "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
      hasBlob,
      kForOnEventAttribute: /* @__PURE__ */ Symbol("kIsForOnEventAttribute"),
      kListener: /* @__PURE__ */ Symbol("kListener"),
      kStatusCode: /* @__PURE__ */ Symbol("status-code"),
      kWebSocket: /* @__PURE__ */ Symbol("websocket"),
      NOOP: () => {
      }
    };
  }
});

// node_modules/ws/lib/buffer-util.js
var require_buffer_util = __commonJS({
  "node_modules/ws/lib/buffer-util.js"(exports, module) {
    "use strict";
    var { EMPTY_BUFFER } = require_constants2();
    var FastBuffer = Buffer[Symbol.species];
    function concat(list, totalLength) {
      if (list.length === 0) return EMPTY_BUFFER;
      if (list.length === 1) return list[0];
      const target = Buffer.allocUnsafe(totalLength);
      let offset = 0;
      for (let i = 0; i < list.length; i++) {
        const buf = list[i];
        target.set(buf, offset);
        offset += buf.length;
      }
      if (offset < totalLength) {
        return new FastBuffer(target.buffer, target.byteOffset, offset);
      }
      return target;
    }
    function _mask(source, mask, output, offset, length) {
      for (let i = 0; i < length; i++) {
        output[offset + i] = source[i] ^ mask[i & 3];
      }
    }
    function _unmask(buffer, mask) {
      for (let i = 0; i < buffer.length; i++) {
        buffer[i] ^= mask[i & 3];
      }
    }
    function toArrayBuffer(buf) {
      if (buf.length === buf.buffer.byteLength) {
        return buf.buffer;
      }
      return buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.length);
    }
    function toBuffer(data) {
      toBuffer.readOnly = true;
      if (Buffer.isBuffer(data)) return data;
      let buf;
      if (data instanceof ArrayBuffer) {
        buf = new FastBuffer(data);
      } else if (ArrayBuffer.isView(data)) {
        buf = new FastBuffer(data.buffer, data.byteOffset, data.byteLength);
      } else {
        buf = Buffer.from(data);
        toBuffer.readOnly = false;
      }
      return buf;
    }
    module.exports = {
      concat,
      mask: _mask,
      toArrayBuffer,
      toBuffer,
      unmask: _unmask
    };
    if (!process.env.WS_NO_BUFFER_UTIL) {
      try {
        const bufferUtil = __require("bufferutil");
        module.exports.mask = function(source, mask, output, offset, length) {
          if (length < 48) _mask(source, mask, output, offset, length);
          else bufferUtil.mask(source, mask, output, offset, length);
        };
        module.exports.unmask = function(buffer, mask) {
          if (buffer.length < 32) _unmask(buffer, mask);
          else bufferUtil.unmask(buffer, mask);
        };
      } catch (e) {
      }
    }
  }
});

// node_modules/ws/lib/limiter.js
var require_limiter = __commonJS({
  "node_modules/ws/lib/limiter.js"(exports, module) {
    "use strict";
    var kDone = /* @__PURE__ */ Symbol("kDone");
    var kRun = /* @__PURE__ */ Symbol("kRun");
    var Limiter = class {
      /**
       * Creates a new `Limiter`.
       *
       * @param {Number} [concurrency=Infinity] The maximum number of jobs allowed
       *     to run concurrently
       */
      constructor(concurrency) {
        this[kDone] = () => {
          this.pending--;
          this[kRun]();
        };
        this.concurrency = concurrency || Infinity;
        this.jobs = [];
        this.pending = 0;
      }
      /**
       * Adds a job to the queue.
       *
       * @param {Function} job The job to run
       * @public
       */
      add(job) {
        this.jobs.push(job);
        this[kRun]();
      }
      /**
       * Removes a job from the queue and runs it if possible.
       *
       * @private
       */
      [kRun]() {
        if (this.pending === this.concurrency) return;
        if (this.jobs.length) {
          const job = this.jobs.shift();
          this.pending++;
          job(this[kDone]);
        }
      }
    };
    module.exports = Limiter;
  }
});

// node_modules/ws/lib/permessage-deflate.js
var require_permessage_deflate = __commonJS({
  "node_modules/ws/lib/permessage-deflate.js"(exports, module) {
    "use strict";
    var zlib = __require("zlib");
    var bufferUtil = require_buffer_util();
    var Limiter = require_limiter();
    var { kStatusCode } = require_constants2();
    var FastBuffer = Buffer[Symbol.species];
    var TRAILER = Buffer.from([0, 0, 255, 255]);
    var kPerMessageDeflate = /* @__PURE__ */ Symbol("permessage-deflate");
    var kTotalLength = /* @__PURE__ */ Symbol("total-length");
    var kCallback = /* @__PURE__ */ Symbol("callback");
    var kBuffers = /* @__PURE__ */ Symbol("buffers");
    var kError = /* @__PURE__ */ Symbol("error");
    var zlibLimiter;
    var PerMessageDeflate2 = class {
      /**
       * Creates a PerMessageDeflate instance.
       *
       * @param {Object} [options] Configuration options
       * @param {(Boolean|Number)} [options.clientMaxWindowBits] Advertise support
       *     for, or request, a custom client window size
       * @param {Boolean} [options.clientNoContextTakeover=false] Advertise/
       *     acknowledge disabling of client context takeover
       * @param {Number} [options.concurrencyLimit=10] The number of concurrent
       *     calls to zlib
       * @param {Boolean} [options.isServer=false] Create the instance in either
       *     server or client mode
       * @param {Number} [options.maxPayload=0] The maximum allowed message length
       * @param {(Boolean|Number)} [options.serverMaxWindowBits] Request/confirm the
       *     use of a custom server window size
       * @param {Boolean} [options.serverNoContextTakeover=false] Request/accept
       *     disabling of server context takeover
       * @param {Number} [options.threshold=1024] Size (in bytes) below which
       *     messages should not be compressed if context takeover is disabled
       * @param {Object} [options.zlibDeflateOptions] Options to pass to zlib on
       *     deflate
       * @param {Object} [options.zlibInflateOptions] Options to pass to zlib on
       *     inflate
       */
      constructor(options) {
        this._options = options || {};
        this._threshold = this._options.threshold !== void 0 ? this._options.threshold : 1024;
        this._maxPayload = this._options.maxPayload | 0;
        this._isServer = !!this._options.isServer;
        this._deflate = null;
        this._inflate = null;
        this.params = null;
        if (!zlibLimiter) {
          const concurrency = this._options.concurrencyLimit !== void 0 ? this._options.concurrencyLimit : 10;
          zlibLimiter = new Limiter(concurrency);
        }
      }
      /**
       * @type {String}
       */
      static get extensionName() {
        return "permessage-deflate";
      }
      /**
       * Create an extension negotiation offer.
       *
       * @return {Object} Extension parameters
       * @public
       */
      offer() {
        const params = {};
        if (this._options.serverNoContextTakeover) {
          params.server_no_context_takeover = true;
        }
        if (this._options.clientNoContextTakeover) {
          params.client_no_context_takeover = true;
        }
        if (this._options.serverMaxWindowBits) {
          params.server_max_window_bits = this._options.serverMaxWindowBits;
        }
        if (this._options.clientMaxWindowBits) {
          params.client_max_window_bits = this._options.clientMaxWindowBits;
        } else if (this._options.clientMaxWindowBits == null) {
          params.client_max_window_bits = true;
        }
        return params;
      }
      /**
       * Accept an extension negotiation offer/response.
       *
       * @param {Array} configurations The extension negotiation offers/reponse
       * @return {Object} Accepted configuration
       * @public
       */
      accept(configurations) {
        configurations = this.normalizeParams(configurations);
        this.params = this._isServer ? this.acceptAsServer(configurations) : this.acceptAsClient(configurations);
        return this.params;
      }
      /**
       * Releases all resources used by the extension.
       *
       * @public
       */
      cleanup() {
        if (this._inflate) {
          this._inflate.close();
          this._inflate = null;
        }
        if (this._deflate) {
          const callback = this._deflate[kCallback];
          this._deflate.close();
          this._deflate = null;
          if (callback) {
            callback(
              new Error(
                "The deflate stream was closed while data was being processed"
              )
            );
          }
        }
      }
      /**
       *  Accept an extension negotiation offer.
       *
       * @param {Array} offers The extension negotiation offers
       * @return {Object} Accepted configuration
       * @private
       */
      acceptAsServer(offers) {
        const opts = this._options;
        const accepted = offers.find((params) => {
          if (opts.serverNoContextTakeover === false && params.server_no_context_takeover || params.server_max_window_bits && (opts.serverMaxWindowBits === false || typeof opts.serverMaxWindowBits === "number" && opts.serverMaxWindowBits > params.server_max_window_bits) || typeof opts.clientMaxWindowBits === "number" && !params.client_max_window_bits) {
            return false;
          }
          return true;
        });
        if (!accepted) {
          throw new Error("None of the extension offers can be accepted");
        }
        if (opts.serverNoContextTakeover) {
          accepted.server_no_context_takeover = true;
        }
        if (opts.clientNoContextTakeover) {
          accepted.client_no_context_takeover = true;
        }
        if (typeof opts.serverMaxWindowBits === "number") {
          accepted.server_max_window_bits = opts.serverMaxWindowBits;
        }
        if (typeof opts.clientMaxWindowBits === "number") {
          accepted.client_max_window_bits = opts.clientMaxWindowBits;
        } else if (accepted.client_max_window_bits === true || opts.clientMaxWindowBits === false) {
          delete accepted.client_max_window_bits;
        }
        return accepted;
      }
      /**
       * Accept the extension negotiation response.
       *
       * @param {Array} response The extension negotiation response
       * @return {Object} Accepted configuration
       * @private
       */
      acceptAsClient(response) {
        const params = response[0];
        if (this._options.clientNoContextTakeover === false && params.client_no_context_takeover) {
          throw new Error('Unexpected parameter "client_no_context_takeover"');
        }
        if (!params.client_max_window_bits) {
          if (typeof this._options.clientMaxWindowBits === "number") {
            params.client_max_window_bits = this._options.clientMaxWindowBits;
          }
        } else if (this._options.clientMaxWindowBits === false || typeof this._options.clientMaxWindowBits === "number" && params.client_max_window_bits > this._options.clientMaxWindowBits) {
          throw new Error(
            'Unexpected or invalid parameter "client_max_window_bits"'
          );
        }
        return params;
      }
      /**
       * Normalize parameters.
       *
       * @param {Array} configurations The extension negotiation offers/reponse
       * @return {Array} The offers/response with normalized parameters
       * @private
       */
      normalizeParams(configurations) {
        configurations.forEach((params) => {
          Object.keys(params).forEach((key) => {
            let value = params[key];
            if (value.length > 1) {
              throw new Error(`Parameter "${key}" must have only a single value`);
            }
            value = value[0];
            if (key === "client_max_window_bits") {
              if (value !== true) {
                const num = +value;
                if (!Number.isInteger(num) || num < 8 || num > 15) {
                  throw new TypeError(
                    `Invalid value for parameter "${key}": ${value}`
                  );
                }
                value = num;
              } else if (!this._isServer) {
                throw new TypeError(
                  `Invalid value for parameter "${key}": ${value}`
                );
              }
            } else if (key === "server_max_window_bits") {
              const num = +value;
              if (!Number.isInteger(num) || num < 8 || num > 15) {
                throw new TypeError(
                  `Invalid value for parameter "${key}": ${value}`
                );
              }
              value = num;
            } else if (key === "client_no_context_takeover" || key === "server_no_context_takeover") {
              if (value !== true) {
                throw new TypeError(
                  `Invalid value for parameter "${key}": ${value}`
                );
              }
            } else {
              throw new Error(`Unknown parameter "${key}"`);
            }
            params[key] = value;
          });
        });
        return configurations;
      }
      /**
       * Decompress data. Concurrency limited.
       *
       * @param {Buffer} data Compressed data
       * @param {Boolean} fin Specifies whether or not this is the last fragment
       * @param {Function} callback Callback
       * @public
       */
      decompress(data, fin, callback) {
        zlibLimiter.add((done) => {
          this._decompress(data, fin, (err, result) => {
            done();
            callback(err, result);
          });
        });
      }
      /**
       * Compress data. Concurrency limited.
       *
       * @param {(Buffer|String)} data Data to compress
       * @param {Boolean} fin Specifies whether or not this is the last fragment
       * @param {Function} callback Callback
       * @public
       */
      compress(data, fin, callback) {
        zlibLimiter.add((done) => {
          this._compress(data, fin, (err, result) => {
            done();
            callback(err, result);
          });
        });
      }
      /**
       * Decompress data.
       *
       * @param {Buffer} data Compressed data
       * @param {Boolean} fin Specifies whether or not this is the last fragment
       * @param {Function} callback Callback
       * @private
       */
      _decompress(data, fin, callback) {
        const endpoint = this._isServer ? "client" : "server";
        if (!this._inflate) {
          const key = `${endpoint}_max_window_bits`;
          const windowBits = typeof this.params[key] !== "number" ? zlib.Z_DEFAULT_WINDOWBITS : this.params[key];
          this._inflate = zlib.createInflateRaw({
            ...this._options.zlibInflateOptions,
            windowBits
          });
          this._inflate[kPerMessageDeflate] = this;
          this._inflate[kTotalLength] = 0;
          this._inflate[kBuffers] = [];
          this._inflate.on("error", inflateOnError);
          this._inflate.on("data", inflateOnData);
        }
        this._inflate[kCallback] = callback;
        this._inflate.write(data);
        if (fin) this._inflate.write(TRAILER);
        this._inflate.flush(() => {
          const err = this._inflate[kError];
          if (err) {
            this._inflate.close();
            this._inflate = null;
            callback(err);
            return;
          }
          const data2 = bufferUtil.concat(
            this._inflate[kBuffers],
            this._inflate[kTotalLength]
          );
          if (this._inflate._readableState.endEmitted) {
            this._inflate.close();
            this._inflate = null;
          } else {
            this._inflate[kTotalLength] = 0;
            this._inflate[kBuffers] = [];
            if (fin && this.params[`${endpoint}_no_context_takeover`]) {
              this._inflate.reset();
            }
          }
          callback(null, data2);
        });
      }
      /**
       * Compress data.
       *
       * @param {(Buffer|String)} data Data to compress
       * @param {Boolean} fin Specifies whether or not this is the last fragment
       * @param {Function} callback Callback
       * @private
       */
      _compress(data, fin, callback) {
        const endpoint = this._isServer ? "server" : "client";
        if (!this._deflate) {
          const key = `${endpoint}_max_window_bits`;
          const windowBits = typeof this.params[key] !== "number" ? zlib.Z_DEFAULT_WINDOWBITS : this.params[key];
          this._deflate = zlib.createDeflateRaw({
            ...this._options.zlibDeflateOptions,
            windowBits
          });
          this._deflate[kTotalLength] = 0;
          this._deflate[kBuffers] = [];
          this._deflate.on("data", deflateOnData);
        }
        this._deflate[kCallback] = callback;
        this._deflate.write(data);
        this._deflate.flush(zlib.Z_SYNC_FLUSH, () => {
          if (!this._deflate) {
            return;
          }
          let data2 = bufferUtil.concat(
            this._deflate[kBuffers],
            this._deflate[kTotalLength]
          );
          if (fin) {
            data2 = new FastBuffer(data2.buffer, data2.byteOffset, data2.length - 4);
          }
          this._deflate[kCallback] = null;
          this._deflate[kTotalLength] = 0;
          this._deflate[kBuffers] = [];
          if (fin && this.params[`${endpoint}_no_context_takeover`]) {
            this._deflate.reset();
          }
          callback(null, data2);
        });
      }
    };
    module.exports = PerMessageDeflate2;
    function deflateOnData(chunk) {
      this[kBuffers].push(chunk);
      this[kTotalLength] += chunk.length;
    }
    function inflateOnData(chunk) {
      this[kTotalLength] += chunk.length;
      if (this[kPerMessageDeflate]._maxPayload < 1 || this[kTotalLength] <= this[kPerMessageDeflate]._maxPayload) {
        this[kBuffers].push(chunk);
        return;
      }
      this[kError] = new RangeError("Max payload size exceeded");
      this[kError].code = "WS_ERR_UNSUPPORTED_MESSAGE_LENGTH";
      this[kError][kStatusCode] = 1009;
      this.removeListener("data", inflateOnData);
      this.reset();
    }
    function inflateOnError(err) {
      this[kPerMessageDeflate]._inflate = null;
      if (this[kError]) {
        this[kCallback](this[kError]);
        return;
      }
      err[kStatusCode] = 1007;
      this[kCallback](err);
    }
  }
});

// node_modules/ws/lib/validation.js
var require_validation = __commonJS({
  "node_modules/ws/lib/validation.js"(exports, module) {
    "use strict";
    var { isUtf8 } = __require("buffer");
    var { hasBlob } = require_constants2();
    var tokenChars = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      // 0 - 15
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      // 16 - 31
      0,
      1,
      0,
      1,
      1,
      1,
      1,
      1,
      0,
      0,
      1,
      1,
      0,
      1,
      1,
      0,
      // 32 - 47
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      // 48 - 63
      0,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      // 64 - 79
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      0,
      0,
      0,
      1,
      1,
      // 80 - 95
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      // 96 - 111
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      0,
      1,
      0,
      1,
      0
      // 112 - 127
    ];
    function isValidStatusCode(code) {
      return code >= 1e3 && code <= 1014 && code !== 1004 && code !== 1005 && code !== 1006 || code >= 3e3 && code <= 4999;
    }
    function _isValidUTF8(buf) {
      const len = buf.length;
      let i = 0;
      while (i < len) {
        if ((buf[i] & 128) === 0) {
          i++;
        } else if ((buf[i] & 224) === 192) {
          if (i + 1 === len || (buf[i + 1] & 192) !== 128 || (buf[i] & 254) === 192) {
            return false;
          }
          i += 2;
        } else if ((buf[i] & 240) === 224) {
          if (i + 2 >= len || (buf[i + 1] & 192) !== 128 || (buf[i + 2] & 192) !== 128 || buf[i] === 224 && (buf[i + 1] & 224) === 128 || // Overlong
          buf[i] === 237 && (buf[i + 1] & 224) === 160) {
            return false;
          }
          i += 3;
        } else if ((buf[i] & 248) === 240) {
          if (i + 3 >= len || (buf[i + 1] & 192) !== 128 || (buf[i + 2] & 192) !== 128 || (buf[i + 3] & 192) !== 128 || buf[i] === 240 && (buf[i + 1] & 240) === 128 || // Overlong
          buf[i] === 244 && buf[i + 1] > 143 || buf[i] > 244) {
            return false;
          }
          i += 4;
        } else {
          return false;
        }
      }
      return true;
    }
    function isBlob(value) {
      return hasBlob && typeof value === "object" && typeof value.arrayBuffer === "function" && typeof value.type === "string" && typeof value.stream === "function" && (value[Symbol.toStringTag] === "Blob" || value[Symbol.toStringTag] === "File");
    }
    module.exports = {
      isBlob,
      isValidStatusCode,
      isValidUTF8: _isValidUTF8,
      tokenChars
    };
    if (isUtf8) {
      module.exports.isValidUTF8 = function(buf) {
        return buf.length < 24 ? _isValidUTF8(buf) : isUtf8(buf);
      };
    } else if (!process.env.WS_NO_UTF_8_VALIDATE) {
      try {
        const isValidUTF8 = __require("utf-8-validate");
        module.exports.isValidUTF8 = function(buf) {
          return buf.length < 32 ? _isValidUTF8(buf) : isValidUTF8(buf);
        };
      } catch (e) {
      }
    }
  }
});

// node_modules/ws/lib/receiver.js
var require_receiver = __commonJS({
  "node_modules/ws/lib/receiver.js"(exports, module) {
    "use strict";
    var { Writable } = __require("stream");
    var PerMessageDeflate2 = require_permessage_deflate();
    var {
      BINARY_TYPES,
      EMPTY_BUFFER,
      kStatusCode,
      kWebSocket
    } = require_constants2();
    var { concat, toArrayBuffer, unmask } = require_buffer_util();
    var { isValidStatusCode, isValidUTF8 } = require_validation();
    var FastBuffer = Buffer[Symbol.species];
    var GET_INFO = 0;
    var GET_PAYLOAD_LENGTH_16 = 1;
    var GET_PAYLOAD_LENGTH_64 = 2;
    var GET_MASK = 3;
    var GET_DATA = 4;
    var INFLATING = 5;
    var DEFER_EVENT = 6;
    var Receiver2 = class extends Writable {
      /**
       * Creates a Receiver instance.
       *
       * @param {Object} [options] Options object
       * @param {Boolean} [options.allowSynchronousEvents=true] Specifies whether
       *     any of the `'message'`, `'ping'`, and `'pong'` events can be emitted
       *     multiple times in the same tick
       * @param {String} [options.binaryType=nodebuffer] The type for binary data
       * @param {Object} [options.extensions] An object containing the negotiated
       *     extensions
       * @param {Boolean} [options.isServer=false] Specifies whether to operate in
       *     client or server mode
       * @param {Number} [options.maxPayload=0] The maximum allowed message length
       * @param {Boolean} [options.skipUTF8Validation=false] Specifies whether or
       *     not to skip UTF-8 validation for text and close messages
       */
      constructor(options = {}) {
        super();
        this._allowSynchronousEvents = options.allowSynchronousEvents !== void 0 ? options.allowSynchronousEvents : true;
        this._binaryType = options.binaryType || BINARY_TYPES[0];
        this._extensions = options.extensions || {};
        this._isServer = !!options.isServer;
        this._maxPayload = options.maxPayload | 0;
        this._skipUTF8Validation = !!options.skipUTF8Validation;
        this[kWebSocket] = void 0;
        this._bufferedBytes = 0;
        this._buffers = [];
        this._compressed = false;
        this._payloadLength = 0;
        this._mask = void 0;
        this._fragmented = 0;
        this._masked = false;
        this._fin = false;
        this._opcode = 0;
        this._totalPayloadLength = 0;
        this._messageLength = 0;
        this._fragments = [];
        this._errored = false;
        this._loop = false;
        this._state = GET_INFO;
      }
      /**
       * Implements `Writable.prototype._write()`.
       *
       * @param {Buffer} chunk The chunk of data to write
       * @param {String} encoding The character encoding of `chunk`
       * @param {Function} cb Callback
       * @private
       */
      _write(chunk, encoding, cb) {
        if (this._opcode === 8 && this._state == GET_INFO) return cb();
        this._bufferedBytes += chunk.length;
        this._buffers.push(chunk);
        this.startLoop(cb);
      }
      /**
       * Consumes `n` bytes from the buffered data.
       *
       * @param {Number} n The number of bytes to consume
       * @return {Buffer} The consumed bytes
       * @private
       */
      consume(n) {
        this._bufferedBytes -= n;
        if (n === this._buffers[0].length) return this._buffers.shift();
        if (n < this._buffers[0].length) {
          const buf = this._buffers[0];
          this._buffers[0] = new FastBuffer(
            buf.buffer,
            buf.byteOffset + n,
            buf.length - n
          );
          return new FastBuffer(buf.buffer, buf.byteOffset, n);
        }
        const dst = Buffer.allocUnsafe(n);
        do {
          const buf = this._buffers[0];
          const offset = dst.length - n;
          if (n >= buf.length) {
            dst.set(this._buffers.shift(), offset);
          } else {
            dst.set(new Uint8Array(buf.buffer, buf.byteOffset, n), offset);
            this._buffers[0] = new FastBuffer(
              buf.buffer,
              buf.byteOffset + n,
              buf.length - n
            );
          }
          n -= buf.length;
        } while (n > 0);
        return dst;
      }
      /**
       * Starts the parsing loop.
       *
       * @param {Function} cb Callback
       * @private
       */
      startLoop(cb) {
        this._loop = true;
        do {
          switch (this._state) {
            case GET_INFO:
              this.getInfo(cb);
              break;
            case GET_PAYLOAD_LENGTH_16:
              this.getPayloadLength16(cb);
              break;
            case GET_PAYLOAD_LENGTH_64:
              this.getPayloadLength64(cb);
              break;
            case GET_MASK:
              this.getMask();
              break;
            case GET_DATA:
              this.getData(cb);
              break;
            case INFLATING:
            case DEFER_EVENT:
              this._loop = false;
              return;
          }
        } while (this._loop);
        if (!this._errored) cb();
      }
      /**
       * Reads the first two bytes of a frame.
       *
       * @param {Function} cb Callback
       * @private
       */
      getInfo(cb) {
        if (this._bufferedBytes < 2) {
          this._loop = false;
          return;
        }
        const buf = this.consume(2);
        if ((buf[0] & 48) !== 0) {
          const error = this.createError(
            RangeError,
            "RSV2 and RSV3 must be clear",
            true,
            1002,
            "WS_ERR_UNEXPECTED_RSV_2_3"
          );
          cb(error);
          return;
        }
        const compressed = (buf[0] & 64) === 64;
        if (compressed && !this._extensions[PerMessageDeflate2.extensionName]) {
          const error = this.createError(
            RangeError,
            "RSV1 must be clear",
            true,
            1002,
            "WS_ERR_UNEXPECTED_RSV_1"
          );
          cb(error);
          return;
        }
        this._fin = (buf[0] & 128) === 128;
        this._opcode = buf[0] & 15;
        this._payloadLength = buf[1] & 127;
        if (this._opcode === 0) {
          if (compressed) {
            const error = this.createError(
              RangeError,
              "RSV1 must be clear",
              true,
              1002,
              "WS_ERR_UNEXPECTED_RSV_1"
            );
            cb(error);
            return;
          }
          if (!this._fragmented) {
            const error = this.createError(
              RangeError,
              "invalid opcode 0",
              true,
              1002,
              "WS_ERR_INVALID_OPCODE"
            );
            cb(error);
            return;
          }
          this._opcode = this._fragmented;
        } else if (this._opcode === 1 || this._opcode === 2) {
          if (this._fragmented) {
            const error = this.createError(
              RangeError,
              `invalid opcode ${this._opcode}`,
              true,
              1002,
              "WS_ERR_INVALID_OPCODE"
            );
            cb(error);
            return;
          }
          this._compressed = compressed;
        } else if (this._opcode > 7 && this._opcode < 11) {
          if (!this._fin) {
            const error = this.createError(
              RangeError,
              "FIN must be set",
              true,
              1002,
              "WS_ERR_EXPECTED_FIN"
            );
            cb(error);
            return;
          }
          if (compressed) {
            const error = this.createError(
              RangeError,
              "RSV1 must be clear",
              true,
              1002,
              "WS_ERR_UNEXPECTED_RSV_1"
            );
            cb(error);
            return;
          }
          if (this._payloadLength > 125 || this._opcode === 8 && this._payloadLength === 1) {
            const error = this.createError(
              RangeError,
              `invalid payload length ${this._payloadLength}`,
              true,
              1002,
              "WS_ERR_INVALID_CONTROL_PAYLOAD_LENGTH"
            );
            cb(error);
            return;
          }
        } else {
          const error = this.createError(
            RangeError,
            `invalid opcode ${this._opcode}`,
            true,
            1002,
            "WS_ERR_INVALID_OPCODE"
          );
          cb(error);
          return;
        }
        if (!this._fin && !this._fragmented) this._fragmented = this._opcode;
        this._masked = (buf[1] & 128) === 128;
        if (this._isServer) {
          if (!this._masked) {
            const error = this.createError(
              RangeError,
              "MASK must be set",
              true,
              1002,
              "WS_ERR_EXPECTED_MASK"
            );
            cb(error);
            return;
          }
        } else if (this._masked) {
          const error = this.createError(
            RangeError,
            "MASK must be clear",
            true,
            1002,
            "WS_ERR_UNEXPECTED_MASK"
          );
          cb(error);
          return;
        }
        if (this._payloadLength === 126) this._state = GET_PAYLOAD_LENGTH_16;
        else if (this._payloadLength === 127) this._state = GET_PAYLOAD_LENGTH_64;
        else this.haveLength(cb);
      }
      /**
       * Gets extended payload length (7+16).
       *
       * @param {Function} cb Callback
       * @private
       */
      getPayloadLength16(cb) {
        if (this._bufferedBytes < 2) {
          this._loop = false;
          return;
        }
        this._payloadLength = this.consume(2).readUInt16BE(0);
        this.haveLength(cb);
      }
      /**
       * Gets extended payload length (7+64).
       *
       * @param {Function} cb Callback
       * @private
       */
      getPayloadLength64(cb) {
        if (this._bufferedBytes < 8) {
          this._loop = false;
          return;
        }
        const buf = this.consume(8);
        const num = buf.readUInt32BE(0);
        if (num > Math.pow(2, 53 - 32) - 1) {
          const error = this.createError(
            RangeError,
            "Unsupported WebSocket frame: payload length > 2^53 - 1",
            false,
            1009,
            "WS_ERR_UNSUPPORTED_DATA_PAYLOAD_LENGTH"
          );
          cb(error);
          return;
        }
        this._payloadLength = num * Math.pow(2, 32) + buf.readUInt32BE(4);
        this.haveLength(cb);
      }
      /**
       * Payload length has been read.
       *
       * @param {Function} cb Callback
       * @private
       */
      haveLength(cb) {
        if (this._payloadLength && this._opcode < 8) {
          this._totalPayloadLength += this._payloadLength;
          if (this._totalPayloadLength > this._maxPayload && this._maxPayload > 0) {
            const error = this.createError(
              RangeError,
              "Max payload size exceeded",
              false,
              1009,
              "WS_ERR_UNSUPPORTED_MESSAGE_LENGTH"
            );
            cb(error);
            return;
          }
        }
        if (this._masked) this._state = GET_MASK;
        else this._state = GET_DATA;
      }
      /**
       * Reads mask bytes.
       *
       * @private
       */
      getMask() {
        if (this._bufferedBytes < 4) {
          this._loop = false;
          return;
        }
        this._mask = this.consume(4);
        this._state = GET_DATA;
      }
      /**
       * Reads data bytes.
       *
       * @param {Function} cb Callback
       * @private
       */
      getData(cb) {
        let data = EMPTY_BUFFER;
        if (this._payloadLength) {
          if (this._bufferedBytes < this._payloadLength) {
            this._loop = false;
            return;
          }
          data = this.consume(this._payloadLength);
          if (this._masked && (this._mask[0] | this._mask[1] | this._mask[2] | this._mask[3]) !== 0) {
            unmask(data, this._mask);
          }
        }
        if (this._opcode > 7) {
          this.controlMessage(data, cb);
          return;
        }
        if (this._compressed) {
          this._state = INFLATING;
          this.decompress(data, cb);
          return;
        }
        if (data.length) {
          this._messageLength = this._totalPayloadLength;
          this._fragments.push(data);
        }
        this.dataMessage(cb);
      }
      /**
       * Decompresses data.
       *
       * @param {Buffer} data Compressed data
       * @param {Function} cb Callback
       * @private
       */
      decompress(data, cb) {
        const perMessageDeflate = this._extensions[PerMessageDeflate2.extensionName];
        perMessageDeflate.decompress(data, this._fin, (err, buf) => {
          if (err) return cb(err);
          if (buf.length) {
            this._messageLength += buf.length;
            if (this._messageLength > this._maxPayload && this._maxPayload > 0) {
              const error = this.createError(
                RangeError,
                "Max payload size exceeded",
                false,
                1009,
                "WS_ERR_UNSUPPORTED_MESSAGE_LENGTH"
              );
              cb(error);
              return;
            }
            this._fragments.push(buf);
          }
          this.dataMessage(cb);
          if (this._state === GET_INFO) this.startLoop(cb);
        });
      }
      /**
       * Handles a data message.
       *
       * @param {Function} cb Callback
       * @private
       */
      dataMessage(cb) {
        if (!this._fin) {
          this._state = GET_INFO;
          return;
        }
        const messageLength = this._messageLength;
        const fragments = this._fragments;
        this._totalPayloadLength = 0;
        this._messageLength = 0;
        this._fragmented = 0;
        this._fragments = [];
        if (this._opcode === 2) {
          let data;
          if (this._binaryType === "nodebuffer") {
            data = concat(fragments, messageLength);
          } else if (this._binaryType === "arraybuffer") {
            data = toArrayBuffer(concat(fragments, messageLength));
          } else if (this._binaryType === "blob") {
            data = new Blob(fragments);
          } else {
            data = fragments;
          }
          if (this._allowSynchronousEvents) {
            this.emit("message", data, true);
            this._state = GET_INFO;
          } else {
            this._state = DEFER_EVENT;
            setImmediate(() => {
              this.emit("message", data, true);
              this._state = GET_INFO;
              this.startLoop(cb);
            });
          }
        } else {
          const buf = concat(fragments, messageLength);
          if (!this._skipUTF8Validation && !isValidUTF8(buf)) {
            const error = this.createError(
              Error,
              "invalid UTF-8 sequence",
              true,
              1007,
              "WS_ERR_INVALID_UTF8"
            );
            cb(error);
            return;
          }
          if (this._state === INFLATING || this._allowSynchronousEvents) {
            this.emit("message", buf, false);
            this._state = GET_INFO;
          } else {
            this._state = DEFER_EVENT;
            setImmediate(() => {
              this.emit("message", buf, false);
              this._state = GET_INFO;
              this.startLoop(cb);
            });
          }
        }
      }
      /**
       * Handles a control message.
       *
       * @param {Buffer} data Data to handle
       * @return {(Error|RangeError|undefined)} A possible error
       * @private
       */
      controlMessage(data, cb) {
        if (this._opcode === 8) {
          if (data.length === 0) {
            this._loop = false;
            this.emit("conclude", 1005, EMPTY_BUFFER);
            this.end();
          } else {
            const code = data.readUInt16BE(0);
            if (!isValidStatusCode(code)) {
              const error = this.createError(
                RangeError,
                `invalid status code ${code}`,
                true,
                1002,
                "WS_ERR_INVALID_CLOSE_CODE"
              );
              cb(error);
              return;
            }
            const buf = new FastBuffer(
              data.buffer,
              data.byteOffset + 2,
              data.length - 2
            );
            if (!this._skipUTF8Validation && !isValidUTF8(buf)) {
              const error = this.createError(
                Error,
                "invalid UTF-8 sequence",
                true,
                1007,
                "WS_ERR_INVALID_UTF8"
              );
              cb(error);
              return;
            }
            this._loop = false;
            this.emit("conclude", code, buf);
            this.end();
          }
          this._state = GET_INFO;
          return;
        }
        if (this._allowSynchronousEvents) {
          this.emit(this._opcode === 9 ? "ping" : "pong", data);
          this._state = GET_INFO;
        } else {
          this._state = DEFER_EVENT;
          setImmediate(() => {
            this.emit(this._opcode === 9 ? "ping" : "pong", data);
            this._state = GET_INFO;
            this.startLoop(cb);
          });
        }
      }
      /**
       * Builds an error object.
       *
       * @param {function(new:Error|RangeError)} ErrorCtor The error constructor
       * @param {String} message The error message
       * @param {Boolean} prefix Specifies whether or not to add a default prefix to
       *     `message`
       * @param {Number} statusCode The status code
       * @param {String} errorCode The exposed error code
       * @return {(Error|RangeError)} The error
       * @private
       */
      createError(ErrorCtor, message, prefix, statusCode, errorCode) {
        this._loop = false;
        this._errored = true;
        const err = new ErrorCtor(
          prefix ? `Invalid WebSocket frame: ${message}` : message
        );
        Error.captureStackTrace(err, this.createError);
        err.code = errorCode;
        err[kStatusCode] = statusCode;
        return err;
      }
    };
    module.exports = Receiver2;
  }
});

// node_modules/ws/lib/sender.js
var require_sender = __commonJS({
  "node_modules/ws/lib/sender.js"(exports, module) {
    "use strict";
    var { Duplex } = __require("stream");
    var { randomFillSync } = __require("crypto");
    var PerMessageDeflate2 = require_permessage_deflate();
    var { EMPTY_BUFFER, kWebSocket, NOOP } = require_constants2();
    var { isBlob, isValidStatusCode } = require_validation();
    var { mask: applyMask, toBuffer } = require_buffer_util();
    var kByteLength = /* @__PURE__ */ Symbol("kByteLength");
    var maskBuffer = Buffer.alloc(4);
    var RANDOM_POOL_SIZE = 8 * 1024;
    var randomPool;
    var randomPoolPointer = RANDOM_POOL_SIZE;
    var DEFAULT = 0;
    var DEFLATING = 1;
    var GET_BLOB_DATA = 2;
    var Sender2 = class _Sender {
      /**
       * Creates a Sender instance.
       *
       * @param {Duplex} socket The connection socket
       * @param {Object} [extensions] An object containing the negotiated extensions
       * @param {Function} [generateMask] The function used to generate the masking
       *     key
       */
      constructor(socket, extensions, generateMask) {
        this._extensions = extensions || {};
        if (generateMask) {
          this._generateMask = generateMask;
          this._maskBuffer = Buffer.alloc(4);
        }
        this._socket = socket;
        this._firstFragment = true;
        this._compress = false;
        this._bufferedBytes = 0;
        this._queue = [];
        this._state = DEFAULT;
        this.onerror = NOOP;
        this[kWebSocket] = void 0;
      }
      /**
       * Frames a piece of data according to the HyBi WebSocket protocol.
       *
       * @param {(Buffer|String)} data The data to frame
       * @param {Object} options Options object
       * @param {Boolean} [options.fin=false] Specifies whether or not to set the
       *     FIN bit
       * @param {Function} [options.generateMask] The function used to generate the
       *     masking key
       * @param {Boolean} [options.mask=false] Specifies whether or not to mask
       *     `data`
       * @param {Buffer} [options.maskBuffer] The buffer used to store the masking
       *     key
       * @param {Number} options.opcode The opcode
       * @param {Boolean} [options.readOnly=false] Specifies whether `data` can be
       *     modified
       * @param {Boolean} [options.rsv1=false] Specifies whether or not to set the
       *     RSV1 bit
       * @return {(Buffer|String)[]} The framed data
       * @public
       */
      static frame(data, options) {
        let mask;
        let merge = false;
        let offset = 2;
        let skipMasking = false;
        if (options.mask) {
          mask = options.maskBuffer || maskBuffer;
          if (options.generateMask) {
            options.generateMask(mask);
          } else {
            if (randomPoolPointer === RANDOM_POOL_SIZE) {
              if (randomPool === void 0) {
                randomPool = Buffer.alloc(RANDOM_POOL_SIZE);
              }
              randomFillSync(randomPool, 0, RANDOM_POOL_SIZE);
              randomPoolPointer = 0;
            }
            mask[0] = randomPool[randomPoolPointer++];
            mask[1] = randomPool[randomPoolPointer++];
            mask[2] = randomPool[randomPoolPointer++];
            mask[3] = randomPool[randomPoolPointer++];
          }
          skipMasking = (mask[0] | mask[1] | mask[2] | mask[3]) === 0;
          offset = 6;
        }
        let dataLength;
        if (typeof data === "string") {
          if ((!options.mask || skipMasking) && options[kByteLength] !== void 0) {
            dataLength = options[kByteLength];
          } else {
            data = Buffer.from(data);
            dataLength = data.length;
          }
        } else {
          dataLength = data.length;
          merge = options.mask && options.readOnly && !skipMasking;
        }
        let payloadLength = dataLength;
        if (dataLength >= 65536) {
          offset += 8;
          payloadLength = 127;
        } else if (dataLength > 125) {
          offset += 2;
          payloadLength = 126;
        }
        const target = Buffer.allocUnsafe(merge ? dataLength + offset : offset);
        target[0] = options.fin ? options.opcode | 128 : options.opcode;
        if (options.rsv1) target[0] |= 64;
        target[1] = payloadLength;
        if (payloadLength === 126) {
          target.writeUInt16BE(dataLength, 2);
        } else if (payloadLength === 127) {
          target[2] = target[3] = 0;
          target.writeUIntBE(dataLength, 4, 6);
        }
        if (!options.mask) return [target, data];
        target[1] |= 128;
        target[offset - 4] = mask[0];
        target[offset - 3] = mask[1];
        target[offset - 2] = mask[2];
        target[offset - 1] = mask[3];
        if (skipMasking) return [target, data];
        if (merge) {
          applyMask(data, mask, target, offset, dataLength);
          return [target];
        }
        applyMask(data, mask, data, 0, dataLength);
        return [target, data];
      }
      /**
       * Sends a close message to the other peer.
       *
       * @param {Number} [code] The status code component of the body
       * @param {(String|Buffer)} [data] The message component of the body
       * @param {Boolean} [mask=false] Specifies whether or not to mask the message
       * @param {Function} [cb] Callback
       * @public
       */
      close(code, data, mask, cb) {
        let buf;
        if (code === void 0) {
          buf = EMPTY_BUFFER;
        } else if (typeof code !== "number" || !isValidStatusCode(code)) {
          throw new TypeError("First argument must be a valid error code number");
        } else if (data === void 0 || !data.length) {
          buf = Buffer.allocUnsafe(2);
          buf.writeUInt16BE(code, 0);
        } else {
          const length = Buffer.byteLength(data);
          if (length > 123) {
            throw new RangeError("The message must not be greater than 123 bytes");
          }
          buf = Buffer.allocUnsafe(2 + length);
          buf.writeUInt16BE(code, 0);
          if (typeof data === "string") {
            buf.write(data, 2);
          } else {
            buf.set(data, 2);
          }
        }
        const options = {
          [kByteLength]: buf.length,
          fin: true,
          generateMask: this._generateMask,
          mask,
          maskBuffer: this._maskBuffer,
          opcode: 8,
          readOnly: false,
          rsv1: false
        };
        if (this._state !== DEFAULT) {
          this.enqueue([this.dispatch, buf, false, options, cb]);
        } else {
          this.sendFrame(_Sender.frame(buf, options), cb);
        }
      }
      /**
       * Sends a ping message to the other peer.
       *
       * @param {*} data The message to send
       * @param {Boolean} [mask=false] Specifies whether or not to mask `data`
       * @param {Function} [cb] Callback
       * @public
       */
      ping(data, mask, cb) {
        let byteLength;
        let readOnly;
        if (typeof data === "string") {
          byteLength = Buffer.byteLength(data);
          readOnly = false;
        } else if (isBlob(data)) {
          byteLength = data.size;
          readOnly = false;
        } else {
          data = toBuffer(data);
          byteLength = data.length;
          readOnly = toBuffer.readOnly;
        }
        if (byteLength > 125) {
          throw new RangeError("The data size must not be greater than 125 bytes");
        }
        const options = {
          [kByteLength]: byteLength,
          fin: true,
          generateMask: this._generateMask,
          mask,
          maskBuffer: this._maskBuffer,
          opcode: 9,
          readOnly,
          rsv1: false
        };
        if (isBlob(data)) {
          if (this._state !== DEFAULT) {
            this.enqueue([this.getBlobData, data, false, options, cb]);
          } else {
            this.getBlobData(data, false, options, cb);
          }
        } else if (this._state !== DEFAULT) {
          this.enqueue([this.dispatch, data, false, options, cb]);
        } else {
          this.sendFrame(_Sender.frame(data, options), cb);
        }
      }
      /**
       * Sends a pong message to the other peer.
       *
       * @param {*} data The message to send
       * @param {Boolean} [mask=false] Specifies whether or not to mask `data`
       * @param {Function} [cb] Callback
       * @public
       */
      pong(data, mask, cb) {
        let byteLength;
        let readOnly;
        if (typeof data === "string") {
          byteLength = Buffer.byteLength(data);
          readOnly = false;
        } else if (isBlob(data)) {
          byteLength = data.size;
          readOnly = false;
        } else {
          data = toBuffer(data);
          byteLength = data.length;
          readOnly = toBuffer.readOnly;
        }
        if (byteLength > 125) {
          throw new RangeError("The data size must not be greater than 125 bytes");
        }
        const options = {
          [kByteLength]: byteLength,
          fin: true,
          generateMask: this._generateMask,
          mask,
          maskBuffer: this._maskBuffer,
          opcode: 10,
          readOnly,
          rsv1: false
        };
        if (isBlob(data)) {
          if (this._state !== DEFAULT) {
            this.enqueue([this.getBlobData, data, false, options, cb]);
          } else {
            this.getBlobData(data, false, options, cb);
          }
        } else if (this._state !== DEFAULT) {
          this.enqueue([this.dispatch, data, false, options, cb]);
        } else {
          this.sendFrame(_Sender.frame(data, options), cb);
        }
      }
      /**
       * Sends a data message to the other peer.
       *
       * @param {*} data The message to send
       * @param {Object} options Options object
       * @param {Boolean} [options.binary=false] Specifies whether `data` is binary
       *     or text
       * @param {Boolean} [options.compress=false] Specifies whether or not to
       *     compress `data`
       * @param {Boolean} [options.fin=false] Specifies whether the fragment is the
       *     last one
       * @param {Boolean} [options.mask=false] Specifies whether or not to mask
       *     `data`
       * @param {Function} [cb] Callback
       * @public
       */
      send(data, options, cb) {
        const perMessageDeflate = this._extensions[PerMessageDeflate2.extensionName];
        let opcode = options.binary ? 2 : 1;
        let rsv1 = options.compress;
        let byteLength;
        let readOnly;
        if (typeof data === "string") {
          byteLength = Buffer.byteLength(data);
          readOnly = false;
        } else if (isBlob(data)) {
          byteLength = data.size;
          readOnly = false;
        } else {
          data = toBuffer(data);
          byteLength = data.length;
          readOnly = toBuffer.readOnly;
        }
        if (this._firstFragment) {
          this._firstFragment = false;
          if (rsv1 && perMessageDeflate && perMessageDeflate.params[perMessageDeflate._isServer ? "server_no_context_takeover" : "client_no_context_takeover"]) {
            rsv1 = byteLength >= perMessageDeflate._threshold;
          }
          this._compress = rsv1;
        } else {
          rsv1 = false;
          opcode = 0;
        }
        if (options.fin) this._firstFragment = true;
        const opts = {
          [kByteLength]: byteLength,
          fin: options.fin,
          generateMask: this._generateMask,
          mask: options.mask,
          maskBuffer: this._maskBuffer,
          opcode,
          readOnly,
          rsv1
        };
        if (isBlob(data)) {
          if (this._state !== DEFAULT) {
            this.enqueue([this.getBlobData, data, this._compress, opts, cb]);
          } else {
            this.getBlobData(data, this._compress, opts, cb);
          }
        } else if (this._state !== DEFAULT) {
          this.enqueue([this.dispatch, data, this._compress, opts, cb]);
        } else {
          this.dispatch(data, this._compress, opts, cb);
        }
      }
      /**
       * Gets the contents of a blob as binary data.
       *
       * @param {Blob} blob The blob
       * @param {Boolean} [compress=false] Specifies whether or not to compress
       *     the data
       * @param {Object} options Options object
       * @param {Boolean} [options.fin=false] Specifies whether or not to set the
       *     FIN bit
       * @param {Function} [options.generateMask] The function used to generate the
       *     masking key
       * @param {Boolean} [options.mask=false] Specifies whether or not to mask
       *     `data`
       * @param {Buffer} [options.maskBuffer] The buffer used to store the masking
       *     key
       * @param {Number} options.opcode The opcode
       * @param {Boolean} [options.readOnly=false] Specifies whether `data` can be
       *     modified
       * @param {Boolean} [options.rsv1=false] Specifies whether or not to set the
       *     RSV1 bit
       * @param {Function} [cb] Callback
       * @private
       */
      getBlobData(blob, compress, options, cb) {
        this._bufferedBytes += options[kByteLength];
        this._state = GET_BLOB_DATA;
        blob.arrayBuffer().then((arrayBuffer) => {
          if (this._socket.destroyed) {
            const err = new Error(
              "The socket was closed while the blob was being read"
            );
            process.nextTick(callCallbacks, this, err, cb);
            return;
          }
          this._bufferedBytes -= options[kByteLength];
          const data = toBuffer(arrayBuffer);
          if (!compress) {
            this._state = DEFAULT;
            this.sendFrame(_Sender.frame(data, options), cb);
            this.dequeue();
          } else {
            this.dispatch(data, compress, options, cb);
          }
        }).catch((err) => {
          process.nextTick(onError, this, err, cb);
        });
      }
      /**
       * Dispatches a message.
       *
       * @param {(Buffer|String)} data The message to send
       * @param {Boolean} [compress=false] Specifies whether or not to compress
       *     `data`
       * @param {Object} options Options object
       * @param {Boolean} [options.fin=false] Specifies whether or not to set the
       *     FIN bit
       * @param {Function} [options.generateMask] The function used to generate the
       *     masking key
       * @param {Boolean} [options.mask=false] Specifies whether or not to mask
       *     `data`
       * @param {Buffer} [options.maskBuffer] The buffer used to store the masking
       *     key
       * @param {Number} options.opcode The opcode
       * @param {Boolean} [options.readOnly=false] Specifies whether `data` can be
       *     modified
       * @param {Boolean} [options.rsv1=false] Specifies whether or not to set the
       *     RSV1 bit
       * @param {Function} [cb] Callback
       * @private
       */
      dispatch(data, compress, options, cb) {
        if (!compress) {
          this.sendFrame(_Sender.frame(data, options), cb);
          return;
        }
        const perMessageDeflate = this._extensions[PerMessageDeflate2.extensionName];
        this._bufferedBytes += options[kByteLength];
        this._state = DEFLATING;
        perMessageDeflate.compress(data, options.fin, (_, buf) => {
          if (this._socket.destroyed) {
            const err = new Error(
              "The socket was closed while data was being compressed"
            );
            callCallbacks(this, err, cb);
            return;
          }
          this._bufferedBytes -= options[kByteLength];
          this._state = DEFAULT;
          options.readOnly = false;
          this.sendFrame(_Sender.frame(buf, options), cb);
          this.dequeue();
        });
      }
      /**
       * Executes queued send operations.
       *
       * @private
       */
      dequeue() {
        while (this._state === DEFAULT && this._queue.length) {
          const params = this._queue.shift();
          this._bufferedBytes -= params[3][kByteLength];
          Reflect.apply(params[0], this, params.slice(1));
        }
      }
      /**
       * Enqueues a send operation.
       *
       * @param {Array} params Send operation parameters.
       * @private
       */
      enqueue(params) {
        this._bufferedBytes += params[3][kByteLength];
        this._queue.push(params);
      }
      /**
       * Sends a frame.
       *
       * @param {(Buffer | String)[]} list The frame to send
       * @param {Function} [cb] Callback
       * @private
       */
      sendFrame(list, cb) {
        if (list.length === 2) {
          this._socket.cork();
          this._socket.write(list[0]);
          this._socket.write(list[1], cb);
          this._socket.uncork();
        } else {
          this._socket.write(list[0], cb);
        }
      }
    };
    module.exports = Sender2;
    function callCallbacks(sender, err, cb) {
      if (typeof cb === "function") cb(err);
      for (let i = 0; i < sender._queue.length; i++) {
        const params = sender._queue[i];
        const callback = params[params.length - 1];
        if (typeof callback === "function") callback(err);
      }
    }
    function onError(sender, err, cb) {
      callCallbacks(sender, err, cb);
      sender.onerror(err);
    }
  }
});

// node_modules/ws/lib/event-target.js
var require_event_target = __commonJS({
  "node_modules/ws/lib/event-target.js"(exports, module) {
    "use strict";
    var { kForOnEventAttribute, kListener } = require_constants2();
    var kCode = /* @__PURE__ */ Symbol("kCode");
    var kData = /* @__PURE__ */ Symbol("kData");
    var kError = /* @__PURE__ */ Symbol("kError");
    var kMessage = /* @__PURE__ */ Symbol("kMessage");
    var kReason = /* @__PURE__ */ Symbol("kReason");
    var kTarget = /* @__PURE__ */ Symbol("kTarget");
    var kType = /* @__PURE__ */ Symbol("kType");
    var kWasClean = /* @__PURE__ */ Symbol("kWasClean");
    var Event = class {
      /**
       * Create a new `Event`.
       *
       * @param {String} type The name of the event
       * @throws {TypeError} If the `type` argument is not specified
       */
      constructor(type) {
        this[kTarget] = null;
        this[kType] = type;
      }
      /**
       * @type {*}
       */
      get target() {
        return this[kTarget];
      }
      /**
       * @type {String}
       */
      get type() {
        return this[kType];
      }
    };
    Object.defineProperty(Event.prototype, "target", { enumerable: true });
    Object.defineProperty(Event.prototype, "type", { enumerable: true });
    var CloseEvent = class extends Event {
      /**
       * Create a new `CloseEvent`.
       *
       * @param {String} type The name of the event
       * @param {Object} [options] A dictionary object that allows for setting
       *     attributes via object members of the same name
       * @param {Number} [options.code=0] The status code explaining why the
       *     connection was closed
       * @param {String} [options.reason=''] A human-readable string explaining why
       *     the connection was closed
       * @param {Boolean} [options.wasClean=false] Indicates whether or not the
       *     connection was cleanly closed
       */
      constructor(type, options = {}) {
        super(type);
        this[kCode] = options.code === void 0 ? 0 : options.code;
        this[kReason] = options.reason === void 0 ? "" : options.reason;
        this[kWasClean] = options.wasClean === void 0 ? false : options.wasClean;
      }
      /**
       * @type {Number}
       */
      get code() {
        return this[kCode];
      }
      /**
       * @type {String}
       */
      get reason() {
        return this[kReason];
      }
      /**
       * @type {Boolean}
       */
      get wasClean() {
        return this[kWasClean];
      }
    };
    Object.defineProperty(CloseEvent.prototype, "code", { enumerable: true });
    Object.defineProperty(CloseEvent.prototype, "reason", { enumerable: true });
    Object.defineProperty(CloseEvent.prototype, "wasClean", { enumerable: true });
    var ErrorEvent = class extends Event {
      /**
       * Create a new `ErrorEvent`.
       *
       * @param {String} type The name of the event
       * @param {Object} [options] A dictionary object that allows for setting
       *     attributes via object members of the same name
       * @param {*} [options.error=null] The error that generated this event
       * @param {String} [options.message=''] The error message
       */
      constructor(type, options = {}) {
        super(type);
        this[kError] = options.error === void 0 ? null : options.error;
        this[kMessage] = options.message === void 0 ? "" : options.message;
      }
      /**
       * @type {*}
       */
      get error() {
        return this[kError];
      }
      /**
       * @type {String}
       */
      get message() {
        return this[kMessage];
      }
    };
    Object.defineProperty(ErrorEvent.prototype, "error", { enumerable: true });
    Object.defineProperty(ErrorEvent.prototype, "message", { enumerable: true });
    var MessageEvent = class extends Event {
      /**
       * Create a new `MessageEvent`.
       *
       * @param {String} type The name of the event
       * @param {Object} [options] A dictionary object that allows for setting
       *     attributes via object members of the same name
       * @param {*} [options.data=null] The message content
       */
      constructor(type, options = {}) {
        super(type);
        this[kData] = options.data === void 0 ? null : options.data;
      }
      /**
       * @type {*}
       */
      get data() {
        return this[kData];
      }
    };
    Object.defineProperty(MessageEvent.prototype, "data", { enumerable: true });
    var EventTarget = {
      /**
       * Register an event listener.
       *
       * @param {String} type A string representing the event type to listen for
       * @param {(Function|Object)} handler The listener to add
       * @param {Object} [options] An options object specifies characteristics about
       *     the event listener
       * @param {Boolean} [options.once=false] A `Boolean` indicating that the
       *     listener should be invoked at most once after being added. If `true`,
       *     the listener would be automatically removed when invoked.
       * @public
       */
      addEventListener(type, handler, options = {}) {
        for (const listener of this.listeners(type)) {
          if (!options[kForOnEventAttribute] && listener[kListener] === handler && !listener[kForOnEventAttribute]) {
            return;
          }
        }
        let wrapper;
        if (type === "message") {
          wrapper = function onMessage(data, isBinary) {
            const event = new MessageEvent("message", {
              data: isBinary ? data : data.toString()
            });
            event[kTarget] = this;
            callListener(handler, this, event);
          };
        } else if (type === "close") {
          wrapper = function onClose(code, message) {
            const event = new CloseEvent("close", {
              code,
              reason: message.toString(),
              wasClean: this._closeFrameReceived && this._closeFrameSent
            });
            event[kTarget] = this;
            callListener(handler, this, event);
          };
        } else if (type === "error") {
          wrapper = function onError(error) {
            const event = new ErrorEvent("error", {
              error,
              message: error.message
            });
            event[kTarget] = this;
            callListener(handler, this, event);
          };
        } else if (type === "open") {
          wrapper = function onOpen() {
            const event = new Event("open");
            event[kTarget] = this;
            callListener(handler, this, event);
          };
        } else {
          return;
        }
        wrapper[kForOnEventAttribute] = !!options[kForOnEventAttribute];
        wrapper[kListener] = handler;
        if (options.once) {
          this.once(type, wrapper);
        } else {
          this.on(type, wrapper);
        }
      },
      /**
       * Remove an event listener.
       *
       * @param {String} type A string representing the event type to remove
       * @param {(Function|Object)} handler The listener to remove
       * @public
       */
      removeEventListener(type, handler) {
        for (const listener of this.listeners(type)) {
          if (listener[kListener] === handler && !listener[kForOnEventAttribute]) {
            this.removeListener(type, listener);
            break;
          }
        }
      }
    };
    module.exports = {
      CloseEvent,
      ErrorEvent,
      Event,
      EventTarget,
      MessageEvent
    };
    function callListener(listener, thisArg, event) {
      if (typeof listener === "object" && listener.handleEvent) {
        listener.handleEvent.call(listener, event);
      } else {
        listener.call(thisArg, event);
      }
    }
  }
});

// node_modules/ws/lib/extension.js
var require_extension = __commonJS({
  "node_modules/ws/lib/extension.js"(exports, module) {
    "use strict";
    var { tokenChars } = require_validation();
    function push(dest, name, elem) {
      if (dest[name] === void 0) dest[name] = [elem];
      else dest[name].push(elem);
    }
    function parse(header) {
      const offers = /* @__PURE__ */ Object.create(null);
      let params = /* @__PURE__ */ Object.create(null);
      let mustUnescape = false;
      let isEscaping = false;
      let inQuotes = false;
      let extensionName;
      let paramName;
      let start = -1;
      let code = -1;
      let end = -1;
      let i = 0;
      for (; i < header.length; i++) {
        code = header.charCodeAt(i);
        if (extensionName === void 0) {
          if (end === -1 && tokenChars[code] === 1) {
            if (start === -1) start = i;
          } else if (i !== 0 && (code === 32 || code === 9)) {
            if (end === -1 && start !== -1) end = i;
          } else if (code === 59 || code === 44) {
            if (start === -1) {
              throw new SyntaxError(`Unexpected character at index ${i}`);
            }
            if (end === -1) end = i;
            const name = header.slice(start, end);
            if (code === 44) {
              push(offers, name, params);
              params = /* @__PURE__ */ Object.create(null);
            } else {
              extensionName = name;
            }
            start = end = -1;
          } else {
            throw new SyntaxError(`Unexpected character at index ${i}`);
          }
        } else if (paramName === void 0) {
          if (end === -1 && tokenChars[code] === 1) {
            if (start === -1) start = i;
          } else if (code === 32 || code === 9) {
            if (end === -1 && start !== -1) end = i;
          } else if (code === 59 || code === 44) {
            if (start === -1) {
              throw new SyntaxError(`Unexpected character at index ${i}`);
            }
            if (end === -1) end = i;
            push(params, header.slice(start, end), true);
            if (code === 44) {
              push(offers, extensionName, params);
              params = /* @__PURE__ */ Object.create(null);
              extensionName = void 0;
            }
            start = end = -1;
          } else if (code === 61 && start !== -1 && end === -1) {
            paramName = header.slice(start, i);
            start = end = -1;
          } else {
            throw new SyntaxError(`Unexpected character at index ${i}`);
          }
        } else {
          if (isEscaping) {
            if (tokenChars[code] !== 1) {
              throw new SyntaxError(`Unexpected character at index ${i}`);
            }
            if (start === -1) start = i;
            else if (!mustUnescape) mustUnescape = true;
            isEscaping = false;
          } else if (inQuotes) {
            if (tokenChars[code] === 1) {
              if (start === -1) start = i;
            } else if (code === 34 && start !== -1) {
              inQuotes = false;
              end = i;
            } else if (code === 92) {
              isEscaping = true;
            } else {
              throw new SyntaxError(`Unexpected character at index ${i}`);
            }
          } else if (code === 34 && header.charCodeAt(i - 1) === 61) {
            inQuotes = true;
          } else if (end === -1 && tokenChars[code] === 1) {
            if (start === -1) start = i;
          } else if (start !== -1 && (code === 32 || code === 9)) {
            if (end === -1) end = i;
          } else if (code === 59 || code === 44) {
            if (start === -1) {
              throw new SyntaxError(`Unexpected character at index ${i}`);
            }
            if (end === -1) end = i;
            let value = header.slice(start, end);
            if (mustUnescape) {
              value = value.replace(/\\/g, "");
              mustUnescape = false;
            }
            push(params, paramName, value);
            if (code === 44) {
              push(offers, extensionName, params);
              params = /* @__PURE__ */ Object.create(null);
              extensionName = void 0;
            }
            paramName = void 0;
            start = end = -1;
          } else {
            throw new SyntaxError(`Unexpected character at index ${i}`);
          }
        }
      }
      if (start === -1 || inQuotes || code === 32 || code === 9) {
        throw new SyntaxError("Unexpected end of input");
      }
      if (end === -1) end = i;
      const token = header.slice(start, end);
      if (extensionName === void 0) {
        push(offers, token, params);
      } else {
        if (paramName === void 0) {
          push(params, token, true);
        } else if (mustUnescape) {
          push(params, paramName, token.replace(/\\/g, ""));
        } else {
          push(params, paramName, token);
        }
        push(offers, extensionName, params);
      }
      return offers;
    }
    function format(extensions) {
      return Object.keys(extensions).map((extension2) => {
        let configurations = extensions[extension2];
        if (!Array.isArray(configurations)) configurations = [configurations];
        return configurations.map((params) => {
          return [extension2].concat(
            Object.keys(params).map((k) => {
              let values = params[k];
              if (!Array.isArray(values)) values = [values];
              return values.map((v) => v === true ? k : `${k}=${v}`).join("; ");
            })
          ).join("; ");
        }).join(", ");
      }).join(", ");
    }
    module.exports = { format, parse };
  }
});

// node_modules/ws/lib/websocket.js
var require_websocket = __commonJS({
  "node_modules/ws/lib/websocket.js"(exports, module) {
    "use strict";
    var EventEmitter3 = __require("events");
    var https = __require("https");
    var http = __require("http");
    var net = __require("net");
    var tls = __require("tls");
    var { randomBytes, createHash } = __require("crypto");
    var { Duplex, Readable } = __require("stream");
    var { URL } = __require("url");
    var PerMessageDeflate2 = require_permessage_deflate();
    var Receiver2 = require_receiver();
    var Sender2 = require_sender();
    var { isBlob } = require_validation();
    var {
      BINARY_TYPES,
      CLOSE_TIMEOUT,
      EMPTY_BUFFER,
      GUID,
      kForOnEventAttribute,
      kListener,
      kStatusCode,
      kWebSocket,
      NOOP
    } = require_constants2();
    var {
      EventTarget: { addEventListener, removeEventListener }
    } = require_event_target();
    var { format, parse } = require_extension();
    var { toBuffer } = require_buffer_util();
    var kAborted = /* @__PURE__ */ Symbol("kAborted");
    var protocolVersions = [8, 13];
    var readyStates = ["CONNECTING", "OPEN", "CLOSING", "CLOSED"];
    var subprotocolRegex = /^[!#$%&'*+\-.0-9A-Z^_`|a-z~]+$/;
    var WebSocket2 = class _WebSocket extends EventEmitter3 {
      /**
       * Create a new `WebSocket`.
       *
       * @param {(String|URL)} address The URL to which to connect
       * @param {(String|String[])} [protocols] The subprotocols
       * @param {Object} [options] Connection options
       */
      constructor(address, protocols, options) {
        super();
        this._binaryType = BINARY_TYPES[0];
        this._closeCode = 1006;
        this._closeFrameReceived = false;
        this._closeFrameSent = false;
        this._closeMessage = EMPTY_BUFFER;
        this._closeTimer = null;
        this._errorEmitted = false;
        this._extensions = {};
        this._paused = false;
        this._protocol = "";
        this._readyState = _WebSocket.CONNECTING;
        this._receiver = null;
        this._sender = null;
        this._socket = null;
        if (address !== null) {
          this._bufferedAmount = 0;
          this._isServer = false;
          this._redirects = 0;
          if (protocols === void 0) {
            protocols = [];
          } else if (!Array.isArray(protocols)) {
            if (typeof protocols === "object" && protocols !== null) {
              options = protocols;
              protocols = [];
            } else {
              protocols = [protocols];
            }
          }
          initAsClient(this, address, protocols, options);
        } else {
          this._autoPong = options.autoPong;
          this._closeTimeout = options.closeTimeout;
          this._isServer = true;
        }
      }
      /**
       * For historical reasons, the custom "nodebuffer" type is used by the default
       * instead of "blob".
       *
       * @type {String}
       */
      get binaryType() {
        return this._binaryType;
      }
      set binaryType(type) {
        if (!BINARY_TYPES.includes(type)) return;
        this._binaryType = type;
        if (this._receiver) this._receiver._binaryType = type;
      }
      /**
       * @type {Number}
       */
      get bufferedAmount() {
        if (!this._socket) return this._bufferedAmount;
        return this._socket._writableState.length + this._sender._bufferedBytes;
      }
      /**
       * @type {String}
       */
      get extensions() {
        return Object.keys(this._extensions).join();
      }
      /**
       * @type {Boolean}
       */
      get isPaused() {
        return this._paused;
      }
      /**
       * @type {Function}
       */
      /* istanbul ignore next */
      get onclose() {
        return null;
      }
      /**
       * @type {Function}
       */
      /* istanbul ignore next */
      get onerror() {
        return null;
      }
      /**
       * @type {Function}
       */
      /* istanbul ignore next */
      get onopen() {
        return null;
      }
      /**
       * @type {Function}
       */
      /* istanbul ignore next */
      get onmessage() {
        return null;
      }
      /**
       * @type {String}
       */
      get protocol() {
        return this._protocol;
      }
      /**
       * @type {Number}
       */
      get readyState() {
        return this._readyState;
      }
      /**
       * @type {String}
       */
      get url() {
        return this._url;
      }
      /**
       * Set up the socket and the internal resources.
       *
       * @param {Duplex} socket The network socket between the server and client
       * @param {Buffer} head The first packet of the upgraded stream
       * @param {Object} options Options object
       * @param {Boolean} [options.allowSynchronousEvents=false] Specifies whether
       *     any of the `'message'`, `'ping'`, and `'pong'` events can be emitted
       *     multiple times in the same tick
       * @param {Function} [options.generateMask] The function used to generate the
       *     masking key
       * @param {Number} [options.maxPayload=0] The maximum allowed message size
       * @param {Boolean} [options.skipUTF8Validation=false] Specifies whether or
       *     not to skip UTF-8 validation for text and close messages
       * @private
       */
      setSocket(socket, head, options) {
        const receiver = new Receiver2({
          allowSynchronousEvents: options.allowSynchronousEvents,
          binaryType: this.binaryType,
          extensions: this._extensions,
          isServer: this._isServer,
          maxPayload: options.maxPayload,
          skipUTF8Validation: options.skipUTF8Validation
        });
        const sender = new Sender2(socket, this._extensions, options.generateMask);
        this._receiver = receiver;
        this._sender = sender;
        this._socket = socket;
        receiver[kWebSocket] = this;
        sender[kWebSocket] = this;
        socket[kWebSocket] = this;
        receiver.on("conclude", receiverOnConclude);
        receiver.on("drain", receiverOnDrain);
        receiver.on("error", receiverOnError);
        receiver.on("message", receiverOnMessage);
        receiver.on("ping", receiverOnPing);
        receiver.on("pong", receiverOnPong);
        sender.onerror = senderOnError;
        if (socket.setTimeout) socket.setTimeout(0);
        if (socket.setNoDelay) socket.setNoDelay();
        if (head.length > 0) socket.unshift(head);
        socket.on("close", socketOnClose);
        socket.on("data", socketOnData);
        socket.on("end", socketOnEnd);
        socket.on("error", socketOnError);
        this._readyState = _WebSocket.OPEN;
        this.emit("open");
      }
      /**
       * Emit the `'close'` event.
       *
       * @private
       */
      emitClose() {
        if (!this._socket) {
          this._readyState = _WebSocket.CLOSED;
          this.emit("close", this._closeCode, this._closeMessage);
          return;
        }
        if (this._extensions[PerMessageDeflate2.extensionName]) {
          this._extensions[PerMessageDeflate2.extensionName].cleanup();
        }
        this._receiver.removeAllListeners();
        this._readyState = _WebSocket.CLOSED;
        this.emit("close", this._closeCode, this._closeMessage);
      }
      /**
       * Start a closing handshake.
       *
       *          +----------+   +-----------+   +----------+
       *     - - -|ws.close()|-->|close frame|-->|ws.close()|- - -
       *    |     +----------+   +-----------+   +----------+     |
       *          +----------+   +-----------+         |
       * CLOSING  |ws.close()|<--|close frame|<--+-----+       CLOSING
       *          +----------+   +-----------+   |
       *    |           |                        |   +---+        |
       *                +------------------------+-->|fin| - - - -
       *    |         +---+                      |   +---+
       *     - - - - -|fin|<---------------------+
       *              +---+
       *
       * @param {Number} [code] Status code explaining why the connection is closing
       * @param {(String|Buffer)} [data] The reason why the connection is
       *     closing
       * @public
       */
      close(code, data) {
        if (this.readyState === _WebSocket.CLOSED) return;
        if (this.readyState === _WebSocket.CONNECTING) {
          const msg = "WebSocket was closed before the connection was established";
          abortHandshake(this, this._req, msg);
          return;
        }
        if (this.readyState === _WebSocket.CLOSING) {
          if (this._closeFrameSent && (this._closeFrameReceived || this._receiver._writableState.errorEmitted)) {
            this._socket.end();
          }
          return;
        }
        this._readyState = _WebSocket.CLOSING;
        this._sender.close(code, data, !this._isServer, (err) => {
          if (err) return;
          this._closeFrameSent = true;
          if (this._closeFrameReceived || this._receiver._writableState.errorEmitted) {
            this._socket.end();
          }
        });
        setCloseTimer(this);
      }
      /**
       * Pause the socket.
       *
       * @public
       */
      pause() {
        if (this.readyState === _WebSocket.CONNECTING || this.readyState === _WebSocket.CLOSED) {
          return;
        }
        this._paused = true;
        this._socket.pause();
      }
      /**
       * Send a ping.
       *
       * @param {*} [data] The data to send
       * @param {Boolean} [mask] Indicates whether or not to mask `data`
       * @param {Function} [cb] Callback which is executed when the ping is sent
       * @public
       */
      ping(data, mask, cb) {
        if (this.readyState === _WebSocket.CONNECTING) {
          throw new Error("WebSocket is not open: readyState 0 (CONNECTING)");
        }
        if (typeof data === "function") {
          cb = data;
          data = mask = void 0;
        } else if (typeof mask === "function") {
          cb = mask;
          mask = void 0;
        }
        if (typeof data === "number") data = data.toString();
        if (this.readyState !== _WebSocket.OPEN) {
          sendAfterClose(this, data, cb);
          return;
        }
        if (mask === void 0) mask = !this._isServer;
        this._sender.ping(data || EMPTY_BUFFER, mask, cb);
      }
      /**
       * Send a pong.
       *
       * @param {*} [data] The data to send
       * @param {Boolean} [mask] Indicates whether or not to mask `data`
       * @param {Function} [cb] Callback which is executed when the pong is sent
       * @public
       */
      pong(data, mask, cb) {
        if (this.readyState === _WebSocket.CONNECTING) {
          throw new Error("WebSocket is not open: readyState 0 (CONNECTING)");
        }
        if (typeof data === "function") {
          cb = data;
          data = mask = void 0;
        } else if (typeof mask === "function") {
          cb = mask;
          mask = void 0;
        }
        if (typeof data === "number") data = data.toString();
        if (this.readyState !== _WebSocket.OPEN) {
          sendAfterClose(this, data, cb);
          return;
        }
        if (mask === void 0) mask = !this._isServer;
        this._sender.pong(data || EMPTY_BUFFER, mask, cb);
      }
      /**
       * Resume the socket.
       *
       * @public
       */
      resume() {
        if (this.readyState === _WebSocket.CONNECTING || this.readyState === _WebSocket.CLOSED) {
          return;
        }
        this._paused = false;
        if (!this._receiver._writableState.needDrain) this._socket.resume();
      }
      /**
       * Send a data message.
       *
       * @param {*} data The message to send
       * @param {Object} [options] Options object
       * @param {Boolean} [options.binary] Specifies whether `data` is binary or
       *     text
       * @param {Boolean} [options.compress] Specifies whether or not to compress
       *     `data`
       * @param {Boolean} [options.fin=true] Specifies whether the fragment is the
       *     last one
       * @param {Boolean} [options.mask] Specifies whether or not to mask `data`
       * @param {Function} [cb] Callback which is executed when data is written out
       * @public
       */
      send(data, options, cb) {
        if (this.readyState === _WebSocket.CONNECTING) {
          throw new Error("WebSocket is not open: readyState 0 (CONNECTING)");
        }
        if (typeof options === "function") {
          cb = options;
          options = {};
        }
        if (typeof data === "number") data = data.toString();
        if (this.readyState !== _WebSocket.OPEN) {
          sendAfterClose(this, data, cb);
          return;
        }
        const opts = {
          binary: typeof data !== "string",
          mask: !this._isServer,
          compress: true,
          fin: true,
          ...options
        };
        if (!this._extensions[PerMessageDeflate2.extensionName]) {
          opts.compress = false;
        }
        this._sender.send(data || EMPTY_BUFFER, opts, cb);
      }
      /**
       * Forcibly close the connection.
       *
       * @public
       */
      terminate() {
        if (this.readyState === _WebSocket.CLOSED) return;
        if (this.readyState === _WebSocket.CONNECTING) {
          const msg = "WebSocket was closed before the connection was established";
          abortHandshake(this, this._req, msg);
          return;
        }
        if (this._socket) {
          this._readyState = _WebSocket.CLOSING;
          this._socket.destroy();
        }
      }
    };
    Object.defineProperty(WebSocket2, "CONNECTING", {
      enumerable: true,
      value: readyStates.indexOf("CONNECTING")
    });
    Object.defineProperty(WebSocket2.prototype, "CONNECTING", {
      enumerable: true,
      value: readyStates.indexOf("CONNECTING")
    });
    Object.defineProperty(WebSocket2, "OPEN", {
      enumerable: true,
      value: readyStates.indexOf("OPEN")
    });
    Object.defineProperty(WebSocket2.prototype, "OPEN", {
      enumerable: true,
      value: readyStates.indexOf("OPEN")
    });
    Object.defineProperty(WebSocket2, "CLOSING", {
      enumerable: true,
      value: readyStates.indexOf("CLOSING")
    });
    Object.defineProperty(WebSocket2.prototype, "CLOSING", {
      enumerable: true,
      value: readyStates.indexOf("CLOSING")
    });
    Object.defineProperty(WebSocket2, "CLOSED", {
      enumerable: true,
      value: readyStates.indexOf("CLOSED")
    });
    Object.defineProperty(WebSocket2.prototype, "CLOSED", {
      enumerable: true,
      value: readyStates.indexOf("CLOSED")
    });
    [
      "binaryType",
      "bufferedAmount",
      "extensions",
      "isPaused",
      "protocol",
      "readyState",
      "url"
    ].forEach((property) => {
      Object.defineProperty(WebSocket2.prototype, property, { enumerable: true });
    });
    ["open", "error", "close", "message"].forEach((method) => {
      Object.defineProperty(WebSocket2.prototype, `on${method}`, {
        enumerable: true,
        get() {
          for (const listener of this.listeners(method)) {
            if (listener[kForOnEventAttribute]) return listener[kListener];
          }
          return null;
        },
        set(handler) {
          for (const listener of this.listeners(method)) {
            if (listener[kForOnEventAttribute]) {
              this.removeListener(method, listener);
              break;
            }
          }
          if (typeof handler !== "function") return;
          this.addEventListener(method, handler, {
            [kForOnEventAttribute]: true
          });
        }
      });
    });
    WebSocket2.prototype.addEventListener = addEventListener;
    WebSocket2.prototype.removeEventListener = removeEventListener;
    module.exports = WebSocket2;
    function initAsClient(websocket, address, protocols, options) {
      const opts = {
        allowSynchronousEvents: true,
        autoPong: true,
        closeTimeout: CLOSE_TIMEOUT,
        protocolVersion: protocolVersions[1],
        maxPayload: 100 * 1024 * 1024,
        skipUTF8Validation: false,
        perMessageDeflate: true,
        followRedirects: false,
        maxRedirects: 10,
        ...options,
        socketPath: void 0,
        hostname: void 0,
        protocol: void 0,
        timeout: void 0,
        method: "GET",
        host: void 0,
        path: void 0,
        port: void 0
      };
      websocket._autoPong = opts.autoPong;
      websocket._closeTimeout = opts.closeTimeout;
      if (!protocolVersions.includes(opts.protocolVersion)) {
        throw new RangeError(
          `Unsupported protocol version: ${opts.protocolVersion} (supported versions: ${protocolVersions.join(", ")})`
        );
      }
      let parsedUrl;
      if (address instanceof URL) {
        parsedUrl = address;
      } else {
        try {
          parsedUrl = new URL(address);
        } catch {
          throw new SyntaxError(`Invalid URL: ${address}`);
        }
      }
      if (parsedUrl.protocol === "http:") {
        parsedUrl.protocol = "ws:";
      } else if (parsedUrl.protocol === "https:") {
        parsedUrl.protocol = "wss:";
      }
      websocket._url = parsedUrl.href;
      const isSecure = parsedUrl.protocol === "wss:";
      const isIpcUrl = parsedUrl.protocol === "ws+unix:";
      let invalidUrlMessage;
      if (parsedUrl.protocol !== "ws:" && !isSecure && !isIpcUrl) {
        invalidUrlMessage = `The URL's protocol must be one of "ws:", "wss:", "http:", "https:", or "ws+unix:"`;
      } else if (isIpcUrl && !parsedUrl.pathname) {
        invalidUrlMessage = "The URL's pathname is empty";
      } else if (parsedUrl.hash) {
        invalidUrlMessage = "The URL contains a fragment identifier";
      }
      if (invalidUrlMessage) {
        const err = new SyntaxError(invalidUrlMessage);
        if (websocket._redirects === 0) {
          throw err;
        } else {
          emitErrorAndClose(websocket, err);
          return;
        }
      }
      const defaultPort = isSecure ? 443 : 80;
      const key = randomBytes(16).toString("base64");
      const request = isSecure ? https.request : http.request;
      const protocolSet = /* @__PURE__ */ new Set();
      let perMessageDeflate;
      opts.createConnection = opts.createConnection || (isSecure ? tlsConnect : netConnect);
      opts.defaultPort = opts.defaultPort || defaultPort;
      opts.port = parsedUrl.port || defaultPort;
      opts.host = parsedUrl.hostname.startsWith("[") ? parsedUrl.hostname.slice(1, -1) : parsedUrl.hostname;
      opts.headers = {
        ...opts.headers,
        "Sec-WebSocket-Version": opts.protocolVersion,
        "Sec-WebSocket-Key": key,
        Connection: "Upgrade",
        Upgrade: "websocket"
      };
      opts.path = parsedUrl.pathname + parsedUrl.search;
      opts.timeout = opts.handshakeTimeout;
      if (opts.perMessageDeflate) {
        perMessageDeflate = new PerMessageDeflate2({
          ...opts.perMessageDeflate,
          isServer: false,
          maxPayload: opts.maxPayload
        });
        opts.headers["Sec-WebSocket-Extensions"] = format({
          [PerMessageDeflate2.extensionName]: perMessageDeflate.offer()
        });
      }
      if (protocols.length) {
        for (const protocol of protocols) {
          if (typeof protocol !== "string" || !subprotocolRegex.test(protocol) || protocolSet.has(protocol)) {
            throw new SyntaxError(
              "An invalid or duplicated subprotocol was specified"
            );
          }
          protocolSet.add(protocol);
        }
        opts.headers["Sec-WebSocket-Protocol"] = protocols.join(",");
      }
      if (opts.origin) {
        if (opts.protocolVersion < 13) {
          opts.headers["Sec-WebSocket-Origin"] = opts.origin;
        } else {
          opts.headers.Origin = opts.origin;
        }
      }
      if (parsedUrl.username || parsedUrl.password) {
        opts.auth = `${parsedUrl.username}:${parsedUrl.password}`;
      }
      if (isIpcUrl) {
        const parts = opts.path.split(":");
        opts.socketPath = parts[0];
        opts.path = parts[1];
      }
      let req;
      if (opts.followRedirects) {
        if (websocket._redirects === 0) {
          websocket._originalIpc = isIpcUrl;
          websocket._originalSecure = isSecure;
          websocket._originalHostOrSocketPath = isIpcUrl ? opts.socketPath : parsedUrl.host;
          const headers = options && options.headers;
          options = { ...options, headers: {} };
          if (headers) {
            for (const [key2, value] of Object.entries(headers)) {
              options.headers[key2.toLowerCase()] = value;
            }
          }
        } else if (websocket.listenerCount("redirect") === 0) {
          const isSameHost = isIpcUrl ? websocket._originalIpc ? opts.socketPath === websocket._originalHostOrSocketPath : false : websocket._originalIpc ? false : parsedUrl.host === websocket._originalHostOrSocketPath;
          if (!isSameHost || websocket._originalSecure && !isSecure) {
            delete opts.headers.authorization;
            delete opts.headers.cookie;
            if (!isSameHost) delete opts.headers.host;
            opts.auth = void 0;
          }
        }
        if (opts.auth && !options.headers.authorization) {
          options.headers.authorization = "Basic " + Buffer.from(opts.auth).toString("base64");
        }
        req = websocket._req = request(opts);
        if (websocket._redirects) {
          websocket.emit("redirect", websocket.url, req);
        }
      } else {
        req = websocket._req = request(opts);
      }
      if (opts.timeout) {
        req.on("timeout", () => {
          abortHandshake(websocket, req, "Opening handshake has timed out");
        });
      }
      req.on("error", (err) => {
        if (req === null || req[kAborted]) return;
        req = websocket._req = null;
        emitErrorAndClose(websocket, err);
      });
      req.on("response", (res) => {
        const location = res.headers.location;
        const statusCode = res.statusCode;
        if (location && opts.followRedirects && statusCode >= 300 && statusCode < 400) {
          if (++websocket._redirects > opts.maxRedirects) {
            abortHandshake(websocket, req, "Maximum redirects exceeded");
            return;
          }
          req.abort();
          let addr;
          try {
            addr = new URL(location, address);
          } catch (e) {
            const err = new SyntaxError(`Invalid URL: ${location}`);
            emitErrorAndClose(websocket, err);
            return;
          }
          initAsClient(websocket, addr, protocols, options);
        } else if (!websocket.emit("unexpected-response", req, res)) {
          abortHandshake(
            websocket,
            req,
            `Unexpected server response: ${res.statusCode}`
          );
        }
      });
      req.on("upgrade", (res, socket, head) => {
        websocket.emit("upgrade", res);
        if (websocket.readyState !== WebSocket2.CONNECTING) return;
        req = websocket._req = null;
        const upgrade = res.headers.upgrade;
        if (upgrade === void 0 || upgrade.toLowerCase() !== "websocket") {
          abortHandshake(websocket, socket, "Invalid Upgrade header");
          return;
        }
        const digest = createHash("sha1").update(key + GUID).digest("base64");
        if (res.headers["sec-websocket-accept"] !== digest) {
          abortHandshake(websocket, socket, "Invalid Sec-WebSocket-Accept header");
          return;
        }
        const serverProt = res.headers["sec-websocket-protocol"];
        let protError;
        if (serverProt !== void 0) {
          if (!protocolSet.size) {
            protError = "Server sent a subprotocol but none was requested";
          } else if (!protocolSet.has(serverProt)) {
            protError = "Server sent an invalid subprotocol";
          }
        } else if (protocolSet.size) {
          protError = "Server sent no subprotocol";
        }
        if (protError) {
          abortHandshake(websocket, socket, protError);
          return;
        }
        if (serverProt) websocket._protocol = serverProt;
        const secWebSocketExtensions = res.headers["sec-websocket-extensions"];
        if (secWebSocketExtensions !== void 0) {
          if (!perMessageDeflate) {
            const message = "Server sent a Sec-WebSocket-Extensions header but no extension was requested";
            abortHandshake(websocket, socket, message);
            return;
          }
          let extensions;
          try {
            extensions = parse(secWebSocketExtensions);
          } catch (err) {
            const message = "Invalid Sec-WebSocket-Extensions header";
            abortHandshake(websocket, socket, message);
            return;
          }
          const extensionNames = Object.keys(extensions);
          if (extensionNames.length !== 1 || extensionNames[0] !== PerMessageDeflate2.extensionName) {
            const message = "Server indicated an extension that was not requested";
            abortHandshake(websocket, socket, message);
            return;
          }
          try {
            perMessageDeflate.accept(extensions[PerMessageDeflate2.extensionName]);
          } catch (err) {
            const message = "Invalid Sec-WebSocket-Extensions header";
            abortHandshake(websocket, socket, message);
            return;
          }
          websocket._extensions[PerMessageDeflate2.extensionName] = perMessageDeflate;
        }
        websocket.setSocket(socket, head, {
          allowSynchronousEvents: opts.allowSynchronousEvents,
          generateMask: opts.generateMask,
          maxPayload: opts.maxPayload,
          skipUTF8Validation: opts.skipUTF8Validation
        });
      });
      if (opts.finishRequest) {
        opts.finishRequest(req, websocket);
      } else {
        req.end();
      }
    }
    function emitErrorAndClose(websocket, err) {
      websocket._readyState = WebSocket2.CLOSING;
      websocket._errorEmitted = true;
      websocket.emit("error", err);
      websocket.emitClose();
    }
    function netConnect(options) {
      options.path = options.socketPath;
      return net.connect(options);
    }
    function tlsConnect(options) {
      options.path = void 0;
      if (!options.servername && options.servername !== "") {
        options.servername = net.isIP(options.host) ? "" : options.host;
      }
      return tls.connect(options);
    }
    function abortHandshake(websocket, stream, message) {
      websocket._readyState = WebSocket2.CLOSING;
      const err = new Error(message);
      Error.captureStackTrace(err, abortHandshake);
      if (stream.setHeader) {
        stream[kAborted] = true;
        stream.abort();
        if (stream.socket && !stream.socket.destroyed) {
          stream.socket.destroy();
        }
        process.nextTick(emitErrorAndClose, websocket, err);
      } else {
        stream.destroy(err);
        stream.once("error", websocket.emit.bind(websocket, "error"));
        stream.once("close", websocket.emitClose.bind(websocket));
      }
    }
    function sendAfterClose(websocket, data, cb) {
      if (data) {
        const length = isBlob(data) ? data.size : toBuffer(data).length;
        if (websocket._socket) websocket._sender._bufferedBytes += length;
        else websocket._bufferedAmount += length;
      }
      if (cb) {
        const err = new Error(
          `WebSocket is not open: readyState ${websocket.readyState} (${readyStates[websocket.readyState]})`
        );
        process.nextTick(cb, err);
      }
    }
    function receiverOnConclude(code, reason) {
      const websocket = this[kWebSocket];
      websocket._closeFrameReceived = true;
      websocket._closeMessage = reason;
      websocket._closeCode = code;
      if (websocket._socket[kWebSocket] === void 0) return;
      websocket._socket.removeListener("data", socketOnData);
      process.nextTick(resume, websocket._socket);
      if (code === 1005) websocket.close();
      else websocket.close(code, reason);
    }
    function receiverOnDrain() {
      const websocket = this[kWebSocket];
      if (!websocket.isPaused) websocket._socket.resume();
    }
    function receiverOnError(err) {
      const websocket = this[kWebSocket];
      if (websocket._socket[kWebSocket] !== void 0) {
        websocket._socket.removeListener("data", socketOnData);
        process.nextTick(resume, websocket._socket);
        websocket.close(err[kStatusCode]);
      }
      if (!websocket._errorEmitted) {
        websocket._errorEmitted = true;
        websocket.emit("error", err);
      }
    }
    function receiverOnFinish() {
      this[kWebSocket].emitClose();
    }
    function receiverOnMessage(data, isBinary) {
      this[kWebSocket].emit("message", data, isBinary);
    }
    function receiverOnPing(data) {
      const websocket = this[kWebSocket];
      if (websocket._autoPong) websocket.pong(data, !this._isServer, NOOP);
      websocket.emit("ping", data);
    }
    function receiverOnPong(data) {
      this[kWebSocket].emit("pong", data);
    }
    function resume(stream) {
      stream.resume();
    }
    function senderOnError(err) {
      const websocket = this[kWebSocket];
      if (websocket.readyState === WebSocket2.CLOSED) return;
      if (websocket.readyState === WebSocket2.OPEN) {
        websocket._readyState = WebSocket2.CLOSING;
        setCloseTimer(websocket);
      }
      this._socket.end();
      if (!websocket._errorEmitted) {
        websocket._errorEmitted = true;
        websocket.emit("error", err);
      }
    }
    function setCloseTimer(websocket) {
      websocket._closeTimer = setTimeout(
        websocket._socket.destroy.bind(websocket._socket),
        websocket._closeTimeout
      );
    }
    function socketOnClose() {
      const websocket = this[kWebSocket];
      this.removeListener("close", socketOnClose);
      this.removeListener("data", socketOnData);
      this.removeListener("end", socketOnEnd);
      websocket._readyState = WebSocket2.CLOSING;
      if (!this._readableState.endEmitted && !websocket._closeFrameReceived && !websocket._receiver._writableState.errorEmitted && this._readableState.length !== 0) {
        const chunk = this.read(this._readableState.length);
        websocket._receiver.write(chunk);
      }
      websocket._receiver.end();
      this[kWebSocket] = void 0;
      clearTimeout(websocket._closeTimer);
      if (websocket._receiver._writableState.finished || websocket._receiver._writableState.errorEmitted) {
        websocket.emitClose();
      } else {
        websocket._receiver.on("error", receiverOnFinish);
        websocket._receiver.on("finish", receiverOnFinish);
      }
    }
    function socketOnData(chunk) {
      if (!this[kWebSocket]._receiver.write(chunk)) {
        this.pause();
      }
    }
    function socketOnEnd() {
      const websocket = this[kWebSocket];
      websocket._readyState = WebSocket2.CLOSING;
      websocket._receiver.end();
      this.end();
    }
    function socketOnError() {
      const websocket = this[kWebSocket];
      this.removeListener("error", socketOnError);
      this.on("error", NOOP);
      if (websocket) {
        websocket._readyState = WebSocket2.CLOSING;
        this.destroy();
      }
    }
  }
});

// node_modules/ws/lib/stream.js
var require_stream = __commonJS({
  "node_modules/ws/lib/stream.js"(exports, module) {
    "use strict";
    var WebSocket2 = require_websocket();
    var { Duplex } = __require("stream");
    function emitClose(stream) {
      stream.emit("close");
    }
    function duplexOnEnd() {
      if (!this.destroyed && this._writableState.finished) {
        this.destroy();
      }
    }
    function duplexOnError(err) {
      this.removeListener("error", duplexOnError);
      this.destroy();
      if (this.listenerCount("error") === 0) {
        this.emit("error", err);
      }
    }
    function createWebSocketStream2(ws, options) {
      let terminateOnDestroy = true;
      const duplex = new Duplex({
        ...options,
        autoDestroy: false,
        emitClose: false,
        objectMode: false,
        writableObjectMode: false
      });
      ws.on("message", function message(msg, isBinary) {
        const data = !isBinary && duplex._readableState.objectMode ? msg.toString() : msg;
        if (!duplex.push(data)) ws.pause();
      });
      ws.once("error", function error(err) {
        if (duplex.destroyed) return;
        terminateOnDestroy = false;
        duplex.destroy(err);
      });
      ws.once("close", function close() {
        if (duplex.destroyed) return;
        duplex.push(null);
      });
      duplex._destroy = function(err, callback) {
        if (ws.readyState === ws.CLOSED) {
          callback(err);
          process.nextTick(emitClose, duplex);
          return;
        }
        let called = false;
        ws.once("error", function error(err2) {
          called = true;
          callback(err2);
        });
        ws.once("close", function close() {
          if (!called) callback(err);
          process.nextTick(emitClose, duplex);
        });
        if (terminateOnDestroy) ws.terminate();
      };
      duplex._final = function(callback) {
        if (ws.readyState === ws.CONNECTING) {
          ws.once("open", function open() {
            duplex._final(callback);
          });
          return;
        }
        if (ws._socket === null) return;
        if (ws._socket._writableState.finished) {
          callback();
          if (duplex._readableState.endEmitted) duplex.destroy();
        } else {
          ws._socket.once("finish", function finish() {
            callback();
          });
          ws.close();
        }
      };
      duplex._read = function() {
        if (ws.isPaused) ws.resume();
      };
      duplex._write = function(chunk, encoding, callback) {
        if (ws.readyState === ws.CONNECTING) {
          ws.once("open", function open() {
            duplex._write(chunk, encoding, callback);
          });
          return;
        }
        ws.send(chunk, callback);
      };
      duplex.on("end", duplexOnEnd);
      duplex.on("error", duplexOnError);
      return duplex;
    }
    module.exports = createWebSocketStream2;
  }
});

// node_modules/ws/lib/subprotocol.js
var require_subprotocol = __commonJS({
  "node_modules/ws/lib/subprotocol.js"(exports, module) {
    "use strict";
    var { tokenChars } = require_validation();
    function parse(header) {
      const protocols = /* @__PURE__ */ new Set();
      let start = -1;
      let end = -1;
      let i = 0;
      for (i; i < header.length; i++) {
        const code = header.charCodeAt(i);
        if (end === -1 && tokenChars[code] === 1) {
          if (start === -1) start = i;
        } else if (i !== 0 && (code === 32 || code === 9)) {
          if (end === -1 && start !== -1) end = i;
        } else if (code === 44) {
          if (start === -1) {
            throw new SyntaxError(`Unexpected character at index ${i}`);
          }
          if (end === -1) end = i;
          const protocol2 = header.slice(start, end);
          if (protocols.has(protocol2)) {
            throw new SyntaxError(`The "${protocol2}" subprotocol is duplicated`);
          }
          protocols.add(protocol2);
          start = end = -1;
        } else {
          throw new SyntaxError(`Unexpected character at index ${i}`);
        }
      }
      if (start === -1 || end !== -1) {
        throw new SyntaxError("Unexpected end of input");
      }
      const protocol = header.slice(start, i);
      if (protocols.has(protocol)) {
        throw new SyntaxError(`The "${protocol}" subprotocol is duplicated`);
      }
      protocols.add(protocol);
      return protocols;
    }
    module.exports = { parse };
  }
});

// node_modules/ws/lib/websocket-server.js
var require_websocket_server = __commonJS({
  "node_modules/ws/lib/websocket-server.js"(exports, module) {
    "use strict";
    var EventEmitter3 = __require("events");
    var http = __require("http");
    var { Duplex } = __require("stream");
    var { createHash } = __require("crypto");
    var extension2 = require_extension();
    var PerMessageDeflate2 = require_permessage_deflate();
    var subprotocol2 = require_subprotocol();
    var WebSocket2 = require_websocket();
    var { CLOSE_TIMEOUT, GUID, kWebSocket } = require_constants2();
    var keyRegex = /^[+/0-9A-Za-z]{22}==$/;
    var RUNNING = 0;
    var CLOSING = 1;
    var CLOSED = 2;
    var WebSocketServer2 = class extends EventEmitter3 {
      /**
       * Create a `WebSocketServer` instance.
       *
       * @param {Object} options Configuration options
       * @param {Boolean} [options.allowSynchronousEvents=true] Specifies whether
       *     any of the `'message'`, `'ping'`, and `'pong'` events can be emitted
       *     multiple times in the same tick
       * @param {Boolean} [options.autoPong=true] Specifies whether or not to
       *     automatically send a pong in response to a ping
       * @param {Number} [options.backlog=511] The maximum length of the queue of
       *     pending connections
       * @param {Boolean} [options.clientTracking=true] Specifies whether or not to
       *     track clients
       * @param {Number} [options.closeTimeout=30000] Duration in milliseconds to
       *     wait for the closing handshake to finish after `websocket.close()` is
       *     called
       * @param {Function} [options.handleProtocols] A hook to handle protocols
       * @param {String} [options.host] The hostname where to bind the server
       * @param {Number} [options.maxPayload=104857600] The maximum allowed message
       *     size
       * @param {Boolean} [options.noServer=false] Enable no server mode
       * @param {String} [options.path] Accept only connections matching this path
       * @param {(Boolean|Object)} [options.perMessageDeflate=false] Enable/disable
       *     permessage-deflate
       * @param {Number} [options.port] The port where to bind the server
       * @param {(http.Server|https.Server)} [options.server] A pre-created HTTP/S
       *     server to use
       * @param {Boolean} [options.skipUTF8Validation=false] Specifies whether or
       *     not to skip UTF-8 validation for text and close messages
       * @param {Function} [options.verifyClient] A hook to reject connections
       * @param {Function} [options.WebSocket=WebSocket] Specifies the `WebSocket`
       *     class to use. It must be the `WebSocket` class or class that extends it
       * @param {Function} [callback] A listener for the `listening` event
       */
      constructor(options, callback) {
        super();
        options = {
          allowSynchronousEvents: true,
          autoPong: true,
          maxPayload: 100 * 1024 * 1024,
          skipUTF8Validation: false,
          perMessageDeflate: false,
          handleProtocols: null,
          clientTracking: true,
          closeTimeout: CLOSE_TIMEOUT,
          verifyClient: null,
          noServer: false,
          backlog: null,
          // use default (511 as implemented in net.js)
          server: null,
          host: null,
          path: null,
          port: null,
          WebSocket: WebSocket2,
          ...options
        };
        if (options.port == null && !options.server && !options.noServer || options.port != null && (options.server || options.noServer) || options.server && options.noServer) {
          throw new TypeError(
            'One and only one of the "port", "server", or "noServer" options must be specified'
          );
        }
        if (options.port != null) {
          this._server = http.createServer((req, res) => {
            const body = http.STATUS_CODES[426];
            res.writeHead(426, {
              "Content-Length": body.length,
              "Content-Type": "text/plain"
            });
            res.end(body);
          });
          this._server.listen(
            options.port,
            options.host,
            options.backlog,
            callback
          );
        } else if (options.server) {
          this._server = options.server;
        }
        if (this._server) {
          const emitConnection = this.emit.bind(this, "connection");
          this._removeListeners = addListeners(this._server, {
            listening: this.emit.bind(this, "listening"),
            error: this.emit.bind(this, "error"),
            upgrade: (req, socket, head) => {
              this.handleUpgrade(req, socket, head, emitConnection);
            }
          });
        }
        if (options.perMessageDeflate === true) options.perMessageDeflate = {};
        if (options.clientTracking) {
          this.clients = /* @__PURE__ */ new Set();
          this._shouldEmitClose = false;
        }
        this.options = options;
        this._state = RUNNING;
      }
      /**
       * Returns the bound address, the address family name, and port of the server
       * as reported by the operating system if listening on an IP socket.
       * If the server is listening on a pipe or UNIX domain socket, the name is
       * returned as a string.
       *
       * @return {(Object|String|null)} The address of the server
       * @public
       */
      address() {
        if (this.options.noServer) {
          throw new Error('The server is operating in "noServer" mode');
        }
        if (!this._server) return null;
        return this._server.address();
      }
      /**
       * Stop the server from accepting new connections and emit the `'close'` event
       * when all existing connections are closed.
       *
       * @param {Function} [cb] A one-time listener for the `'close'` event
       * @public
       */
      close(cb) {
        if (this._state === CLOSED) {
          if (cb) {
            this.once("close", () => {
              cb(new Error("The server is not running"));
            });
          }
          process.nextTick(emitClose, this);
          return;
        }
        if (cb) this.once("close", cb);
        if (this._state === CLOSING) return;
        this._state = CLOSING;
        if (this.options.noServer || this.options.server) {
          if (this._server) {
            this._removeListeners();
            this._removeListeners = this._server = null;
          }
          if (this.clients) {
            if (!this.clients.size) {
              process.nextTick(emitClose, this);
            } else {
              this._shouldEmitClose = true;
            }
          } else {
            process.nextTick(emitClose, this);
          }
        } else {
          const server = this._server;
          this._removeListeners();
          this._removeListeners = this._server = null;
          server.close(() => {
            emitClose(this);
          });
        }
      }
      /**
       * See if a given request should be handled by this server instance.
       *
       * @param {http.IncomingMessage} req Request object to inspect
       * @return {Boolean} `true` if the request is valid, else `false`
       * @public
       */
      shouldHandle(req) {
        if (this.options.path) {
          const index = req.url.indexOf("?");
          const pathname = index !== -1 ? req.url.slice(0, index) : req.url;
          if (pathname !== this.options.path) return false;
        }
        return true;
      }
      /**
       * Handle a HTTP Upgrade request.
       *
       * @param {http.IncomingMessage} req The request object
       * @param {Duplex} socket The network socket between the server and client
       * @param {Buffer} head The first packet of the upgraded stream
       * @param {Function} cb Callback
       * @public
       */
      handleUpgrade(req, socket, head, cb) {
        socket.on("error", socketOnError);
        const key = req.headers["sec-websocket-key"];
        const upgrade = req.headers.upgrade;
        const version = +req.headers["sec-websocket-version"];
        if (req.method !== "GET") {
          const message = "Invalid HTTP method";
          abortHandshakeOrEmitwsClientError(this, req, socket, 405, message);
          return;
        }
        if (upgrade === void 0 || upgrade.toLowerCase() !== "websocket") {
          const message = "Invalid Upgrade header";
          abortHandshakeOrEmitwsClientError(this, req, socket, 400, message);
          return;
        }
        if (key === void 0 || !keyRegex.test(key)) {
          const message = "Missing or invalid Sec-WebSocket-Key header";
          abortHandshakeOrEmitwsClientError(this, req, socket, 400, message);
          return;
        }
        if (version !== 13 && version !== 8) {
          const message = "Missing or invalid Sec-WebSocket-Version header";
          abortHandshakeOrEmitwsClientError(this, req, socket, 400, message, {
            "Sec-WebSocket-Version": "13, 8"
          });
          return;
        }
        if (!this.shouldHandle(req)) {
          abortHandshake(socket, 400);
          return;
        }
        const secWebSocketProtocol = req.headers["sec-websocket-protocol"];
        let protocols = /* @__PURE__ */ new Set();
        if (secWebSocketProtocol !== void 0) {
          try {
            protocols = subprotocol2.parse(secWebSocketProtocol);
          } catch (err) {
            const message = "Invalid Sec-WebSocket-Protocol header";
            abortHandshakeOrEmitwsClientError(this, req, socket, 400, message);
            return;
          }
        }
        const secWebSocketExtensions = req.headers["sec-websocket-extensions"];
        const extensions = {};
        if (this.options.perMessageDeflate && secWebSocketExtensions !== void 0) {
          const perMessageDeflate = new PerMessageDeflate2({
            ...this.options.perMessageDeflate,
            isServer: true,
            maxPayload: this.options.maxPayload
          });
          try {
            const offers = extension2.parse(secWebSocketExtensions);
            if (offers[PerMessageDeflate2.extensionName]) {
              perMessageDeflate.accept(offers[PerMessageDeflate2.extensionName]);
              extensions[PerMessageDeflate2.extensionName] = perMessageDeflate;
            }
          } catch (err) {
            const message = "Invalid or unacceptable Sec-WebSocket-Extensions header";
            abortHandshakeOrEmitwsClientError(this, req, socket, 400, message);
            return;
          }
        }
        if (this.options.verifyClient) {
          const info = {
            origin: req.headers[`${version === 8 ? "sec-websocket-origin" : "origin"}`],
            secure: !!(req.socket.authorized || req.socket.encrypted),
            req
          };
          if (this.options.verifyClient.length === 2) {
            this.options.verifyClient(info, (verified, code, message, headers) => {
              if (!verified) {
                return abortHandshake(socket, code || 401, message, headers);
              }
              this.completeUpgrade(
                extensions,
                key,
                protocols,
                req,
                socket,
                head,
                cb
              );
            });
            return;
          }
          if (!this.options.verifyClient(info)) return abortHandshake(socket, 401);
        }
        this.completeUpgrade(extensions, key, protocols, req, socket, head, cb);
      }
      /**
       * Upgrade the connection to WebSocket.
       *
       * @param {Object} extensions The accepted extensions
       * @param {String} key The value of the `Sec-WebSocket-Key` header
       * @param {Set} protocols The subprotocols
       * @param {http.IncomingMessage} req The request object
       * @param {Duplex} socket The network socket between the server and client
       * @param {Buffer} head The first packet of the upgraded stream
       * @param {Function} cb Callback
       * @throws {Error} If called more than once with the same socket
       * @private
       */
      completeUpgrade(extensions, key, protocols, req, socket, head, cb) {
        if (!socket.readable || !socket.writable) return socket.destroy();
        if (socket[kWebSocket]) {
          throw new Error(
            "server.handleUpgrade() was called more than once with the same socket, possibly due to a misconfiguration"
          );
        }
        if (this._state > RUNNING) return abortHandshake(socket, 503);
        const digest = createHash("sha1").update(key + GUID).digest("base64");
        const headers = [
          "HTTP/1.1 101 Switching Protocols",
          "Upgrade: websocket",
          "Connection: Upgrade",
          `Sec-WebSocket-Accept: ${digest}`
        ];
        const ws = new this.options.WebSocket(null, void 0, this.options);
        if (protocols.size) {
          const protocol = this.options.handleProtocols ? this.options.handleProtocols(protocols, req) : protocols.values().next().value;
          if (protocol) {
            headers.push(`Sec-WebSocket-Protocol: ${protocol}`);
            ws._protocol = protocol;
          }
        }
        if (extensions[PerMessageDeflate2.extensionName]) {
          const params = extensions[PerMessageDeflate2.extensionName].params;
          const value = extension2.format({
            [PerMessageDeflate2.extensionName]: [params]
          });
          headers.push(`Sec-WebSocket-Extensions: ${value}`);
          ws._extensions = extensions;
        }
        this.emit("headers", headers, req);
        socket.write(headers.concat("\r\n").join("\r\n"));
        socket.removeListener("error", socketOnError);
        ws.setSocket(socket, head, {
          allowSynchronousEvents: this.options.allowSynchronousEvents,
          maxPayload: this.options.maxPayload,
          skipUTF8Validation: this.options.skipUTF8Validation
        });
        if (this.clients) {
          this.clients.add(ws);
          ws.on("close", () => {
            this.clients.delete(ws);
            if (this._shouldEmitClose && !this.clients.size) {
              process.nextTick(emitClose, this);
            }
          });
        }
        cb(ws, req);
      }
    };
    module.exports = WebSocketServer2;
    function addListeners(server, map) {
      for (const event of Object.keys(map)) server.on(event, map[event]);
      return function removeListeners() {
        for (const event of Object.keys(map)) {
          server.removeListener(event, map[event]);
        }
      };
    }
    function emitClose(server) {
      server._state = CLOSED;
      server.emit("close");
    }
    function socketOnError() {
      this.destroy();
    }
    function abortHandshake(socket, code, message, headers) {
      message = message || http.STATUS_CODES[code];
      headers = {
        Connection: "close",
        "Content-Type": "text/html",
        "Content-Length": Buffer.byteLength(message),
        ...headers
      };
      socket.once("finish", socket.destroy);
      socket.end(
        `HTTP/1.1 ${code} ${http.STATUS_CODES[code]}\r
` + Object.keys(headers).map((h) => `${h}: ${headers[h]}`).join("\r\n") + "\r\n\r\n" + message
      );
    }
    function abortHandshakeOrEmitwsClientError(server, req, socket, code, message, headers) {
      if (server.listenerCount("wsClientError")) {
        const err = new Error(message);
        Error.captureStackTrace(err, abortHandshakeOrEmitwsClientError);
        server.emit("wsClientError", err, socket, req);
      } else {
        abortHandshake(socket, code, message, headers);
      }
    }
  }
});

// node_modules/ws/wrapper.mjs
var import_stream, import_extension, import_permessage_deflate, import_receiver, import_sender, import_subprotocol, import_websocket, import_websocket_server, wrapper_default;
var init_wrapper = __esm({
  "node_modules/ws/wrapper.mjs"() {
    "use strict";
    import_stream = __toESM(require_stream(), 1);
    import_extension = __toESM(require_extension(), 1);
    import_permessage_deflate = __toESM(require_permessage_deflate(), 1);
    import_receiver = __toESM(require_receiver(), 1);
    import_sender = __toESM(require_sender(), 1);
    import_subprotocol = __toESM(require_subprotocol(), 1);
    import_websocket = __toESM(require_websocket(), 1);
    import_websocket_server = __toESM(require_websocket_server(), 1);
    wrapper_default = import_websocket.default;
  }
});

// node_modules/ink/build/devtools-window-polyfill.js
var customGlobal;
var init_devtools_window_polyfill = __esm({
  "node_modules/ink/build/devtools-window-polyfill.js"() {
    "use strict";
    init_wrapper();
    customGlobal = global;
    customGlobal.WebSocket ||= wrapper_default;
    customGlobal.window ||= global;
    customGlobal.self ||= global;
    customGlobal.window.__REACT_DEVTOOLS_COMPONENT_FILTERS__ = [
      {
        // ComponentFilterElementType
        type: 1,
        // ElementTypeHostComponent
        value: 7,
        isEnabled: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalApp",
        isEnabled: true,
        isValid: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalAppContext",
        isEnabled: true,
        isValid: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalStdoutContext",
        isEnabled: true,
        isValid: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalStderrContext",
        isEnabled: true,
        isValid: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalStdinContext",
        isEnabled: true,
        isValid: true
      },
      {
        // ComponentFilterDisplayName
        type: 2,
        value: "InternalFocusContext",
        isEnabled: true,
        isValid: true
      }
    ];
  }
});

// stubs/react-devtools-core.js
var react_devtools_core_default;
var init_react_devtools_core = __esm({
  "stubs/react-devtools-core.js"() {
    "use strict";
    react_devtools_core_default = { connectToDevTools: () => {
    } };
  }
});

// node_modules/ink/build/devtools.js
var devtools_exports = {};
var init_devtools = __esm({
  "node_modules/ink/build/devtools.js"() {
    "use strict";
    init_devtools_window_polyfill();
    init_react_devtools_core();
    react_devtools_core_default.connectToDevTools();
  }
});

// node_modules/cli-boxes/boxes.json
var require_boxes = __commonJS({
  "node_modules/cli-boxes/boxes.json"(exports, module) {
    module.exports = {
      single: {
        topLeft: "\u250C",
        top: "\u2500",
        topRight: "\u2510",
        right: "\u2502",
        bottomRight: "\u2518",
        bottom: "\u2500",
        bottomLeft: "\u2514",
        left: "\u2502"
      },
      double: {
        topLeft: "\u2554",
        top: "\u2550",
        topRight: "\u2557",
        right: "\u2551",
        bottomRight: "\u255D",
        bottom: "\u2550",
        bottomLeft: "\u255A",
        left: "\u2551"
      },
      round: {
        topLeft: "\u256D",
        top: "\u2500",
        topRight: "\u256E",
        right: "\u2502",
        bottomRight: "\u256F",
        bottom: "\u2500",
        bottomLeft: "\u2570",
        left: "\u2502"
      },
      bold: {
        topLeft: "\u250F",
        top: "\u2501",
        topRight: "\u2513",
        right: "\u2503",
        bottomRight: "\u251B",
        bottom: "\u2501",
        bottomLeft: "\u2517",
        left: "\u2503"
      },
      singleDouble: {
        topLeft: "\u2553",
        top: "\u2500",
        topRight: "\u2556",
        right: "\u2551",
        bottomRight: "\u255C",
        bottom: "\u2500",
        bottomLeft: "\u2559",
        left: "\u2551"
      },
      doubleSingle: {
        topLeft: "\u2552",
        top: "\u2550",
        topRight: "\u2555",
        right: "\u2502",
        bottomRight: "\u255B",
        bottom: "\u2550",
        bottomLeft: "\u2558",
        left: "\u2502"
      },
      classic: {
        topLeft: "+",
        top: "-",
        topRight: "+",
        right: "|",
        bottomRight: "+",
        bottom: "-",
        bottomLeft: "+",
        left: "|"
      },
      arrow: {
        topLeft: "\u2198",
        top: "\u2193",
        topRight: "\u2199",
        right: "\u2190",
        bottomRight: "\u2196",
        bottom: "\u2191",
        bottomLeft: "\u2197",
        left: "\u2192"
      }
    };
  }
});

// node_modules/cli-boxes/index.js
var require_cli_boxes = __commonJS({
  "node_modules/cli-boxes/index.js"(exports, module) {
    "use strict";
    var cliBoxes2 = require_boxes();
    module.exports = cliBoxes2;
    module.exports.default = cliBoxes2;
  }
});

// node_modules/mimic-fn/index.js
var require_mimic_fn = __commonJS({
  "node_modules/mimic-fn/index.js"(exports, module) {
    "use strict";
    var mimicFn = (to, from) => {
      for (const prop of Reflect.ownKeys(from)) {
        Object.defineProperty(to, prop, Object.getOwnPropertyDescriptor(from, prop));
      }
      return to;
    };
    module.exports = mimicFn;
    module.exports.default = mimicFn;
  }
});

// node_modules/onetime/index.js
var require_onetime = __commonJS({
  "node_modules/onetime/index.js"(exports, module) {
    "use strict";
    var mimicFn = require_mimic_fn();
    var calledFunctions = /* @__PURE__ */ new WeakMap();
    var onetime2 = (function_, options = {}) => {
      if (typeof function_ !== "function") {
        throw new TypeError("Expected a function");
      }
      let returnValue;
      let callCount = 0;
      const functionName = function_.displayName || function_.name || "<anonymous>";
      const onetime3 = function(...arguments_) {
        calledFunctions.set(onetime3, ++callCount);
        if (callCount === 1) {
          returnValue = function_.apply(this, arguments_);
          function_ = null;
        } else if (options.throw === true) {
          throw new Error(`Function \`${functionName}\` can only be called once`);
        }
        return returnValue;
      };
      mimicFn(onetime3, function_);
      calledFunctions.set(onetime3, callCount);
      return onetime3;
    };
    module.exports = onetime2;
    module.exports.default = onetime2;
    module.exports.callCount = (function_) => {
      if (!calledFunctions.has(function_)) {
        throw new Error(`The given function \`${function_.name}\` is not wrapped by the \`onetime\` package`);
      }
      return calledFunctions.get(function_);
    };
  }
});

// node_modules/escape-string-regexp/index.js
var require_escape_string_regexp = __commonJS({
  "node_modules/escape-string-regexp/index.js"(exports, module) {
    "use strict";
    var matchOperatorsRegex = /[|\\{}()[\]^$+*?.-]/g;
    module.exports = (string) => {
      if (typeof string !== "string") {
        throw new TypeError("Expected a string");
      }
      return string.replace(matchOperatorsRegex, "\\$&");
    };
  }
});

// node_modules/stack-utils/index.js
var require_stack_utils = __commonJS({
  "node_modules/stack-utils/index.js"(exports, module) {
    "use strict";
    var escapeStringRegexp = require_escape_string_regexp();
    var cwd2 = typeof process === "object" && process && typeof process.cwd === "function" ? process.cwd() : ".";
    var natives = [].concat(
      __require("module").builtinModules,
      "bootstrap_node",
      "node"
    ).map((n) => new RegExp(`(?:\\((?:node:)?${n}(?:\\.js)?:\\d+:\\d+\\)$|^\\s*at (?:node:)?${n}(?:\\.js)?:\\d+:\\d+$)`));
    natives.push(
      /\((?:node:)?internal\/[^:]+:\d+:\d+\)$/,
      /\s*at (?:node:)?internal\/[^:]+:\d+:\d+$/,
      /\/\.node-spawn-wrap-\w+-\w+\/node:\d+:\d+\)?$/
    );
    var StackUtils2 = class _StackUtils {
      constructor(opts) {
        opts = {
          ignoredPackages: [],
          ...opts
        };
        if ("internals" in opts === false) {
          opts.internals = _StackUtils.nodeInternals();
        }
        if ("cwd" in opts === false) {
          opts.cwd = cwd2;
        }
        this._cwd = opts.cwd.replace(/\\/g, "/");
        this._internals = [].concat(
          opts.internals,
          ignoredPackagesRegExp(opts.ignoredPackages)
        );
        this._wrapCallSite = opts.wrapCallSite || false;
      }
      static nodeInternals() {
        return [...natives];
      }
      clean(stack, indent = 0) {
        indent = " ".repeat(indent);
        if (!Array.isArray(stack)) {
          stack = stack.split("\n");
        }
        if (!/^\s*at /.test(stack[0]) && /^\s*at /.test(stack[1])) {
          stack = stack.slice(1);
        }
        let outdent = false;
        let lastNonAtLine = null;
        const result = [];
        stack.forEach((st) => {
          st = st.replace(/\\/g, "/");
          if (this._internals.some((internal) => internal.test(st))) {
            return;
          }
          const isAtLine = /^\s*at /.test(st);
          if (outdent) {
            st = st.trimEnd().replace(/^(\s+)at /, "$1");
          } else {
            st = st.trim();
            if (isAtLine) {
              st = st.slice(3);
            }
          }
          st = st.replace(`${this._cwd}/`, "");
          if (st) {
            if (isAtLine) {
              if (lastNonAtLine) {
                result.push(lastNonAtLine);
                lastNonAtLine = null;
              }
              result.push(st);
            } else {
              outdent = true;
              lastNonAtLine = st;
            }
          }
        });
        return result.map((line) => `${indent}${line}
`).join("");
      }
      captureString(limit, fn = this.captureString) {
        if (typeof limit === "function") {
          fn = limit;
          limit = Infinity;
        }
        const { stackTraceLimit } = Error;
        if (limit) {
          Error.stackTraceLimit = limit;
        }
        const obj = {};
        Error.captureStackTrace(obj, fn);
        const { stack } = obj;
        Error.stackTraceLimit = stackTraceLimit;
        return this.clean(stack);
      }
      capture(limit, fn = this.capture) {
        if (typeof limit === "function") {
          fn = limit;
          limit = Infinity;
        }
        const { prepareStackTrace, stackTraceLimit } = Error;
        Error.prepareStackTrace = (obj2, site) => {
          if (this._wrapCallSite) {
            return site.map(this._wrapCallSite);
          }
          return site;
        };
        if (limit) {
          Error.stackTraceLimit = limit;
        }
        const obj = {};
        Error.captureStackTrace(obj, fn);
        const { stack } = obj;
        Object.assign(Error, { prepareStackTrace, stackTraceLimit });
        return stack;
      }
      at(fn = this.at) {
        const [site] = this.capture(1, fn);
        if (!site) {
          return {};
        }
        const res = {
          line: site.getLineNumber(),
          column: site.getColumnNumber()
        };
        setFile(res, site.getFileName(), this._cwd);
        if (site.isConstructor()) {
          Object.defineProperty(res, "constructor", {
            value: true,
            configurable: true
          });
        }
        if (site.isEval()) {
          res.evalOrigin = site.getEvalOrigin();
        }
        if (site.isNative()) {
          res.native = true;
        }
        let typename;
        try {
          typename = site.getTypeName();
        } catch (_) {
        }
        if (typename && typename !== "Object" && typename !== "[object Object]") {
          res.type = typename;
        }
        const fname = site.getFunctionName();
        if (fname) {
          res.function = fname;
        }
        const meth = site.getMethodName();
        if (meth && fname !== meth) {
          res.method = meth;
        }
        return res;
      }
      parseLine(line) {
        const match = line && line.match(re);
        if (!match) {
          return null;
        }
        const ctor = match[1] === "new";
        let fname = match[2];
        const evalOrigin = match[3];
        const evalFile = match[4];
        const evalLine = Number(match[5]);
        const evalCol = Number(match[6]);
        let file = match[7];
        const lnum = match[8];
        const col = match[9];
        const native = match[10] === "native";
        const closeParen = match[11] === ")";
        let method;
        const res = {};
        if (lnum) {
          res.line = Number(lnum);
        }
        if (col) {
          res.column = Number(col);
        }
        if (closeParen && file) {
          let closes = 0;
          for (let i = file.length - 1; i > 0; i--) {
            if (file.charAt(i) === ")") {
              closes++;
            } else if (file.charAt(i) === "(" && file.charAt(i - 1) === " ") {
              closes--;
              if (closes === -1 && file.charAt(i - 1) === " ") {
                const before = file.slice(0, i - 1);
                const after = file.slice(i + 1);
                file = after;
                fname += ` (${before}`;
                break;
              }
            }
          }
        }
        if (fname) {
          const methodMatch = fname.match(methodRe);
          if (methodMatch) {
            fname = methodMatch[1];
            method = methodMatch[2];
          }
        }
        setFile(res, file, this._cwd);
        if (ctor) {
          Object.defineProperty(res, "constructor", {
            value: true,
            configurable: true
          });
        }
        if (evalOrigin) {
          res.evalOrigin = evalOrigin;
          res.evalLine = evalLine;
          res.evalColumn = evalCol;
          res.evalFile = evalFile && evalFile.replace(/\\/g, "/");
        }
        if (native) {
          res.native = true;
        }
        if (fname) {
          res.function = fname;
        }
        if (method && fname !== method) {
          res.method = method;
        }
        return res;
      }
    };
    function setFile(result, filename, cwd3) {
      if (filename) {
        filename = filename.replace(/\\/g, "/");
        if (filename.startsWith(`${cwd3}/`)) {
          filename = filename.slice(cwd3.length + 1);
        }
        result.file = filename;
      }
    }
    function ignoredPackagesRegExp(ignoredPackages) {
      if (ignoredPackages.length === 0) {
        return [];
      }
      const packages = ignoredPackages.map((mod) => escapeStringRegexp(mod));
      return new RegExp(`[/\\\\]node_modules[/\\\\](?:${packages.join("|")})[/\\\\][^:]+:\\d+:\\d+`);
    }
    var re = new RegExp(
      "^(?:\\s*at )?(?:(new) )?(?:(.*?) \\()?(?:eval at ([^ ]+) \\((.+?):(\\d+):(\\d+)\\), )?(?:(.+?):(\\d+):(\\d+)|(native))(\\)?)$"
    );
    var methodRe = /^(.*?) \[as (.*?)\]$/;
    module.exports = StackUtils2;
  }
});

// node_modules/react/cjs/react-jsx-runtime.production.min.js
var require_react_jsx_runtime_production_min = __commonJS({
  "node_modules/react/cjs/react-jsx-runtime.production.min.js"(exports) {
    "use strict";
    var f = require_react();
    var k = /* @__PURE__ */ Symbol.for("react.element");
    var l = /* @__PURE__ */ Symbol.for("react.fragment");
    var m = Object.prototype.hasOwnProperty;
    var n = f.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner;
    var p = { key: true, ref: true, __self: true, __source: true };
    function q(c, a, g) {
      var b, d = {}, e = null, h = null;
      void 0 !== g && (e = "" + g);
      void 0 !== a.key && (e = "" + a.key);
      void 0 !== a.ref && (h = a.ref);
      for (b in a) m.call(a, b) && !p.hasOwnProperty(b) && (d[b] = a[b]);
      if (c && c.defaultProps) for (b in a = c.defaultProps, a) void 0 === d[b] && (d[b] = a[b]);
      return { $$typeof: k, type: c, key: e, ref: h, props: d, _owner: n.current };
    }
    exports.Fragment = l;
    exports.jsx = q;
    exports.jsxs = q;
  }
});

// node_modules/react/jsx-runtime.js
var require_jsx_runtime = __commonJS({
  "node_modules/react/jsx-runtime.js"(exports, module) {
    "use strict";
    if (true) {
      module.exports = require_react_jsx_runtime_production_min();
    } else {
      module.exports = null;
    }
  }
});

// node_modules/ink/build/render.js
import { Stream } from "stream";
import process12 from "process";

// node_modules/ink/build/ink.js
var import_react10 = __toESM(require_react(), 1);
import process11 from "process";

// node_modules/es-toolkit/dist/function/debounce.mjs
function debounce(func, debounceMs, { signal, edges } = {}) {
  let pendingThis = void 0;
  let pendingArgs = null;
  const leading = edges != null && edges.includes("leading");
  const trailing = edges == null || edges.includes("trailing");
  const invoke = () => {
    if (pendingArgs !== null) {
      func.apply(pendingThis, pendingArgs);
      pendingThis = void 0;
      pendingArgs = null;
    }
  };
  const onTimerEnd = () => {
    if (trailing) {
      invoke();
    }
    cancel();
  };
  let timeoutId = null;
  const schedule = () => {
    if (timeoutId != null) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => {
      timeoutId = null;
      onTimerEnd();
    }, debounceMs);
  };
  const cancelTimer = () => {
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
      timeoutId = null;
    }
  };
  const cancel = () => {
    cancelTimer();
    pendingThis = void 0;
    pendingArgs = null;
  };
  const flush = () => {
    invoke();
  };
  const debounced = function(...args) {
    if (signal?.aborted) {
      return;
    }
    pendingThis = this;
    pendingArgs = args;
    const isFirstCall = timeoutId == null;
    schedule();
    if (leading && isFirstCall) {
      invoke();
    }
  };
  debounced.schedule = schedule;
  debounced.cancel = cancel;
  debounced.flush = flush;
  signal?.addEventListener("abort", cancel, { once: true });
  return debounced;
}

// node_modules/es-toolkit/dist/compat/function/debounce.mjs
function debounce2(func, debounceMs = 0, options = {}) {
  if (typeof options !== "object") {
    options = {};
  }
  const { leading = false, trailing = true, maxWait } = options;
  const edges = Array(2);
  if (leading) {
    edges[0] = "leading";
  }
  if (trailing) {
    edges[1] = "trailing";
  }
  let result = void 0;
  let pendingAt = null;
  const _debounced = debounce(function(...args) {
    result = func.apply(this, args);
    pendingAt = null;
  }, debounceMs, { edges });
  const debounced = function(...args) {
    if (maxWait != null) {
      if (pendingAt === null) {
        pendingAt = Date.now();
      }
      if (Date.now() - pendingAt >= maxWait) {
        result = func.apply(this, args);
        pendingAt = Date.now();
        _debounced.cancel();
        _debounced.schedule();
        return result;
      }
    }
    _debounced.apply(this, args);
    return result;
  };
  const flush = () => {
    _debounced.flush();
    return result;
  };
  debounced.cancel = _debounced.cancel;
  debounced.flush = flush;
  return debounced;
}

// node_modules/es-toolkit/dist/compat/function/throttle.mjs
function throttle(func, throttleMs = 0, options = {}) {
  const { leading = true, trailing = true } = options;
  return debounce2(func, throttleMs, {
    leading,
    maxWait: throttleMs,
    trailing
  });
}

// node_modules/ansi-escapes/base.js
var base_exports = {};
__export(base_exports, {
  ConEmu: () => ConEmu,
  beep: () => beep,
  beginSynchronizedOutput: () => beginSynchronizedOutput,
  clearScreen: () => clearScreen,
  clearTerminal: () => clearTerminal,
  clearViewport: () => clearViewport,
  cursorBackward: () => cursorBackward,
  cursorDown: () => cursorDown,
  cursorForward: () => cursorForward,
  cursorGetPosition: () => cursorGetPosition,
  cursorHide: () => cursorHide,
  cursorLeft: () => cursorLeft,
  cursorMove: () => cursorMove,
  cursorNextLine: () => cursorNextLine,
  cursorPrevLine: () => cursorPrevLine,
  cursorRestorePosition: () => cursorRestorePosition,
  cursorSavePosition: () => cursorSavePosition,
  cursorShow: () => cursorShow,
  cursorTo: () => cursorTo,
  cursorUp: () => cursorUp,
  endSynchronizedOutput: () => endSynchronizedOutput,
  enterAlternativeScreen: () => enterAlternativeScreen,
  eraseDown: () => eraseDown,
  eraseEndLine: () => eraseEndLine,
  eraseLine: () => eraseLine,
  eraseLines: () => eraseLines,
  eraseScreen: () => eraseScreen,
  eraseStartLine: () => eraseStartLine,
  eraseUp: () => eraseUp,
  exitAlternativeScreen: () => exitAlternativeScreen,
  iTerm: () => iTerm,
  image: () => image,
  link: () => link,
  scrollDown: () => scrollDown,
  scrollUp: () => scrollUp,
  setCwd: () => setCwd,
  synchronizedOutput: () => synchronizedOutput
});
import process2 from "process";
import os from "os";

// node_modules/environment/index.js
var isBrowser = globalThis.window?.document !== void 0;
var isNode = globalThis.process?.versions?.node !== void 0;
var isBun = globalThis.process?.versions?.bun !== void 0;
var isDeno = globalThis.Deno?.version?.deno !== void 0;
var isElectron = globalThis.process?.versions?.electron !== void 0;
var isJsDom = globalThis.navigator?.userAgent?.includes("jsdom") === true;
var isWebWorker = typeof WorkerGlobalScope !== "undefined" && globalThis instanceof WorkerGlobalScope;
var isDedicatedWorker = typeof DedicatedWorkerGlobalScope !== "undefined" && globalThis instanceof DedicatedWorkerGlobalScope;
var isSharedWorker = typeof SharedWorkerGlobalScope !== "undefined" && globalThis instanceof SharedWorkerGlobalScope;
var isServiceWorker = typeof ServiceWorkerGlobalScope !== "undefined" && globalThis instanceof ServiceWorkerGlobalScope;
var platform = globalThis.navigator?.userAgentData?.platform;
var isMacOs = platform === "macOS" || globalThis.navigator?.platform === "MacIntel" || globalThis.navigator?.userAgent?.includes(" Mac ") === true || globalThis.process?.platform === "darwin";
var isWindows = platform === "Windows" || globalThis.navigator?.platform === "Win32" || globalThis.process?.platform === "win32";
var isLinux = platform === "Linux" || globalThis.navigator?.platform?.startsWith("Linux") === true || globalThis.navigator?.userAgent?.includes(" Linux ") === true || globalThis.process?.platform === "linux";
var isIos = platform === "iOS" || globalThis.navigator?.platform === "MacIntel" && globalThis.navigator?.maxTouchPoints > 1 || /iPad|iPhone|iPod/.test(globalThis.navigator?.platform);
var isAndroid = platform === "Android" || globalThis.navigator?.platform === "Android" || globalThis.navigator?.userAgent?.includes(" Android ") === true || globalThis.process?.platform === "android";

// node_modules/ansi-escapes/base.js
var ESC = "\x1B[";
var OSC = "\x1B]";
var BEL = "\x07";
var SEP = ";";
var isTerminalApp = !isBrowser && process2.env.TERM_PROGRAM === "Apple_Terminal";
var isWindows2 = !isBrowser && process2.platform === "win32";
var isTmux = !isBrowser && (process2.env.TERM?.startsWith("screen") || process2.env.TERM?.startsWith("tmux") || process2.env.TMUX !== void 0);
var cwdFunction = isBrowser ? () => {
  throw new Error("`process.cwd()` only works in Node.js, not the browser.");
} : process2.cwd;
var wrapOsc = (sequence) => {
  if (isTmux) {
    return "\x1BPtmux;" + sequence.replaceAll("\x1B", "\x1B\x1B") + "\x1B\\";
  }
  return sequence;
};
var cursorTo = (x, y) => {
  if (typeof x !== "number") {
    throw new TypeError("The `x` argument is required");
  }
  if (typeof y !== "number") {
    return ESC + (x + 1) + "G";
  }
  return ESC + (y + 1) + SEP + (x + 1) + "H";
};
var cursorMove = (x, y) => {
  if (typeof x !== "number") {
    throw new TypeError("The `x` argument is required");
  }
  let returnValue = "";
  if (x < 0) {
    returnValue += ESC + -x + "D";
  } else if (x > 0) {
    returnValue += ESC + x + "C";
  }
  if (y < 0) {
    returnValue += ESC + -y + "A";
  } else if (y > 0) {
    returnValue += ESC + y + "B";
  }
  return returnValue;
};
var cursorUp = (count = 1) => ESC + count + "A";
var cursorDown = (count = 1) => ESC + count + "B";
var cursorForward = (count = 1) => ESC + count + "C";
var cursorBackward = (count = 1) => ESC + count + "D";
var cursorLeft = ESC + "G";
var cursorSavePosition = isTerminalApp ? "\x1B7" : ESC + "s";
var cursorRestorePosition = isTerminalApp ? "\x1B8" : ESC + "u";
var cursorGetPosition = ESC + "6n";
var cursorNextLine = ESC + "E";
var cursorPrevLine = ESC + "F";
var cursorHide = ESC + "?25l";
var cursorShow = ESC + "?25h";
var eraseLines = (count) => {
  let clear = "";
  for (let i = 0; i < count; i++) {
    clear += eraseLine + (i < count - 1 ? cursorUp() : "");
  }
  if (count) {
    clear += cursorLeft;
  }
  return clear;
};
var eraseEndLine = ESC + "K";
var eraseStartLine = ESC + "1K";
var eraseLine = ESC + "2K";
var eraseDown = ESC + "J";
var eraseUp = ESC + "1J";
var eraseScreen = ESC + "2J";
var scrollUp = ESC + "S";
var scrollDown = ESC + "T";
var clearScreen = "\x1Bc";
var clearViewport = `${eraseScreen}${ESC}H`;
var isOldWindows = () => {
  if (isBrowser || !isWindows2) {
    return false;
  }
  const parts = os.release().split(".");
  const major = Number(parts[0]);
  const build = Number(parts[2] ?? 0);
  if (major < 10) {
    return true;
  }
  if (major === 10 && build < 10586) {
    return true;
  }
  return false;
};
var clearTerminal = isOldWindows() ? `${eraseScreen}${ESC}0f` : `${eraseScreen}${ESC}3J${ESC}H`;
var enterAlternativeScreen = ESC + "?1049h";
var exitAlternativeScreen = ESC + "?1049l";
var beginSynchronizedOutput = ESC + "?2026h";
var endSynchronizedOutput = ESC + "?2026l";
var synchronizedOutput = (text) => beginSynchronizedOutput + text + endSynchronizedOutput;
var beep = BEL;
var link = (text, url) => {
  const openLink = wrapOsc(`${OSC}8${SEP}${SEP}${url}${BEL}`);
  const closeLink = wrapOsc(`${OSC}8${SEP}${SEP}${BEL}`);
  return openLink + text + closeLink;
};
var image = (data, options = {}) => {
  let returnValue = `${OSC}1337;File=inline=1`;
  if (options.width) {
    returnValue += `;width=${options.width}`;
  }
  if (options.height) {
    returnValue += `;height=${options.height}`;
  }
  if (options.preserveAspectRatio === false) {
    returnValue += ";preserveAspectRatio=0";
  }
  const imageBuffer = Buffer.from(data);
  return wrapOsc(returnValue + `;size=${imageBuffer.byteLength}:` + imageBuffer.toString("base64") + BEL);
};
var iTerm = {
  setCwd: (cwd2 = cwdFunction()) => wrapOsc(`${OSC}50;CurrentDir=${cwd2}${BEL}`),
  annotation(message, options = {}) {
    let returnValue = `${OSC}1337;`;
    const hasX = options.x !== void 0;
    const hasY = options.y !== void 0;
    if ((hasX || hasY) && !(hasX && hasY && options.length !== void 0)) {
      throw new Error("`x`, `y` and `length` must be defined when `x` or `y` is defined");
    }
    message = message.replaceAll("|", "");
    returnValue += options.isHidden ? "AddHiddenAnnotation=" : "AddAnnotation=";
    if (options.length > 0) {
      returnValue += (hasX ? [message, options.length, options.x, options.y] : [options.length, message]).join("|");
    } else {
      returnValue += message;
    }
    return wrapOsc(returnValue + BEL);
  }
};
var ConEmu = {
  setCwd: (cwd2 = cwdFunction()) => wrapOsc(`${OSC}9;9;${cwd2}${BEL}`)
};
var setCwd = (cwd2 = cwdFunction()) => iTerm.setCwd(cwd2) + ConEmu.setCwd(cwd2);

// node_modules/is-in-ci/index.js
import { env } from "process";
var isInCi = env.CI !== "0" && env.CI !== "false" && ("CI" in env || "CONTINUOUS_INTEGRATION" in env || Object.keys(env).some((key) => key.startsWith("CI_")));
var is_in_ci_default = isInCi;

// node_modules/auto-bind/index.js
var getAllProperties = (object) => {
  const properties = /* @__PURE__ */ new Set();
  do {
    for (const key of Reflect.ownKeys(object)) {
      properties.add([object, key]);
    }
  } while ((object = Reflect.getPrototypeOf(object)) && object !== Object.prototype);
  return properties;
};
function autoBind(self, { include, exclude } = {}) {
  const filter = (key) => {
    const match = (pattern) => typeof pattern === "string" ? key === pattern : pattern.test(key);
    if (include) {
      return include.some(match);
    }
    if (exclude) {
      return !exclude.some(match);
    }
    return true;
  };
  for (const [object, key] of getAllProperties(self.constructor.prototype)) {
    if (key === "constructor" || !filter(key)) {
      continue;
    }
    const descriptor = Reflect.getOwnPropertyDescriptor(object, key);
    if (descriptor && typeof descriptor.value === "function") {
      self[key] = self[key].bind(self);
    }
  }
  return self;
}

// node_modules/ink/build/ink.js
var import_signal_exit2 = __toESM(require_signal_exit(), 1);

// node_modules/patch-console/dist/index.js
import { PassThrough } from "stream";
var consoleMethods = [
  "assert",
  "count",
  "countReset",
  "debug",
  "dir",
  "dirxml",
  "error",
  "group",
  "groupCollapsed",
  "groupEnd",
  "info",
  "log",
  "table",
  "time",
  "timeEnd",
  "timeLog",
  "trace",
  "warn"
];
var originalMethods = {};
var patchConsole = (callback) => {
  const stdout = new PassThrough();
  const stderr = new PassThrough();
  stdout.write = (data) => {
    callback("stdout", data);
  };
  stderr.write = (data) => {
    callback("stderr", data);
  };
  const internalConsole = new console.Console(stdout, stderr);
  for (const method of consoleMethods) {
    originalMethods[method] = console[method];
    console[method] = internalConsole[method];
  }
  return () => {
    for (const method of consoleMethods) {
      console[method] = originalMethods[method];
    }
    originalMethods = {};
  };
};
var dist_default = patchConsole;

// node_modules/yoga-layout/dist/binaries/yoga-wasm-base64-esm.js
var loadYoga = (() => {
  var _scriptDir = import.meta.url;
  return (function(loadYoga2) {
    loadYoga2 = loadYoga2 || {};
    var h;
    h || (h = typeof loadYoga2 !== "undefined" ? loadYoga2 : {});
    var aa, ca;
    h.ready = new Promise(function(a, b) {
      aa = a;
      ca = b;
    });
    var da = Object.assign({}, h), q = "";
    "undefined" != typeof document && document.currentScript && (q = document.currentScript.src);
    _scriptDir && (q = _scriptDir);
    0 !== q.indexOf("blob:") ? q = q.substr(0, q.replace(/[?#].*/, "").lastIndexOf("/") + 1) : q = "";
    var ea = h.print || console.log.bind(console), v = h.printErr || console.warn.bind(console);
    Object.assign(h, da);
    da = null;
    var w;
    h.wasmBinary && (w = h.wasmBinary);
    var noExitRuntime = h.noExitRuntime || true;
    "object" != typeof WebAssembly && x("no native wasm support detected");
    var fa, ha = false;
    function z(a, b, c) {
      c = b + c;
      for (var d = ""; !(b >= c); ) {
        var e = a[b++];
        if (!e) break;
        if (e & 128) {
          var f = a[b++] & 63;
          if (192 == (e & 224)) d += String.fromCharCode((e & 31) << 6 | f);
          else {
            var g = a[b++] & 63;
            e = 224 == (e & 240) ? (e & 15) << 12 | f << 6 | g : (e & 7) << 18 | f << 12 | g << 6 | a[b++] & 63;
            65536 > e ? d += String.fromCharCode(e) : (e -= 65536, d += String.fromCharCode(55296 | e >> 10, 56320 | e & 1023));
          }
        } else d += String.fromCharCode(e);
      }
      return d;
    }
    var ia, ja, A, C, ka, D, E, la, ma;
    function na() {
      var a = fa.buffer;
      ia = a;
      h.HEAP8 = ja = new Int8Array(a);
      h.HEAP16 = C = new Int16Array(a);
      h.HEAP32 = D = new Int32Array(a);
      h.HEAPU8 = A = new Uint8Array(a);
      h.HEAPU16 = ka = new Uint16Array(a);
      h.HEAPU32 = E = new Uint32Array(a);
      h.HEAPF32 = la = new Float32Array(a);
      h.HEAPF64 = ma = new Float64Array(a);
    }
    var oa, pa = [], qa = [], ra = [];
    function sa() {
      var a = h.preRun.shift();
      pa.unshift(a);
    }
    var F = 0, ta = null, G = null;
    function x(a) {
      if (h.onAbort) h.onAbort(a);
      a = "Aborted(" + a + ")";
      v(a);
      ha = true;
      a = new WebAssembly.RuntimeError(a + ". Build with -sASSERTIONS for more info.");
      ca(a);
      throw a;
    }
    function ua(a) {
      return a.startsWith("data:application/octet-stream;base64,");
    }
    var H;
    H = "data:application/octet-stream;base64,AGFzbQEAAAABugM3YAF/AGACf38AYAF/AX9gA39/fwBgAn98AGACf38Bf2ADf39/AX9gBH9/f30BfWADf398AGAAAGAEf39/fwBgAX8BfGACf38BfGAFf39/f38Bf2AAAX9gA39/fwF9YAZ/f31/fX8AYAV/f39/fwBgAn9/AX1gBX9/f319AX1gAX8BfWADf35/AX5gB39/f39/f38AYAZ/f39/f38AYAR/f39/AX9gBn9/f319fQF9YAR/f31/AGADf399AX1gBn98f39/fwF/YAR/fHx/AGACf30AYAh/f39/f39/fwBgDX9/f39/f39/f39/f38AYAp/f39/f39/f39/AGAFf39/f38BfGAEfHx/fwF9YA1/fX1/f399fX9/f39/AX9gB39/f319f38AYAJ+fwF/YAN/fX0BfWABfAF8YAN/fHwAYAR/f319AGAHf39/fX19fQF9YA1/fX99f31/fX19fX1/AX9gC39/f39/f399fX19AX9gCH9/f39/f319AGAEf39+fgBgB39/f39/f38Bf2ACfH8BfGAFf398fH8AYAN/f38BfGAEf39/fABgA39/fQBgBn9/fX99fwF/ArUBHgFhAWEAHwFhAWIAAwFhAWMACQFhAWQAFgFhAWUAEQFhAWYAIAFhAWcAAAFhAWgAIQFhAWkAAwFhAWoAAAFhAWsAFwFhAWwACgFhAW0ABQFhAW4AAwFhAW8AAQFhAXAAFwFhAXEABgFhAXIAAAFhAXMAIgFhAXQACgFhAXUADQFhAXYAFgFhAXcAAgFhAXgAAwFhAXkAGAFhAXoAAgFhAUEAAQFhAUIAEQFhAUMAAQFhAUQAAAOiAqACAgMSBwcACRkDAAoRBgYKEwAPDxMBBiMTCgcHGgMUASQFJRQHAwMKCgMmAQYYDxobFAAKBw8KBwMDAgkCAAAFGwACBwIHBgIDAQMIDAABKAkHBQURACkZASoAAAIrLAIALQcHBy4HLwkFCgMCMA0xAgMJAgACAQYKAQIBBQEACQIFAQEABQAODQ0GFQIBHBUGAgkCEAAAAAUyDzMMBQYINAUCAwUODg41AgMCAgIDBgICNgIBDAwMAQsLCwsLCx0CAAIAAAABABABBQICAQMCEgMMCwEBAQEBAQsLAQICAwICAgICAgIDAgIICAEICAgEBAQEBAQEBAQABAQABAQEBAAE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GiABQQA2AvADIAFCADcC6AMgAigC7AMiAyACKALoAyIERwRAIAMgBGsiBEEASA0FIAEgBBAeIgM2AuwDIAEgAzYC6AMgASADIARqNgLwAyACKALoAyIEIAIoAuwDIghHBEADQCADIAQoAgA2AgAgA0EEaiEDIARBBGoiBCAIRw0ACwsgASADNgLsAwsgASACKQL0AzcC9AMgASACKAKEBDYChAQgASACKQL8AzcC/AMgAUEANgLkAwsgBSABNgIAIAEgADYC5AMLIAZBAWohBiAFQQRqIgUgB0cNAAsLDwsQAgALUAACQAJAAkACQAJAIAIOBAQAAQIDCyAAIAEgAUEwahBDDwsgACABIAFBMGogAxBEDwsgACABIAFBMGoQQg8LECQACyAAIAEgAUEwaiADEEULcAIBfwF9IwBBEGsiBCQAIARBCGogACABQQJ0QdwlaigCACACEDZDAADAfyEFAkACQAJAIAQtAAxBAWsOAgABAgsgBCoCCCEFDAELIAQqAgggA5RDCtcjPJQhBQsgBEEQaiQAIAVDAAAAACAFIAVbGwt5AgF/AX0jAEEQayIDJAAgA0EIaiAAIAFBAnRB7CVqKAIAIAIQU0MAAMB/IQQCQAJAAkAgAy0ADEEBaw4CAAECCyADKgIIIQQMAQsgAyoCCEMAAAAAlEMK1yM8lCEECyADQRBqJAAgBEMAAAAAl0MAAAAAIAQgBFsbC1QAAkACQAJAAkACQCACDgQEAAECAwsgACABIAFBwgBqEEMPCyAAIAEgAUHCAGogAxBEDwsgACABIAFBwgBqEEIPCxAkAAsgACABIAFBwgBqIAMQRQsvACAAIAJFQQF0IgIgASADEGAgACACIAEQS5IgACACIAEgAxB/IAAgAiABEFKSkgvOAQIDfwJ9IwBBEGsiAyQAQQEhBCADQQhqIABB/ABqIgUgACABQQF0akH2AGoiAS8BABAfAkACQCADKgIIIgcgAioCACIGXARAIAcgB1sEQCACLQAEIQIMAgsgBiAGXCEECyACLQAEIQIgBEUNACADLQAMIAJB/wFxRg0BCyAFIAEgBiACEDkDQCAALQAAIgFBBHENASAAIAFBBHI6AAAgACgCECIBBEAgACABEQAACyAAQYCAgP4HNgKcASAAKALkAyIADQALCyADQRBqJAALzgECA38CfSMAQRBrIgMk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AWsOAgABAgsgBCoCCCEFDAELIAQqAgggA5RDCtcjPJQhBQsgBEEQaiQAIAVDAAAAACAFIAVbGwscACAAIAFBCCACpyACQiCIpyADpyADQiCIpxAVCwUAEFgACzkAIABFBEBBAA8LAn8gAUGAf3FBgL8DRiABQf8ATXJFBEBB/DtBGTYCAEF/DAELIAAgAToAAEEBCwvEAgACQAJAAkACQAJAAkACQAJAAkACQAJAAkACQCABQQlrDhIACgsMCgsCAwQFDAsMDAoLBwgJCyACIAIoAgAiAUEEajYCACAAIAEoAgA2AgAPCwALIAIgAigCACIBQQRqNgIAIAAgATIBADcDAA8LIAIgAigCACIBQQRqNgIAIAAgATMBADcDAA8LIAIgAigCACIBQQRqNgIAIAAgATAAADcDAA8LIAIgAigCACIBQQRqNgIAIAAgATEAADcDAA8LAAsgAiACKAIAQQdqQXhxIgFBCGo2AgAgACABKwMAOQMADwsgACACIAMRAQALDwsgAiACKAIAIgFBBGo2AgAgACABNAIANwMADwsgAiACKAIAIgFBBGo2AgAgACABNQIANwMADwsgAiACKAIAQQdqQXhxIgFBCGo2AgAgACABKQMANwMAC84BAgN/An0jAEEQayIDJABBASEEIANBCGogAEH8AGoiBSAAIAFBAXRqQegAaiIBLwEAEB8CQAJAIAMqAggiByACKgIAIgZcBEAgByAHWwRAIAItAAQhAgwCCyAGIAZcIQQLIAItAAQhAiAERQ0AIAMtAAwgAkH/AXFGDQELIAUgASAGIAIQOQNAIAAtAAAiAUEEcQ0BIAAgAUEEcjoAACAAKAIQIgEEQCAAIAERAAALIABBgICA/gc2ApwBIAAoAuQDIgANAAsLIANBEGokAAtdAQR/IAAoAgAhAgNAIAIsAAAiAxBXBEBBfyEEIAAgAkEBaiICNgIAIAFBzJmz5gBNBH9BfyADQTBrIgMgAUEKbCIEaiADIARB/////wdzShsFIAQLIQEMAQsLIAELrhQCEn8BfiMAQdAAayIIJAAgCCABNgJMIAhBN2ohFyAIQThqIRQCQAJAAkACQANAIAEhDSAHIA5B/////wdzSg0BIAcgDmohDgJAAkACQCANIgctAAAiCQRAA0ACQAJAIAlB/wFxIgFFBEAgByEBDAELIAFBJUcNASAH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IQEgAEIANwIEIAAgATYCACABIAA2AgQgAkEQaiQAIAALGwEBfyAABEAgACgCACIBBEAgARAjCyAAECMLC0kBAn9BBBAeIQFBIBAeIgBBADYCHCAAQoCAgICAgIDAPzcCFCAAQgA3AgwgAEEAOgAIIABBAzYCBCAAQQA2AgAgASAANgIAIAELIAAgAkEFR0EAIAIbRQRAQbgwIAMgBBBJDwsgAyAEEHALIgEBfiABIAKtIAOtQiCGhCAEIAARFQAiBUIgiKckASAFpwuoAQEFfyAAKAJUIgMoAgAhBSADKAIEIgQgACgCFCAAKAIcIgdrIgYgBCAGSRsiBgRAIAUgByAGECsaIAMgAygCACAGaiIFNgIAIAMgAygCBCAGayIENgIECyAEIAIgAiAESxsiBARAIAUgASAEECsaIAMgAygCACAEaiIFNgIAIAMgAygCBCAEazYCBAsgBUEAOgAAIAAgACgCLCIBNgIcIAAgATYCFCACCwQAQgALBABBAAuKBQIGfgJ/IAEgASgCAEEHakF4cSIBQRBqNgIAIAAhCSABKQMAIQMgASkDCCEGIwBBIGsiCCQAAkAgBkL///////////8AgyIEQoCAgICAgMCAPH0gBEKAgICAgIDA/8MAfVQEQCAGQgSGIANCPIiEIQQgA0L//////////w+DIgNCgYCAgICAgIAIWgRAIARCgYCAgICAgIDAAHwhAgwCCyAEQoCAgICAgICAQH0hAiADQoCAgICAgICACFINASACIARCAYN8IQIMAQsgA1AgBEKAgICAgIDA//8AVCAEQoCAgICAgMD//wBRG0UEQCAGQgSGIANCPIiEQv////////8Dg0KAgICAgICA/P8AhCECDAELQoCAgICAgID4/wAhAiAEQv///////7//wwBWDQBCACECIARCMIinIgBBkfcASQ0AIAMhAiAGQv///////z+DQoCAgICAgMAAhCIFIQcCQCAAQYH3AGsiAUHAAHEEQCACIAFBQGqthiEHQgAhAgwBCyABRQ0AIAcgAa0iBIYgAkHAACABa62IhCEHIAIgBIYhAgsgCCACNwMQIAggBzcDGAJAQYH4ACAAayIAQcAAcQRAIAUgAEFAaq2IIQNCACEFDAELIABFDQAgBUHAACAAa62GIAMgAK0iAoiEIQMgBSACiCEFCyAIIAM3AwAgCCAF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ASAAKAIAIQAgASACQQFxBH8gASgCACAAaigCAAUgAAsRCwALYQECfyMAQRBrIgIkACABIAAoAgQiA0EBdWohASAAKAIAIQAgAiABIANBAXEEfyABKAIAIABqKAIABSAACxEBAEEQEB4iACACKQMINwMIIAAgAikDADcDACACQRBqJAAgAAtjAQJ/IwBBEGsiAyQAIAEgACgCBCIEQQF1aiEBIAAoAgAhACADIAEgAiAEQQFxBH8gASgCACAAaigCAAUgAAsRAwBBEBAeIgAgAykDCDcDCCAAIAMpAwA3AwAgA0EQaiQAIAALNwEBfyABIAAoAgQiA0EBdWohASAAKAIAIQAgASACIANBAXEEfyABKAIAIABqKAIABSAACxEEAAs5AQF/IAEgACgCBCIEQQF1aiEBIAAoAgAhACABIAIgAyAEQQFxBH8gASgCACAAaigCAAUgAAsRCAALCQAgASAAEQIACwUAQcM7Cw8AIAEgACgCAGogAjYCAAsNACABIAAoAgBqKAIACxgBAX9BEBAeIgBCADcDCCAAQQA2AgAgAAsYAQF/QRAQHiIAQgA3AwAgAEIANwMIIAALDABBMBAeQQBBMBAqCzcBAX8gASAAKAIEIgNBAXVqIQEgACgCACEAIAEgAiADQQFxBH8gASgCACAAaigCAAUgAAsRHgALBQBBvjsLIQAgACABKAIAIAEgASwAC0EASBtBuzsgAigCABAQNgIACyoBAX9BDBAeIgFBADoABCABIAAoAgA2AgggAEEANgIAIAFB2Cc2AgAgAQsFAEG7OwsFAEG4OwshACAAIAEoAgAgASABLAALQQBIG0GkOyACKAIAEBA2AgAL2AEBBH8jAEEgayIDJAAgASgCACIEQfD///8HSQRAAkACQCAEQQtPBEAgBEEPckEBaiIFEB4hBiADIAVBgICAgHhyNgIQIAMgBjYCCCADIAQ2AgwgBCAGaiEFDAELIAMgBDoAEyADQQhqIgYgBGohBSAERQ0BCyAGIAFBBGogBBArGgsgBUEAOgAAIAMgAjYCACADQRhqIANBCGogAyAAEQMAIAMoAhgQHSADKAIYIgAQBiADKAIAEAYgAywAE0EASARAIAMoAggQIwsgA0EgaiQAIAAPCxACAAsqAQF/QQwQHiIBQQA6AAQgASAAKAIANgIIIABBADYCACABQeAmNgIA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AkEIaiAIIAYQHyACIAcgAC8AABAfQQEhAyACKgIIIgogAioCACILXAR/IAogClsNAyALIAtcBSADC0UNAiACLQAMIAItAARHDQILIABBAmohAEEBIQMgBCEGQQEhBCAGRQ0ACyABLwB6IgBBB3FFBEAgBS0AekEHcUUNAgsgCCAAECAiCiAHIAUvAHoQICILWw0BIAogClsNACALIAtcDQELIAFBFGogBUEUakHoABArGiABQfwAaiAFQfwAahCgAQNAIAEtAAAiAEEEcQ0BIAEgAEEEcjoAACABKAIQIgAEQCABIAARAAALIAFBgICA/gc2ApwBIAEoAuQDIgENAAsLIAJBEGokAAvGAwEEfyMAQaAEayICJAAgACgCBCEBIABBADYCBCABBEAgASABKAIAKAIEEQAACyAAKAIIIQEgAEEANgIIIAEEQCABIAEoAgAoAgQRAAALAkAgACgCACIAKALoAyAAKALsA0YEQCAAKALkAw0BIAAgAkEYaiAAKAL0AxBcIgEpAgA3AgAgACABKAIQNgIQIAAgASkCCDcCCCAAQRRqIAFBFGpB6AAQKxogACABKQKMATcCjAEgACABKQKEATcChAEgACABKQJ8NwJ8IAEoApQBIQQgAUEANgKUASAAKAKUASEDIAAgBDYClAEgAwRAIAMQWwsgAEGYAWogAUGYAWpB0AIQKxogACgC6AMiAwRAIAAgAzYC7AMgAxAjCyAAIAEoAugDNgLoAyAAIAEoAuwDNgLsAyAAIAEoAvADNgLwAyABQQA2AvADIAFCADcC6AMgACABKQL8AzcC/AMgACABKQL0AzcC9AMgACABKAKEBDYChAQgASgClAEhACABQQA2ApQBIAAEQCAAEFsLIAJBoARqJAAPCyACQfAcNgIQIABBBUHYJSACQRBqECwQJAALIAJB5hE2AgAgAEEFQdglIAIQLBAkAAsLAEEMEB4gABCiAQsLAEEMEB5BABCiAQsNACAAKAIALQAIQQFxCwoAIAAoAgAoAhQLGQAgAUH/AXEEQBACAAsgACgCACgCEEEBcQsYACAAKAIAIgAgAC0ACEH+AXEgAXI6AAgLJgAgASAAKAIAIgAoAhRHBEAgACABNgIUIAAgACgCDEEBajYCDAsLkgEBAn8jAEEQayICJAAgACgCACEAIAFDAAAAAGAEQCABIAAqAhhcBEAgACABOAIYIAAgACgCDEEBajYCDAsgAkEQaiQADwsgAkGIFDYCACMAQRBrIgMkACADIAI2AgwCQCAARQRAQbgwQdglIAIQSRoMAQsgAEEAQQVB2CUgAiAAKAIEEQ0AGgsgA0EQaiQAECQACz8AIAFB/wFxRQRAIAIgACgCACIAKAIQIgFBAXFHBEAgACABQX5xIAJyNgIQIAAgACgCDEEBajYCDAsPCxACAAsL4CYjAEGACAuBHk9ubHkgbGVhZiBub2RlcyB3aXRoIGN1c3RvbSBtZWFzdXJlIGZ1bmN0aW9ucyBzaG91bGQgbWFudWFsbHkgbWFyayB0aGVtc2VsdmVzIGFzIGRpcnR5AGlzRGlydHkAbWFya0RpcnR5AGRlc3Ryb3kAc2V0RGlzcGxheQBnZXREaXNwbGF5AHNldEZsZXgALSsgICAwWDB4AC0wWCswWCAwWC0weCsweCAweABzZXRGbGV4R3JvdwBnZXRGbGV4R3JvdwBzZXRPdmVyZmxvdwBnZXRPdmVyZmxvdwBoYXNOZXdMYXlvdXQAY2FsY3VsYXRlTGF5b3V0AGdldENvbXB1dGVkTGF5b3V0AHVuc2lnbmVkIHNob3J0AGdldENoaWxkQ291bnQAdW5zaWduZWQgaW50AHNldEp1c3RpZnlDb250ZW50AGdldEp1c3RpZnlDb250ZW50AGF2YWlsYWJsZUhlaWdodCBpcyBpbmRlZmluaXRlIHNvIGhlaWdodFNpemluZ01vZGUgbXVzdCBiZSBTaXppbmdNb2RlOjpNYXhDb250ZW50AGF2YWlsYWJsZVdpZHRoIGlzIGluZGVmaW5pdGUgc28gd2lkdGhTaXppbmdNb2RlIG11c3QgYmUgU2l6aW5nTW9kZTo6TWF4Q29udGVudABzZXRBbGlnbkNvbnRlbnQAZ2V0QWxpZ25Db250ZW50AGdldFBhcmVudABpbXBsZW1lbnQAc2V0TWF4SGVpZ2h0UGVyY2VudABzZXRIZWlnaHRQZXJjZW50AHNldE1pbkhlaWdodFBlcmNlbnQAc2V0RmxleEJhc2lzUGVyY2VudABzZXRHYXBQZXJjZW50AHNldFBvc2l0aW9uUGVyY2VudABzZXRNYXJnaW5QZXJjZW50AHNldE1heFdpZHRoUGVyY2VudABzZXRXaWR0aFBlcmNlbnQAc2V0TWluV2lkdGhQZXJjZW50AHNldFBhZGRpbmdQZXJjZW50AGhhbmRsZS50eXBlKCkgPT0gU3R5bGVWYWx1ZUhhbmRsZTo6VHlwZTo6UG9pbnQgfHwgaGFuZGxlLnR5cGUoKSA9PSBTdHlsZVZhbHVlSGFuZGxlOjpUeXBlOjpQZXJjZW50AGNyZWF0ZURlZmF1bHQAdW5pdAByaWdodABoZWlnaHQAc2V0TWF4SGVpZ2h0AGdldE1heEhlaWdodABzZXRIZWlnaHQAZ2V0SGVpZ2h0AHNldE1pbkhlaWdodABnZXRNaW5IZWlnaHQAZ2V0Q29tcHV0ZWRIZWlnaHQAZ2V0Q29tcHV0ZWRSaWdodABsZWZ0AGdldENvbXB1dGVkTGVmdAByZXNldABfX2Rlc3RydWN0AGZsb2F0AHVpbnQ2NF90AHVzZVdlYkRlZmF1bHRzAHNldFVzZVdlYkRlZmF1bHRzAHNldEFsaWduSXRlbXMAZ2V0QWxpZ25JdGVtcwBzZXRGbGV4QmFzaXMAZ2V0RmxleEJhc2lzAENhbm5vdCBnZXQgbGF5b3V0IHByb3BlcnRpZXMgb2YgbXVsdGktZWRnZSBzaG9ydGhhbmRzAHNldFBvaW50U2NhbGVGYWN0b3IATWVhc3VyZUNhbGxiYWNrV3JhcHBlcgBEaXJ0aWVkQ2FsbGJhY2tXcmFwcGVyAENhbm5vdCByZXNldCBhIG5vZGUgc3RpbGwgYXR0YWNoZWQgdG8gYSBvd25lcgBzZXRCb3JkZXIAZ2V0Qm9yZGVyAGdldENvbXB1dGVkQm9yZGVyAGdldE51bWJlcgBoYW5kbGUudHlwZSgpID09IFN0eWxlVmFsdWVIYW5kbGU6OlR5cGU6Ok51bWJlcgB1bnNpZ25lZCBjaGFyAHRvcABnZXRDb21wdXRlZFRvcABzZXRGbGV4V3JhcABnZXRGbGV4V3JhcABzZXRHYXAAZ2V0R2FwACVwAHNldEhlaWdodEF1dG8Ac2V0RmxleEJhc2lzQXV0bwBzZXRQb3NpdGlvbkF1dG8Ac2V0TWFyZ2luQXV0bwBzZXRXaWR0aEF1dG8AU2NhbGUgZmFjdG9yIHNob3VsZCBub3QgYmUgbGVzcyB0aGFuIHplcm8Ac2V0QXNwZWN0UmF0aW8AZ2V0QXNwZWN0UmF0aW8Ac2V0UG9zaXRpb24AZ2V0UG9zaXRpb24Abm90aWZ5T25EZXN0cnVjdGlvbgBzZXRGbGV4RGlyZWN0aW9uAGdldEZsZXhEaXJlY3Rpb24Ac2V0RGlyZWN0aW9uAGdldERpcmVjdGlvbgBzZXRNYXJnaW4AZ2V0TWFyZ2luAGdldENvbXB1dGVkTWFyZ2luAG1hcmtMYXlvdXRTZWVuAG5hbgBib3R0b20AZ2V0Q29tcHV0ZWRCb3R0b20AYm9vbABlbXNjcmlwdGVuOjp2YWwAc2V0RmxleFNocmluawBnZXRGbGV4U2hyaW5rAHNldEFsd2F5c0Zvcm1zQ29udGFpbmluZ0Jsb2NrAE1lYXN1cmVDYWxsYmFjawBEaXJ0aWVkQ2FsbGJhY2sAZ2V0TGVuZ3RoAHdpZHRoAHNldE1heFdpZHRoAGdldE1heFdpZHRoAHNldFdpZHRoAGdldFdpZHRoAHNldE1pbldpZHRoAGdldE1pbldpZHRoAGdldENvbXB1dGVkV2lkdGgAcHVzaAAvaG9tZS9ydW5uZXIvd29yay95b2dhL3lvZ2EvamF2YXNjcmlwdC8uLi95b2dhL3N0eWxlL1NtYWxsVmFsdWVCdWZmZXIuaAAvaG9tZS9ydW5uZXIvd29yay95b2dhL3lvZ2EvamF2YXNjcmlwdC8uLi95b2dhL3N0eWxlL1N0eWxlVmFsdWVQb29sLmgAdW5zaWduZWQgbG9uZwBzZXRCb3hTaXppbmcAZ2V0Qm94U2l6aW5nAHN0ZDo6d3N0cmluZwBzdGQ6OnN0cmluZwBzdGQ6OnUxNnN0cmluZwBzdGQ6OnUzMnN0cmluZwBzZXRQYWRkaW5nAGdldFBhZGRpbmcAZ2V0Q29tcHV0ZWRQYWRkaW5nAFRyaWVkIHRvIGNvbnN0cnVjdCBZR05vZGUgd2l0aCBudWxsIGNvbmZpZwBBdHRlbXB0aW5nIHRvIGNvbnN0cnVjdCBOb2RlIHdpdGggbnVsbCBjb25maWcAY3JlYXRlV2l0aENvbmZpZwBpbmYAc2V0QWxpZ25TZWxmAGdldEFsaWduU2VsZgBTaXplAHZhbHVlAFZhbHVlAGNyZWF0ZQBtZWFzdXJlAHNldFBvc2l0aW9uVHlwZQBnZXRQb3NpdGlvblR5cGUAaXNSZWZlcmVuY2VCYXNlbGluZQBzZXRJc1JlZmVyZW5jZUJhc2VsaW5lAGNvcHlTdHlsZQBkb3VibGUATm9kZQBleHRlbmQAaW5zZXJ0Q2hpbGQAZ2V0Q2hpbGQAcmVtb3ZlQ2hpbGQAdm9pZABzZXRFeHBlcmltZW50YWxGZWF0dXJlRW5hYmxlZABpc0V4cGVyaW1lbnRhbEZlYXR1cmVFbmFibGVkAGRpcnRpZWQAQ2Fubm90IHJlc2V0IGEgbm9kZSB3aGljaCBzdGlsbCBoYXMgY2hpbGRyZW4gYXR0YWNoZWQAdW5zZXRNZWFzdXJlRnVuYwB1bnNldERpcnRpZWRGdW5jAHNldEVycmF0YQBnZXRFcnJhdGEATWVhc3VyZSBmdW5jdGlvbiByZXR1cm5lZCBhbiBpbnZhbGlkIGRpbWVuc2lvbiB0byBZb2dhOiBbd2lkdGg9JWYsIGhlaWdodD0lZl0ARXhwZWN0IGN1c3RvbSBiYXNlbGluZSBmdW5jdGlvbiB0byBub3QgcmV0dXJuIE5hTgBOQU4ASU5GAGVtc2NyaXB0ZW46Om1lbW9yeV92aWV3PHNob3J0PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzx1bnNpZ25lZCBzaG9ydD4AZW1zY3JpcHRlbjo6bWVtb3J5X3ZpZXc8aW50PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzx1bnNpZ25lZCBpbnQ+AGVtc2NyaXB0ZW46Om1lbW9yeV92aWV3PGZsb2F0PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzx1aW50OF90PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzxpbnQ4X3Q+AGVtc2NyaXB0ZW46Om1lbW9yeV92aWV3PHVpbnQxNl90PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzxpbnQxNl90PgBlbXNjcmlwdGVuOjptZW1vcnlfdmlldzx1aW50MzJfdD4AZW1zY3JpcHRlbjo6bWVtb3J5X3ZpZXc8aW50MzJfdD4AZW1zY3JpcHRlbjo6bWVtb3J5X3ZpZXc8Y2hhcj4AZW1zY3JpcHRlbjo6bWVtb3J5X3ZpZXc8dW5zaWduZWQgY2hhcj4Ac3RkOjpiYXNpY19zdHJpbmc8dW5zaWduZWQgY2hhcj4AZW1zY3JpcHRlbjo6bWVtb3J5X3ZpZXc8c2lnbmVk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";
    if (!ua(H)) {
      var va = H;
      H = h.locateFile ? h.locateFile(va, q) : q + va;
    }
    function wa() {
      var a = H;
      try {
        if (a == H && w) return new Uint8Array(w);
        if (ua(a)) try {
          var b = xa(a.slice(37)), c = new Uint8Array(b.length);
          for (a = 0; a < b.length; ++a) c[a] = b.charCodeAt(a);
          var d = c;
        } catch (f) {
          throw Error("Converting base64 string to bytes failed.");
        }
        else d = void 0;
        var e = d;
        if (e) return e;
        throw "both async and sync fetching of the wasm failed";
      } catch (f) {
        x(f);
      }
    }
    function ya() {
      return w || "function" != typeof fetch ? Promise.resolve().then(function() {
        return wa();
      }) : fetch(H, { credentials: "same-origin" }).then(function(a) {
        if (!a.ok) throw "failed to load wasm binary file at '" + H + "'";
        return a.arrayBuffer();
      }).catch(function() {
        return wa();
      });
    }
    function za(a) {
      for (; 0 < a.length; ) a.shift()(h);
    }
    function Aa(a) {
      if (void 0 === a) return "_unknown";
      a = a.replace(/[^a-zA-Z0-9_]/g, "$");
      var b = a.charCodeAt(0);
      return 48 <= b && 57 >= b ? "_" + a : a;
    }
    function Ba(a, b) {
      a = Aa(a);
      return function() {
        return b.apply(this, arguments);
      };
    }
    var J = [{}, { value: void 0 }, { value: null }, { value: true }, { value: false }], Ca = [];
    function Da(a) {
      var b = Error, c = Ba(a, function(d) {
        this.name = a;
        this.message = d;
        d = Error(d).stack;
        void 0 !== d && (this.stack = this.toString() + "\n" + d.replace(/^Error(:[^\n]*)?\n/, ""));
      });
      c.prototype = Object.create(b.prototype);
      c.prototype.constructor = c;
      c.prototype.toString = function() {
        return void 0 === this.message ? this.name : this.name + ": " + this.message;
      };
      return c;
    }
    var K = void 0;
    function L(a) {
      throw new K(a);
    }
    var M = (a) => {
      a || L("Cannot use deleted val. handle = " + a);
      return J[a].value;
    }, Ea = (a) => {
      switch (a) {
        case void 0:
          return 1;
        case null:
          return 2;
        case true:
          return 3;
        case false:
          return 4;
        default:
          var b = Ca.length ? Ca.pop() : J.length;
          J[b] = { ga: 1, value: a };
          return b;
      }
    }, Fa = void 0, Ga = void 0;
    function N(a) {
      for (var b = ""; A[a]; ) b += Ga[A[a++]];
      return b;
    }
    var O = [];
    function Ha() {
      for (; O.length; ) {
        var a = O.pop();
        a.M.$ = false;
        a["delete"]();
      }
    }
    var P = void 0, Q = {};
    function Ia(a, b) {
      for (void 0 === b && L("ptr should not be undefined"); a.R; ) b = a.ba(b), a = a.R;
      return b;
    }
    var R = {};
    function Ja(a) {
      a = Ka(a);
      var b = N(a);
      S(a);
      return b;
    }
    function La(a, b) {
      var c = R[a];
      void 0 === c && L(b + " has unknown type " + Ja(a));
      return c;
    }
    function Ma() {
    }
    var Na = false;
    function Oa(a) {
      --a.count.value;
      0 === a.count.value && (a.T ? a.U.W(a.T) : a.P.N.W(a.O));
    }
    function Pa(a, b, c) {
      if (b === c) return a;
      if (void 0 === c.R) return null;
      a = Pa(a, b, c.R);
      return null === a ? null : c.na(a);
    }
    var Qa = {};
    function Ra(a, b) {
      b = Ia(a, b);
      return Q[b];
    }
    var Sa = void 0;
    function Ta(a) {
      throw new Sa(a);
    }
    function Ua(a, b) {
      b.P && b.O || Ta("makeClassHandle requires ptr and ptrType");
      !!b.U !== !!b.T && Ta("Both smartPtrType and smartPtr must be specified");
      b.count = { value: 1 };
      return T(Object.create(a, { M: { value: b } }));
    }
    function T(a) {
      if ("undefined" === typeof FinalizationRegistry) return T = (b) => b, a;
      Na = new FinalizationRegistry((b) => {
        Oa(b.M);
      });
      T = (b) => {
        var c = b.M;
        c.T && Na.register(b, { M: c }, b);
        return b;
      };
      Ma = (b) => {
        Na.unregister(b);
      };
      return T(a);
    }
    var Va = {};
    function Wa(a) {
      for (; a.length; ) {
        var b = a.pop();
        a.pop()(b);
      }
    }
    function Xa(a) {
      return this.fromWireType(D[a >> 2]);
    }
    var U = {}, Ya = {};
    function V(a, b, c) {
      function d(k) {
        k = c(k);
        k.length !== a.length && Ta("Mismatched type converter count");
        for (var m = 0; m < a.length; ++m) W(a[m], k[m]);
      }
      a.forEach(function(k) {
        Ya[k] = b;
      });
      var e = Array(b.length), f = [], g = 0;
      b.forEach((k, m) => {
        R.hasOwnProperty(k) ? e[m] = R[k] : (f.push(k), U.hasOwnProperty(k) || (U[k] = []), U[k].push(() => {
          e[m] = R[k];
          ++g;
          g === f.length && d(e);
        }));
      });
      0 === f.length && d(e);
    }
    function Za(a) {
      switch (a) {
        case 1:
          return 0;
        case 2:
          return 1;
        case 4:
          return 2;
        case 8:
          return 3;
        default:
          throw new TypeError("Unknown type size: " + a);
      }
    }
    function W(a, b, c = {}) {
      if (!("argPackAdvance" in b)) throw new TypeError("registerType registeredInstance requires argPackAdvance");
      var d = b.name;
      a || L('type "' + d + '" must have a positive integer typeid pointer');
      if (R.hasOwnProperty(a)) {
        if (c.ua) return;
        L("Cannot register type '" + d + "' twice");
      }
      R[a] = b;
      delete Ya[a];
      U.hasOwnProperty(a) && (b = U[a], delete U[a], b.forEach((e) => e()));
    }
    function $a(a) {
      L(a.M.P.N.name + " instance already deleted");
    }
    function X() {
    }
    function ab(a, b, c) {
      if (void 0 === a[b].S) {
        var d = a[b];
        a[b] = function() {
          a[b].S.hasOwnProperty(arguments.length) || L("Function '" + c + "' called with an invalid number of arguments (" + arguments.length + ") - expects one of (" + a[b].S + ")!");
          return a[b].S[arguments.length].apply(this, arguments);
        };
        a[b].S = [];
        a[b].S[d.Z] = d;
      }
    }
    function bb(a, b) {
      h.hasOwnProperty(a) ? (L("Cannot register public name '" + a + "' twice"), ab(h, a, a), h.hasOwnProperty(void 0) && L("Cannot register multiple overloads of a function with the same number of arguments (undefined)!"), h[a].S[void 0] = b) : h[a] = b;
    }
    function cb(a, b, c, d, e, f, g, k) {
      this.name = a;
      this.constructor = b;
      this.X = c;
      this.W = d;
      this.R = e;
      this.pa = f;
      this.ba = g;
      this.na = k;
      this.ja = [];
    }
    function db(a, b, c) {
      for (; b !== c; ) b.ba || L("Expected null or instance of " + c.name + ", got an instance of " + b.name), a = b.ba(a), b = b.R;
      return a;
    }
    function eb(a, b) {
      if (null === b) return this.ea && L("null is not a valid " + this.name), 0;
      b.M || L('Cannot pass "' + fb(b) + '" as a ' + this.name);
      b.M.O || L("Cannot pass deleted object as a pointer of type " + this.name);
      return db(b.M.O, b.M.P.N, this.N);
    }
    function gb(a, b) {
      if (null === b) {
        this.ea && L("null is not a valid " + this.name);
        if (this.da) {
          var c = this.fa();
          null !== a && a.push(this.W, c);
          return c;
        }
        return 0;
      }
      b.M || L('Cannot pass "' + fb(b) + '" as a ' + this.name);
      b.M.O || L("Cannot pass deleted object as a pointer of type " + this.name);
      !this.ca && b.M.P.ca && L("Cannot convert argument of type " + (b.M.U ? b.M.U.name : b.M.P.name) + " to parameter type " + this.name);
      c = db(b.M.O, b.M.P.N, this.N);
      if (this.da) switch (void 0 === b.M.T && L("Passing raw pointer to smart pointer is illegal"), this.Ba) {
        case 0:
          b.M.U === this ? c = b.M.T : L("Cannot convert argument of type " + (b.M.U ? b.M.U.name : b.M.P.name) + " to parameter type " + this.name);
          break;
        case 1:
          c = b.M.T;
          break;
        case 2:
          if (b.M.U === this) c = b.M.T;
          else {
            var d = b.clone();
            c = this.xa(c, Ea(function() {
              d["delete"]();
            }));
            null !== a && a.push(this.W, c);
          }
          break;
        default:
          L("Unsupporting sharing policy");
      }
      return c;
    }
    function hb(a, b) {
      if (null === b) return this.ea && L("null is not a valid " + this.name), 0;
      b.M || L('Cannot pass "' + fb(b) + '" as a ' + this.name);
      b.M.O || L("Cannot pass deleted object as a pointer of type " + this.name);
      b.M.P.ca && L("Cannot convert argument of type " + b.M.P.name + " to parameter type " + this.name);
      return db(b.M.O, b.M.P.N, this.N);
    }
    function Y(a, b, c, d) {
      this.name = a;
      this.N = b;
      this.ea = c;
      this.ca = d;
      this.da = false;
      this.W = this.xa = this.fa = this.ka = this.Ba = this.wa = void 0;
      void 0 !== b.R ? this.toWireType = gb : (this.toWireType = d ? eb : hb, this.V = null);
    }
    function ib(a, b) {
      h.hasOwnProperty(a) || Ta("Replacing nonexistant public symbol");
      h[a] = b;
      h[a].Z = void 0;
    }
    function jb(a, b) {
      var c = [];
      return function() {
        c.length = 0;
        Object.assign(c, arguments);
        if (a.includes("j")) {
          var d = h["dynCall_" + a];
          d = c && c.length ? d.apply(null, [b].concat(c)) : d.call(null, b);
        } else d = oa.get(b).apply(null, c);
        return d;
      };
    }
    function Z(a, b) {
      a = N(a);
      var c = a.includes("j") ? jb(a, b) : oa.get(b);
      "function" != typeof c && L("unknown function pointer with signature " + a + ": " + b);
      return c;
    }
    var mb = void 0;
    function nb(a, b) {
      function c(f) {
        e[f] || R[f] || (Ya[f] ? Ya[f].forEach(c) : (d.push(f), e[f] = true));
      }
      var d = [], e = {};
      b.forEach(c);
      throw new mb(a + ": " + d.map(Ja).join([", "]));
    }
    function ob(a, b, c, d, e) {
      var f = b.length;
      2 > f && L("argTypes array size mismatch! Must at least get return value and 'this' types!");
      var g = null !== b[1] && null !== c, k = false;
      for (c = 1; c < b.length; ++c) if (null !== b[c] && void 0 === b[c].V) {
        k = true;
        break;
      }
      var m = "void" !== b[0].name, l = f - 2, n = Array(l), p = [], r = [];
      return function() {
        arguments.length !== l && L("function " + a + " called with " + arguments.length + " arguments, expected " + l + " args!");
        r.length = 0;
        p.length = g ? 2 : 1;
        p[0] = e;
        if (g) {
          var u = b[1].toWireType(r, this);
          p[1] = u;
        }
        for (var t = 0; t < l; ++t) n[t] = b[t + 2].toWireType(r, arguments[t]), p.push(n[t]);
        t = d.apply(null, p);
        if (k) Wa(r);
        else for (var y = g ? 1 : 2; y < b.length; y++) {
          var B = 1 === y ? u : n[y - 2];
          null !== b[y].V && b[y].V(B);
        }
        u = m ? b[0].fromWireType(t) : void 0;
        return u;
      };
    }
    function pb(a, b) {
      for (var c = [], d = 0; d < a; d++) c.push(E[b + 4 * d >> 2]);
      return c;
    }
    function qb(a) {
      4 < a && 0 === --J[a].ga && (J[a] = void 0, Ca.push(a));
    }
    function fb(a) {
      if (null === a) return "null";
      var b = typeof a;
      return "object" === b || "array" === b || "function" === b ? a.toString() : "" + a;
    }
    function rb(a, b) {
      switch (b) {
        case 2:
          return function(c) {
            return this.fromWireType(la[c >> 2]);
          };
        case 3:
          return function(c) {
            return this.fromWireType(ma[c >> 3]);
          };
        default:
          throw new TypeError("Unknown float type: " + a);
      }
    }
    function sb(a, b, c) {
      switch (b) {
        case 0:
          return c ? function(d) {
            return ja[d];
          } : function(d) {
            return A[d];
          };
        case 1:
          return c ? function(d) {
            return C[d >> 1];
          } : function(d) {
            return ka[d >> 1];
          };
        case 2:
          return c ? function(d) {
            return D[d >> 2];
          } : function(d) {
            return E[d >> 2];
          };
        default:
          throw new TypeError("Unknown integer type: " + a);
      }
    }
    function tb(a, b) {
      for (var c = "", d = 0; !(d >= b / 2); ++d) {
        var e = C[a + 2 * d >> 1];
        if (0 == e) break;
        c += String.fromCharCode(e);
      }
      return c;
    }
    function ub(a, b, c) {
      void 0 === c && (c = 2147483647);
      if (2 > c) return 0;
      c -= 2;
      var d = b;
      c = c < 2 * a.length ? c / 2 : a.length;
      for (var e = 0; e < c; ++e) C[b >> 1] = a.charCodeAt(e), b += 2;
      C[b >> 1] = 0;
      return b - d;
    }
    function vb(a) {
      return 2 * a.length;
    }
    function wb(a, b) {
      for (var c = 0, d = ""; !(c >= b / 4); ) {
        var e = D[a + 4 * c >> 2];
        if (0 == e) break;
        ++c;
        65536 <= e ? (e -= 65536, d += String.fromCharCode(55296 | e >> 10, 56320 | e & 1023)) : d += String.fromCharCode(e);
      }
      return d;
    }
    function xb(a, b, c) {
      void 0 === c && (c = 2147483647);
      if (4 > c) return 0;
      var d = b;
      c = d + c - 4;
      for (var e = 0; e < a.length; ++e) {
        var f = a.charCodeAt(e);
        if (55296 <= f && 57343 >= f) {
          var g = a.charCodeAt(++e);
          f = 65536 + ((f & 1023) << 10) | g & 1023;
        }
        D[b >> 2] = f;
        b += 4;
        if (b + 4 > c) break;
      }
      D[b >> 2] = 0;
      return b - d;
    }
    function yb(a) {
      for (var b = 0, c = 0; c < a.length; ++c) {
        var d = a.charCodeAt(c);
        55296 <= d && 57343 >= d && ++c;
        b += 4;
      }
      return b;
    }
    var zb = {};
    function Ab(a) {
      var b = zb[a];
      return void 0 === b ? N(a) : b;
    }
    var Bb = [];
    function Cb(a) {
      var b = Bb.length;
      Bb.push(a);
      return b;
    }
    function Db(a, b) {
      for (var c = Array(a), d = 0; d < a; ++d) c[d] = La(E[b + 4 * d >> 2], "parameter " + d);
      return c;
    }
    var Eb = [], Fb = [null, [], []];
    K = h.BindingError = Da("BindingError");
    h.count_emval_handles = function() {
      for (var a = 0, b = 5; b < J.length; ++b) void 0 !== J[b] && ++a;
      return a;
    };
    h.get_first_emval = function() {
      for (var a = 5; a < J.length; ++a) if (void 0 !== J[a]) return J[a];
      return null;
    };
    Fa = h.PureVirtualError = Da("PureVirtualError");
    for (var Gb = Array(256), Hb = 0; 256 > Hb; ++Hb) Gb[Hb] = String.fromCharCode(Hb);
    Ga = Gb;
    h.getInheritedInstanceCount = function() {
      return Object.keys(Q).length;
    };
    h.getLiveInheritedInstances = function() {
      var a = [], b;
      for (b in Q) Q.hasOwnProperty(b) && a.push(Q[b]);
      return a;
    };
    h.flushPendingDeletes = Ha;
    h.setDelayFunction = function(a) {
      P = a;
      O.length && P && P(Ha);
    };
    Sa = h.InternalError = Da("InternalError");
    X.prototype.isAliasOf = function(a) {
      if (!(this instanceof X && a instanceof X)) return false;
      var b = this.M.P.N, c = this.M.O, d = a.M.P.N;
      for (a = a.M.O; b.R; ) c = b.ba(c), b = b.R;
      for (; d.R; ) a = d.ba(a), d = d.R;
      return b === d && c === a;
    };
    X.prototype.clone = function() {
      this.M.O || $a(this);
      if (this.M.aa) return this.M.count.value += 1, this;
      var a = T, b = Object, c = b.create, d = Object.getPrototypeOf(this), e = this.M;
      a = a(c.call(b, d, { M: { value: { count: e.count, $: e.$, aa: e.aa, O: e.O, P: e.P, T: e.T, U: e.U } } }));
      a.M.count.value += 1;
      a.M.$ = false;
      return a;
    };
    X.prototype["delete"] = function() {
      this.M.O || $a(this);
      this.M.$ && !this.M.aa && L("Object already scheduled for deletion");
      Ma(this);
      Oa(this.M);
      this.M.aa || (this.M.T = void 0, this.M.O = void 0);
    };
    X.prototype.isDeleted = function() {
      return !this.M.O;
    };
    X.prototype.deleteLater = function() {
      this.M.O || $a(this);
      this.M.$ && !this.M.aa && L("Object already scheduled for deletion");
      O.push(this);
      1 === O.length && P && P(Ha);
      this.M.$ = true;
      return this;
    };
    Y.prototype.qa = function(a) {
      this.ka && (a = this.ka(a));
      return a;
    };
    Y.prototype.ha = function(a) {
      this.W && this.W(a);
    };
    Y.prototype.argPackAdvance = 8;
    Y.prototype.readValueFromPointer = Xa;
    Y.prototype.deleteObject = function(a) {
      if (null !== a) a["delete"]();
    };
    Y.prototype.fromWireType = function(a) {
      function b() {
        return this.da ? Ua(this.N.X, { P: this.wa, O: c, U: this, T: a }) : Ua(this.N.X, { P: this, O: a });
      }
      var c = this.qa(a);
      if (!c) return this.ha(a), null;
      var d = Ra(this.N, c);
      if (void 0 !== d) {
        if (0 === d.M.count.value) return d.M.O = c, d.M.T = a, d.clone();
        d = d.clone();
        this.ha(a);
        return d;
      }
      d = this.N.pa(c);
      d = Qa[d];
      if (!d) return b.call(this);
      d = this.ca ? d.la : d.pointerType;
      var e = Pa(c, this.N, d.N);
      return null === e ? b.call(this) : this.da ? Ua(d.N.X, { P: d, O: e, U: this, T: a }) : Ua(d.N.X, { P: d, O: e });
    };
    mb = h.UnboundTypeError = Da("UnboundTypeError");
    var xa = "function" == typeof atob ? atob : function(a) {
      var b = "", c = 0;
      a = a.replace(/[^A-Za-z0-9\+\/=]/g, "");
      do {
        var d = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".indexOf(a.charAt(c++));
        var e = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".indexOf(a.charAt(c++));
        var f = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".indexOf(a.charAt(c++));
        var g = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".indexOf(a.charAt(c++));
        d = d << 2 | e >> 4;
        e = (e & 15) << 4 | f >> 2;
        var k = (f & 3) << 6 | g;
        b += String.fromCharCode(d);
        64 !== f && (b += String.fromCharCode(e));
        64 !== g && (b += String.fromCharCode(k));
      } while (c < a.length);
      return b;
    }, Jb = {
      l: function(a, b, c, d) {
        x("Assertion failed: " + (a ? z(A, a) : "") + ", at: " + [b ? b ? z(A, b) : "" : "unknown filename", c, d ? d ? z(A, d) : "" : "unknown function"]);
      },
      q: function(a, b, c) {
        a = N(a);
        b = La(b, "wrapper");
        c = M(c);
        var d = [].slice, e = b.N, f = e.X, g = e.R.X, k = e.R.constructor;
        a = Ba(a, function() {
          e.R.ja.forEach(function(l) {
            if (this[l] === g[l]) throw new Fa("Pure virtual function " + l + " must be implemented in JavaScript");
          }.bind(this));
          Object.defineProperty(this, "__parent", { value: f });
          this.__construct.apply(this, d.call(arguments));
        });
        f.__construct = function() {
          this === f && L("Pass correct 'this' to __construct");
          var l = k.implement.apply(void 0, [this].concat(d.call(arguments)));
          Ma(l);
          var n = l.M;
          l.notifyOnDestruction();
          n.aa = true;
          Object.defineProperties(this, { M: { value: n } });
          T(this);
          l = n.O;
          l = Ia(e, l);
          Q.hasOwnProperty(l) ? L("Tried to register registered instance: " + l) : Q[l] = this;
        };
        f.__destruct = function() {
          this === f && L("Pass correct 'this' to __destruct");
          Ma(this);
          var l = this.M.O;
          l = Ia(e, l);
          Q.hasOwnProperty(l) ? delete Q[l] : L("Tried to unregister unregistered instance: " + l);
        };
        a.prototype = Object.create(f);
        for (var m in c) a.prototype[m] = c[m];
        return Ea(a);
      },
      j: function(a) {
        var b = Va[a];
        delete Va[a];
        var c = b.fa, d = b.W, e = b.ia, f = e.map((g) => g.ta).concat(e.map((g) => g.za));
        V([a], f, (g) => {
          var k = {};
          e.forEach((m, l) => {
            var n = g[l], p = m.ra, r = m.sa, u = g[l + e.length], t = m.ya, y = m.Aa;
            k[m.oa] = { read: (B) => n.fromWireType(p(r, B)), write: (B, ba) => {
              var I = [];
              t(
                y,
                B,
                u.toWireType(I, ba)
              );
              Wa(I);
            } };
          });
          return [{ name: b.name, fromWireType: function(m) {
            var l = {}, n;
            for (n in k) l[n] = k[n].read(m);
            d(m);
            return l;
          }, toWireType: function(m, l) {
            for (var n in k) if (!(n in l)) throw new TypeError('Missing field:  "' + n + '"');
            var p = c();
            for (n in k) k[n].write(p, l[n]);
            null !== m && m.push(d, p);
            return p;
          }, argPackAdvance: 8, readValueFromPointer: Xa, V: d }];
        });
      },
      v: function() {
      },
      B: function(a, b, c, d, e) {
        var f = Za(c);
        b = N(b);
        W(a, {
          name: b,
          fromWireType: function(g) {
            return !!g;
          },
          toWireType: function(g, k) {
            return k ? d : e;
          },
          argPackAdvance: 8,
          readValueFromPointer: function(g) {
            if (1 === c) var k = ja;
            else if (2 === c) k = C;
            else if (4 === c) k = D;
            else throw new TypeError("Unknown boolean type size: " + b);
            return this.fromWireType(k[g >> f]);
          },
          V: null
        });
      },
      f: function(a, b, c, d, e, f, g, k, m, l, n, p, r) {
        n = N(n);
        f = Z(e, f);
        k && (k = Z(g, k));
        l && (l = Z(m, l));
        r = Z(p, r);
        var u = Aa(n);
        bb(u, function() {
          nb("Cannot construct " + n + " due to unbound types", [d]);
        });
        V([a, b, c], d ? [d] : [], function(t) {
          t = t[0];
          if (d) {
            var y = t.N;
            var B = y.X;
          } else B = X.prototype;
          t = Ba(u, function() {
            if (Object.getPrototypeOf(this) !== ba) throw new K("Use 'new' to construct " + n);
            if (void 0 === I.Y) throw new K(n + " has no accessible constructor");
            var kb = I.Y[arguments.length];
            if (void 0 === kb) throw new K("Tried to invoke ctor of " + n + " with invalid number of parameters (" + arguments.length + ") - expected (" + Object.keys(I.Y).toString() + ") parameters instead!");
            return kb.apply(this, arguments);
          });
          var ba = Object.create(B, { constructor: { value: t } });
          t.prototype = ba;
          var I = new cb(n, t, ba, r, y, f, k, l);
          y = new Y(n, I, true, false);
          B = new Y(n + "*", I, false, false);
          var lb = new Y(n + " const*", I, false, true);
          Qa[a] = {
            pointerType: B,
            la: lb
          };
          ib(u, t);
          return [y, B, lb];
        });
      },
      d: function(a, b, c, d, e, f, g) {
        var k = pb(c, d);
        b = N(b);
        f = Z(e, f);
        V([], [a], function(m) {
          function l() {
            nb("Cannot call " + n + " due to unbound types", k);
          }
          m = m[0];
          var n = m.name + "." + b;
          b.startsWith("@@") && (b = Symbol[b.substring(2)]);
          var p = m.N.constructor;
          void 0 === p[b] ? (l.Z = c - 1, p[b] = l) : (ab(p, b, n), p[b].S[c - 1] = l);
          V([], k, function(r) {
            r = ob(n, [r[0], null].concat(r.slice(1)), null, f, g);
            void 0 === p[b].S ? (r.Z = c - 1, p[b] = r) : p[b].S[c - 1] = r;
            return [];
          });
          return [];
        });
      },
      p: function(a, b, c, d, e, f) {
        0 < b || x();
        var g = pb(
          b,
          c
        );
        e = Z(d, e);
        V([], [a], function(k) {
          k = k[0];
          var m = "constructor " + k.name;
          void 0 === k.N.Y && (k.N.Y = []);
          if (void 0 !== k.N.Y[b - 1]) throw new K("Cannot register multiple constructors with identical number of parameters (" + (b - 1) + ") for class '" + k.name + "'! Overload resolution is currently only performed using the parameter count, not actual type info!");
          k.N.Y[b - 1] = () => {
            nb("Cannot construct " + k.name + " due to unbound types", g);
          };
          V([], g, function(l) {
            l.splice(1, 0, null);
            k.N.Y[b - 1] = ob(m, l, null, e, f);
            return [];
          });
          return [];
        });
      },
      a: function(a, b, c, d, e, f, g, k) {
        var m = pb(c, d);
        b = N(b);
        f = Z(e, f);
        V([], [a], function(l) {
          function n() {
            nb("Cannot call " + p + " due to unbound types", m);
          }
          l = l[0];
          var p = l.name + "." + b;
          b.startsWith("@@") && (b = Symbol[b.substring(2)]);
          k && l.N.ja.push(b);
          var r = l.N.X, u = r[b];
          void 0 === u || void 0 === u.S && u.className !== l.name && u.Z === c - 2 ? (n.Z = c - 2, n.className = l.name, r[b] = n) : (ab(r, b, p), r[b].S[c - 2] = n);
          V([], m, function(t) {
            t = ob(p, t, l, f, g);
            void 0 === r[b].S ? (t.Z = c - 2, r[b] = t) : r[b].S[c - 2] = t;
            return [];
          });
          return [];
        });
      },
      A: function(a, b) {
        b = N(b);
        W(
          a,
          { name: b, fromWireType: function(c) {
            var d = M(c);
            qb(c);
            return d;
          }, toWireType: function(c, d) {
            return Ea(d);
          }, argPackAdvance: 8, readValueFromPointer: Xa, V: null }
        );
      },
      n: function(a, b, c) {
        c = Za(c);
        b = N(b);
        W(a, { name: b, fromWireType: function(d) {
          return d;
        }, toWireType: function(d, e) {
          return e;
        }, argPackAdvance: 8, readValueFromPointer: rb(b, c), V: null });
      },
      e: function(a, b, c, d, e) {
        b = N(b);
        -1 === e && (e = 4294967295);
        e = Za(c);
        var f = (k) => k;
        if (0 === d) {
          var g = 32 - 8 * c;
          f = (k) => k << g >>> g;
        }
        c = b.includes("unsigned") ? function(k, m) {
          return m >>> 0;
        } : function(k, m) {
          return m;
        };
        W(a, { name: b, fromWireType: f, toWireType: c, argPackAdvance: 8, readValueFromPointer: sb(b, e, 0 !== d), V: null });
      },
      b: function(a, b, c) {
        function d(f) {
          f >>= 2;
          var g = E;
          return new e(ia, g[f + 1], g[f]);
        }
        var e = [Int8Array, Uint8Array, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array][b];
        c = N(c);
        W(a, { name: c, fromWireType: d, argPackAdvance: 8, readValueFromPointer: d }, { ua: true });
      },
      o: function(a, b) {
        b = N(b);
        var c = "std::string" === b;
        W(a, { name: b, fromWireType: function(d) {
          var e = E[d >> 2], f = d + 4;
          if (c) for (var g = f, k = 0; k <= e; ++k) {
            var m = f + k;
            if (k == e || 0 == A[m]) {
              g = g ? z(A, g, m - g) : "";
              if (void 0 === l) var l = g;
              else l += String.fromCharCode(0), l += g;
              g = m + 1;
            }
          }
          else {
            l = Array(e);
            for (k = 0; k < e; ++k) l[k] = String.fromCharCode(A[f + k]);
            l = l.join("");
          }
          S(d);
          return l;
        }, toWireType: function(d, e) {
          e instanceof ArrayBuffer && (e = new Uint8Array(e));
          var f, g = "string" == typeof e;
          g || e instanceof Uint8Array || e instanceof Uint8ClampedArray || e instanceof Int8Array || L("Cannot pass non-string to std::string");
          if (c && g) {
            var k = 0;
            for (f = 0; f < e.length; ++f) {
              var m = e.charCodeAt(f);
              127 >= m ? k++ : 2047 >= m ? k += 2 : 55296 <= m && 57343 >= m ? (k += 4, ++f) : k += 3;
            }
            f = k;
          } else f = e.length;
          k = Ib(4 + f + 1);
          m = k + 4;
          E[k >> 2] = f;
          if (c && g) {
            if (g = m, m = f + 1, f = A, 0 < m) {
              m = g + m - 1;
              for (var l = 0; l < e.length; ++l) {
                var n = e.charCodeAt(l);
                if (55296 <= n && 57343 >= n) {
                  var p = e.charCodeAt(++l);
                  n = 65536 + ((n & 1023) << 10) | p & 1023;
                }
                if (127 >= n) {
                  if (g >= m) break;
                  f[g++] = n;
                } else {
                  if (2047 >= n) {
                    if (g + 1 >= m) break;
                    f[g++] = 192 | n >> 6;
                  } else {
                    if (65535 >= n) {
                      if (g + 2 >= m) break;
                      f[g++] = 224 | n >> 12;
                    } else {
                      if (g + 3 >= m) break;
                      f[g++] = 240 | n >> 18;
                      f[g++] = 128 | n >> 12 & 63;
                    }
                    f[g++] = 128 | n >> 6 & 63;
                  }
                  f[g++] = 128 | n & 63;
                }
              }
              f[g] = 0;
            }
          } else if (g) for (g = 0; g < f; ++g) l = e.charCodeAt(g), 255 < l && (S(m), L("String has UTF-16 code units that do not fit in 8 bits")), A[m + g] = l;
          else for (g = 0; g < f; ++g) A[m + g] = e[g];
          null !== d && d.push(S, k);
          return k;
        }, argPackAdvance: 8, readValueFromPointer: Xa, V: function(d) {
          S(d);
        } });
      },
      i: function(a, b, c) {
        c = N(c);
        if (2 === b) {
          var d = tb;
          var e = ub;
          var f = vb;
          var g = () => ka;
          var k = 1;
        } else 4 === b && (d = wb, e = xb, f = yb, g = () => E, k = 2);
        W(a, { name: c, fromWireType: function(m) {
          for (var l = E[m >> 2], n = g(), p, r = m + 4, u = 0; u <= l; ++u) {
            var t = m + 4 + u * b;
            if (u == l || 0 == n[t >> k]) r = d(r, t - r), void 0 === p ? p = r : (p += String.fromCharCode(0), p += r), r = t + b;
          }
          S(m);
          return p;
        }, toWireType: function(m, l) {
          "string" != typeof l && L("Cannot pass non-string to C++ string type " + c);
          var n = f(l), p = Ib(4 + n + b);
          E[p >> 2] = n >> k;
          e(l, p + 4, n + b);
          null !== m && m.push(S, p);
          return p;
        }, argPackAdvance: 8, readValueFromPointer: Xa, V: function(m) {
          S(m);
        } });
      },
      k: function(a, b, c, d, e, f) {
        Va[a] = { name: N(b), fa: Z(c, d), W: Z(e, f), ia: [] };
      },
      h: function(a, b, c, d, e, f, g, k, m, l) {
        Va[a].ia.push({ oa: N(b), ta: c, ra: Z(d, e), sa: f, za: g, ya: Z(k, m), Aa: l });
      },
      C: function(a, b) {
        b = N(b);
        W(a, {
          va: true,
          name: b,
          argPackAdvance: 0,
          fromWireType: function() {
          },
          toWireType: function() {
          }
        });
      },
      s: function(a, b, c, d, e) {
        a = Bb[a];
        b = M(b);
        c = Ab(c);
        var f = [];
        E[d >> 2] = Ea(f);
        return a(b, c, f, e);
      },
      t: function(a, b, c, d) {
        a = Bb[a];
        b = M(b);
        c = Ab(c);
        a(b, c, null, d);
      },
      g: qb,
      m: function(a, b) {
        var c = Db(a, b), d = c[0];
        b = d.name + "_$" + c.slice(1).map(function(g) {
          return g.name;
        }).join("_") + "$";
        var e = Eb[b];
        if (void 0 !== e) return e;
        var f = Array(a - 1);
        e = Cb((g, k, m, l) => {
          for (var n = 0, p = 0; p < a - 1; ++p) f[p] = c[p + 1].readValueFromPointer(l + n), n += c[p + 1].argPackAdvance;
          g = g[k].apply(
            g,
            f
          );
          for (p = 0; p < a - 1; ++p) c[p + 1].ma && c[p + 1].ma(f[p]);
          if (!d.va) return d.toWireType(m, g);
        });
        return Eb[b] = e;
      },
      D: function(a) {
        4 < a && (J[a].ga += 1);
      },
      r: function(a) {
        var b = M(a);
        Wa(b);
        qb(a);
      },
      c: function() {
        x("");
      },
      x: function(a, b, c) {
        A.copyWithin(a, b, b + c);
      },
      w: function(a) {
        var b = A.length;
        a >>>= 0;
        if (2147483648 < a) return false;
        for (var c = 1; 4 >= c; c *= 2) {
          var d = b * (1 + 0.2 / c);
          d = Math.min(d, a + 100663296);
          var e = Math;
          d = Math.max(a, d);
          e = e.min.call(e, 2147483648, d + (65536 - d % 65536) % 65536);
          a: {
            try {
              fa.grow(e - ia.byteLength + 65535 >>> 16);
              na();
              var f = 1;
              break a;
            } catch (g) {
            }
            f = void 0;
          }
          if (f) return true;
        }
        return false;
      },
      z: function() {
        return 52;
      },
      u: function() {
        return 70;
      },
      y: function(a, b, c, d) {
        for (var e = 0, f = 0; f < c; f++) {
          var g = E[b >> 2], k = E[b + 4 >> 2];
          b += 8;
          for (var m = 0; m < k; m++) {
            var l = A[g + m], n = Fb[a];
            0 === l || 10 === l ? ((1 === a ? ea : v)(z(n, 0)), n.length = 0) : n.push(l);
          }
          e += k;
        }
        E[d >> 2] = e;
        return 0;
      }
    };
    (function() {
      function a(e) {
        h.asm = e.exports;
        fa = h.asm.E;
        na();
        oa = h.asm.J;
        qa.unshift(h.asm.F);
        F--;
        h.monitorRunDependencies && h.monitorRunDependencies(F);
        0 == F && (null !== ta && (clearInterval(ta), ta = null), G && (e = G, G = null, e()));
      }
      function b(e) {
        a(e.instance);
      }
      function c(e) {
        return ya().then(function(f) {
          return WebAssembly.instantiate(f, d);
        }).then(function(f) {
          return f;
        }).then(e, function(f) {
          v("failed to asynchronously prepare wasm: " + f);
          x(f);
        });
      }
      var d = { a: Jb };
      F++;
      h.monitorRunDependencies && h.monitorRunDependencies(F);
      if (h.instantiateWasm) try {
        return h.instantiateWasm(
          d,
          a
        );
      } catch (e) {
        v("Module.instantiateWasm callback failed with error: " + e), ca(e);
      }
      (function() {
        return w || "function" != typeof WebAssembly.instantiateStreaming || ua(H) || "function" != typeof fetch ? c(b) : fetch(H, { credentials: "same-origin" }).then(function(e) {
          return WebAssembly.instantiateStreaming(e, d).then(b, function(f) {
            v("wasm streaming compile failed: " + f);
            v("falling back to ArrayBuffer instantiation");
            return c(b);
          });
        });
      })().catch(ca);
      return {};
    })();
    h.___wasm_call_ctors = function() {
      return (h.___wasm_call_ctors = h.asm.F).apply(null, arguments);
    };
    var Ka = h.___getTypeName = function() {
      return (Ka = h.___getTypeName = h.asm.G).apply(null, arguments);
    };
    h.__embind_initialize_bindings = function() {
      return (h.__embind_initialize_bindings = h.asm.H).apply(null, arguments);
    };
    var Ib = h._malloc = function() {
      return (Ib = h._malloc = h.asm.I).apply(null, arguments);
    }, S = h._free = function() {
      return (S = h._free = h.asm.K).apply(null, arguments);
    };
    h.dynCall_jiji = function() {
      return (h.dynCall_jiji = h.asm.L).apply(null, arguments);
    };
    var Kb;
    G = function Lb() {
      Kb || Mb();
      Kb || (G = Lb);
    };
    function Mb() {
      function a() {
        if (!Kb && (Kb = true, h.calledRun = true, !ha)) {
          za(qa);
          aa(h);
          if (h.onRuntimeInitialized) h.onRuntimeInitialized();
          if (h.postRun) for ("function" == typeof h.postRun && (h.postRun = [h.postRun]); h.postRun.length; ) {
            var b = h.postRun.shift();
            ra.unshift(b);
          }
          za(ra);
        }
      }
      if (!(0 < F)) {
        if (h.preRun) for ("function" == typeof h.preRun && (h.preRun = [h.preRun]); h.preRun.length; ) sa();
        za(pa);
        0 < F || (h.setStatus ? (h.setStatus("Running..."), setTimeout(function() {
          setTimeout(function() {
            h.setStatus("");
          }, 1);
          a();
        }, 1)) : a());
      }
    }
    if (h.preInit) for ("function" == typeof h.preInit && (h.preInit = [h.preInit]); 0 < h.preInit.length; ) h.preInit.pop()();
    Mb();
    return loadYoga2.ready;
  });
})();
var yoga_wasm_base64_esm_default = loadYoga;

// node_modules/yoga-layout/dist/src/generated/YGEnums.js
var Align = /* @__PURE__ */ (function(Align2) {
  Align2[Align2["Auto"] = 0] = "Auto";
  Align2[Align2["FlexStart"] = 1] = "FlexStart";
  Align2[Align2["Center"] = 2] = "Center";
  Align2[Align2["FlexEnd"] = 3] = "FlexEnd";
  Align2[Align2["Stretch"] = 4] = "Stretch";
  Align2[Align2["Baseline"] = 5] = "Baseline";
  Align2[Align2["SpaceBetween"] = 6] = "SpaceBetween";
  Align2[Align2["SpaceAround"] = 7] = "SpaceAround";
  Align2[Align2["SpaceEvenly"] = 8] = "SpaceEvenly";
  return Align2;
})({});
var BoxSizing = /* @__PURE__ */ (function(BoxSizing2) {
  BoxSizing2[BoxSizing2["BorderBox"] = 0] = "BorderBox";
  BoxSizing2[BoxSizing2["ContentBox"] = 1] = "ContentBox";
  return BoxSizing2;
})({});
var Dimension = /* @__PURE__ */ (function(Dimension2) {
  Dimension2[Dimension2["Width"] = 0] = "Width";
  Dimension2[Dimension2["Height"] = 1] = "Height";
  return Dimension2;
})({});
var Direction = /* @__PURE__ */ (function(Direction2) {
  Direction2[Direction2["Inherit"] = 0] = "Inherit";
  Direction2[Direction2["LTR"] = 1] = "LTR";
  Direction2[Direction2["RTL"] = 2] = "RTL";
  return Direction2;
})({});
var Display = /* @__PURE__ */ (function(Display2) {
  Display2[Display2["Flex"] = 0] = "Flex";
  Display2[Display2["None"] = 1] = "None";
  Display2[Display2["Contents"] = 2] = "Contents";
  return Display2;
})({});
var Edge = /* @__PURE__ */ (function(Edge2) {
  Edge2[Edge2["Left"] = 0] = "Left";
  Edge2[Edge2["Top"] = 1] = "Top";
  Edge2[Edge2["Right"] = 2] = "Right";
  Edge2[Edge2["Bottom"] = 3] = "Bottom";
  Edge2[Edge2["Start"] = 4] = "Start";
  Edge2[Edge2["End"] = 5] = "End";
  Edge2[Edge2["Horizontal"] = 6] = "Horizontal";
  Edge2[Edge2["Vertical"] = 7] = "Vertical";
  Edge2[Edge2["All"] = 8] = "All";
  return Edge2;
})({});
var Errata = /* @__PURE__ */ (function(Errata2) {
  Errata2[Errata2["None"] = 0] = "None";
  Errata2[Errata2["StretchFlexBasis"] = 1] = "StretchFlexBasis";
  Errata2[Errata2["AbsolutePositionWithoutInsetsExcludesPadding"] = 2] = "AbsolutePositionWithoutInsetsExcludesPadding";
  Errata2[Errata2["AbsolutePercentAgainstInnerSize"] = 4] = "AbsolutePercentAgainstInnerSize";
  Errata2[Errata2["All"] = 2147483647] = "All";
  Errata2[Errata2["Classic"] = 2147483646] = "Classic";
  return Errata2;
})({});
var ExperimentalFeature = /* @__PURE__ */ (function(ExperimentalFeature2) {
  ExperimentalFeature2[ExperimentalFeature2["WebFlexBasis"] = 0] = "WebFlexBasis";
  return ExperimentalFeature2;
})({});
var FlexDirection = /* @__PURE__ */ (function(FlexDirection2) {
  FlexDirection2[FlexDirection2["Column"] = 0] = "Column";
  FlexDirection2[FlexDirection2["ColumnReverse"] = 1] = "ColumnReverse";
  FlexDirection2[FlexDirection2["Row"] = 2] = "Row";
  FlexDirection2[FlexDirection2["RowReverse"] = 3] = "RowReverse";
  return FlexDirection2;
})({});
var Gutter = /* @__PURE__ */ (function(Gutter2) {
  Gutter2[Gutter2["Column"] = 0] = "Column";
  Gutter2[Gutter2["Row"] = 1] = "Row";
  Gutter2[Gutter2["All"] = 2] = "All";
  return Gutter2;
})({});
var Justify = /* @__PURE__ */ (function(Justify2) {
  Justify2[Justify2["FlexStart"] = 0] = "FlexStart";
  Justify2[Justify2["Center"] = 1] = "Center";
  Justify2[Justify2["FlexEnd"] = 2] = "FlexEnd";
  Justify2[Justify2["SpaceBetween"] = 3] = "SpaceBetween";
  Justify2[Justify2["SpaceAround"] = 4] = "SpaceAround";
  Justify2[Justify2["SpaceEvenly"] = 5] = "SpaceEvenly";
  return Justify2;
})({});
var LogLevel = /* @__PURE__ */ (function(LogLevel2) {
  LogLevel2[LogLevel2["Error"] = 0] = "Error";
  LogLevel2[LogLevel2["Warn"] = 1] = "Warn";
  LogLevel2[LogLevel2["Info"] = 2] = "Info";
  LogLevel2[LogLevel2["Debug"] = 3] = "Debug";
  LogLevel2[LogLevel2["Verbose"] = 4] = "Verbose";
  LogLevel2[LogLevel2["Fatal"] = 5] = "Fatal";
  return LogLevel2;
})({});
var MeasureMode = /* @__PURE__ */ (function(MeasureMode2) {
  MeasureMode2[MeasureMode2["Undefined"] = 0] = "Undefined";
  MeasureMode2[MeasureMode2["Exactly"] = 1] = "Exactly";
  MeasureMode2[MeasureMode2["AtMost"] = 2] = "AtMost";
  return MeasureMode2;
})({});
var NodeType = /* @__PURE__ */ (function(NodeType2) {
  NodeType2[NodeType2["Default"] = 0] = "Default";
  NodeType2[NodeType2["Text"] = 1] = "Text";
  return NodeType2;
})({});
var Overflow = /* @__PURE__ */ (function(Overflow2) {
  Overflow2[Overflow2["Visible"] = 0] = "Visible";
  Overflow2[Overflow2["Hidden"] = 1] = "Hidden";
  Overflow2[Overflow2["Scroll"] = 2] = "Scroll";
  return Overflow2;
})({});
var PositionType = /* @__PURE__ */ (function(PositionType2) {
  PositionType2[PositionType2["Static"] = 0] = "Static";
  PositionType2[PositionType2["Relative"] = 1] = "Relative";
  PositionType2[PositionType2["Absolute"] = 2] = "Absolute";
  return PositionType2;
})({});
var Unit = /* @__PURE__ */ (function(Unit2) {
  Unit2[Unit2["Undefined"] = 0] = "Undefined";
  Unit2[Unit2["Point"] = 1] = "Point";
  Unit2[Unit2["Percent"] = 2] = "Percent";
  Unit2[Unit2["Auto"] = 3] = "Auto";
  return Unit2;
})({});
var Wrap = /* @__PURE__ */ (function(Wrap2) {
  Wrap2[Wrap2["NoWrap"] = 0] = "NoWrap";
  Wrap2[Wrap2["Wrap"] = 1] = "Wrap";
  Wrap2[Wrap2["WrapReverse"] = 2] = "WrapReverse";
  return Wrap2;
})({});
var constants = {
  ALIGN_AUTO: Align.Auto,
  ALIGN_FLEX_START: Align.FlexStart,
  ALIGN_CENTER: Align.Center,
  ALIGN_FLEX_END: Align.FlexEnd,
  ALIGN_STRETCH: Align.Stretch,
  ALIGN_BASELINE: Align.Baseline,
  ALIGN_SPACE_BETWEEN: Align.SpaceBetween,
  ALIGN_SPACE_AROUND: Align.SpaceAround,
  ALIGN_SPACE_EVENLY: Align.SpaceEvenly,
  BOX_SIZING_BORDER_BOX: BoxSizing.BorderBox,
  BOX_SIZING_CONTENT_BOX: BoxSizing.ContentBox,
  DIMENSION_WIDTH: Dimension.Width,
  DIMENSION_HEIGHT: Dimension.Height,
  DIRECTION_INHERIT: Direction.Inherit,
  DIRECTION_LTR: Direction.LTR,
  DIRECTION_RTL: Direction.RTL,
  DISPLAY_FLEX: Display.Flex,
  DISPLAY_NONE: Display.None,
  DISPLAY_CONTENTS: Display.Contents,
  EDGE_LEFT: Edge.Left,
  EDGE_TOP: Edge.Top,
  EDGE_RIGHT: Edge.Right,
  EDGE_BOTTOM: Edge.Bottom,
  EDGE_START: Edge.Start,
  EDGE_END: Edge.End,
  EDGE_HORIZONTAL: Edge.Horizontal,
  EDGE_VERTICAL: Edge.Vertical,
  EDGE_ALL: Edge.All,
  ERRATA_NONE: Errata.None,
  ERRATA_STRETCH_FLEX_BASIS: Errata.StretchFlexBasis,
  ERRATA_ABSOLUTE_POSITION_WITHOUT_INSETS_EXCLUDES_PADDING: Errata.AbsolutePositionWithoutInsetsExcludesPadding,
  ERRATA_ABSOLUTE_PERCENT_AGAINST_INNER_SIZE: Errata.AbsolutePercentAgainstInnerSize,
  ERRATA_ALL: Errata.All,
  ERRATA_CLASSIC: Errata.Classic,
  EXPERIMENTAL_FEATURE_WEB_FLEX_BASIS: ExperimentalFeature.WebFlexBasis,
  FLEX_DIRECTION_COLUMN: FlexDirection.Column,
  FLEX_DIRECTION_COLUMN_REVERSE: FlexDirection.ColumnReverse,
  FLEX_DIRECTION_ROW: FlexDirection.Row,
  FLEX_DIRECTION_ROW_REVERSE: FlexDirection.RowReverse,
  GUTTER_COLUMN: Gutter.Column,
  GUTTER_ROW: Gutter.Row,
  GUTTER_ALL: Gutter.All,
  JUSTIFY_FLEX_START: Justify.FlexStart,
  JUSTIFY_CENTER: Justify.Center,
  JUSTIFY_FLEX_END: Justify.FlexEnd,
  JUSTIFY_SPACE_BETWEEN: Justify.SpaceBetween,
  JUSTIFY_SPACE_AROUND: Justify.SpaceAround,
  JUSTIFY_SPACE_EVENLY: Justify.SpaceEvenly,
  LOG_LEVEL_ERROR: LogLevel.Error,
  LOG_LEVEL_WARN: LogLevel.Warn,
  LOG_LEVEL_INFO: LogLevel.Info,
  LOG_LEVEL_DEBUG: LogLevel.Debug,
  LOG_LEVEL_VERBOSE: LogLevel.Verbose,
  LOG_LEVEL_FATAL: LogLevel.Fatal,
  MEASURE_MODE_UNDEFINED: MeasureMode.Undefined,
  MEASURE_MODE_EXACTLY: MeasureMode.Exactly,
  MEASURE_MODE_AT_MOST: MeasureMode.AtMost,
  NODE_TYPE_DEFAULT: NodeType.Default,
  NODE_TYPE_TEXT: NodeType.Text,
  OVERFLOW_VISIBLE: Overflow.Visible,
  OVERFLOW_HIDDEN: Overflow.Hidden,
  OVERFLOW_SCROLL: Overflow.Scroll,
  POSITION_TYPE_STATIC: PositionType.Static,
  POSITION_TYPE_RELATIVE: PositionType.Relative,
  POSITION_TYPE_ABSOLUTE: PositionType.Absolute,
  UNIT_UNDEFINED: Unit.Undefined,
  UNIT_POINT: Unit.Point,
  UNIT_PERCENT: Unit.Percent,
  UNIT_AUTO: Unit.Auto,
  WRAP_NO_WRAP: Wrap.NoWrap,
  WRAP_WRAP: Wrap.Wrap,
  WRAP_WRAP_REVERSE: Wrap.WrapReverse
};
var YGEnums_default = constants;

// node_modules/yoga-layout/dist/src/wrapAssembly.js
function wrapAssembly(lib) {
  function patch(prototype, name, fn) {
    const original = prototype[name];
    prototype[name] = function() {
      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }
      return fn.call(this, original, ...args);
    };
  }
  for (const fnName of ["setPosition", "setMargin", "setFlexBasis", "setWidth", "setHeight", "setMinWidth", "setMinHeight", "setMaxWidth", "setMaxHeight", "setPadding", "setGap"]) {
    const methods = {
      [Unit.Point]: lib.Node.prototype[fnName],
      [Unit.Percent]: lib.Node.prototype[`${fnName}Percent`],
      [Unit.Auto]: lib.Node.prototype[`${fnName}Auto`]
    };
    patch(lib.Node.prototype, fnName, function(original) {
      for (var _len2 = arguments.length, args = new Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
        args[_key2 - 1] = arguments[_key2];
      }
      const value = args.pop();
      let unit, asNumber;
      if (value === "auto") {
        unit = Unit.Auto;
        asNumber = void 0;
      } else if (typeof value === "object") {
        unit = value.unit;
        asNumber = value.valueOf();
      } else {
        unit = typeof value === "string" && value.endsWith("%") ? Unit.Percent : Unit.Point;
        asNumber = parseFloat(value);
        if (value !== void 0 && !Number.isNaN(value) && Number.isNaN(asNumber)) {
          throw new Error(`Invalid value ${value} for ${fnName}`);
        }
      }
      if (!methods[unit]) throw new Error(`Failed to execute "${fnName}": Unsupported unit '${value}'`);
      if (asNumber !== void 0) {
        return methods[unit].call(this, ...args, asNumber);
      } else {
        return methods[unit].call(this, ...args);
      }
    });
  }
  function wrapMeasureFunction(measureFunction) {
    return lib.MeasureCallback.implement({
      measure: function() {
        const {
          width,
          height
        } = measureFunction(...arguments);
        return {
          width: width ?? NaN,
          height: height ?? NaN
        };
      }
    });
  }
  patch(lib.Node.prototype, "setMeasureFunc", function(original, measureFunc) {
    if (measureFunc) {
      return original.call(this, wrapMeasureFunction(measureFunc));
    } else {
      return this.unsetMeasureFunc();
    }
  });
  function wrapDirtiedFunc(dirtiedFunction) {
    return lib.DirtiedCallback.implement({
      dirtied: dirtiedFunction
    });
  }
  patch(lib.Node.prototype, "setDirtiedFunc", function(original, dirtiedFunc) {
    original.call(this, wrapDirtiedFunc(dirtiedFunc));
  });
  patch(lib.Config.prototype, "free", function() {
    lib.Config.destroy(this);
  });
  patch(lib.Node, "create", (_, config) => {
    return config ? lib.Node.createWithConfig(config) : lib.Node.createDefault();
  });
  patch(lib.Node.prototype, "free", function() {
    lib.Node.destroy(this);
  });
  patch(lib.Node.prototype, "freeRecursive", function() {
    for (let t = 0, T = this.getChildCount(); t < T; ++t) {
      this.getChild(0).freeRecursive();
    }
    this.free();
  });
  patch(lib.Node.prototype, "calculateLayout", function(original) {
    let width = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : NaN;
    let height = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : NaN;
    let direction = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : Direction.LTR;
    return original.call(this, width, height, direction);
  });
  return {
    Config: lib.Config,
    Node: lib.Node,
    ...YGEnums_default
  };
}

// node_modules/yoga-layout/dist/src/index.js
var Yoga = wrapAssembly(await yoga_wasm_base64_esm_default());
var src_default = Yoga;

// node_modules/ink/build/reconciler.js
var import_react_reconciler = __toESM(require_react_reconciler(), 1);
var import_constants = __toESM(require_constants(), 1);
import process3 from "process";

// node_modules/ansi-regex/index.js
function ansiRegex({ onlyFirst = false } = {}) {
  const ST = "(?:\\u0007|\\u001B\\u005C|\\u009C)";
  const osc = `(?:\\u001B\\][\\s\\S]*?${ST})`;
  const csi = "[\\u001B\\u009B][[\\]()#;?]*(?:\\d{1,4}(?:[;:]\\d{0,4})*)?[\\dA-PR-TZcf-nq-uy=><~]";
  const pattern = `${osc}|${csi}`;
  return new RegExp(pattern, onlyFirst ? void 0 : "g");
}

// node_modules/strip-ansi/index.js
var regex = ansiRegex();
function stripAnsi(string) {
  if (typeof string !== "string") {
    throw new TypeError(`Expected a \`string\`, got \`${typeof string}\``);
  }
  if (!string.includes("\x1B") && !string.includes("\x9B")) {
    return string;
  }
  return string.replace(regex, "");
}

// node_modules/get-east-asian-width/lookup-data.js
var ambiguousRanges = [161, 161, 164, 164, 167, 168, 170, 170, 173, 174, 176, 180, 182, 186, 188, 191, 198, 198, 208, 208, 215, 216, 222, 225, 230, 230, 232, 234, 236, 237, 240, 240, 242, 243, 247, 250, 252, 252, 254, 254, 257, 257, 273, 273, 275, 275, 283, 283, 294, 295, 299, 299, 305, 307, 312, 312, 319, 322, 324, 324, 328, 331, 333, 333, 338, 339, 358, 359, 363, 363, 462, 462, 464, 464, 466, 466, 468, 468, 470, 470, 472, 472, 474, 474, 476, 476, 593, 593, 609, 609, 708, 708, 711, 711, 713, 715, 717, 717, 720, 720, 728, 731, 733, 733, 735, 735, 768, 879, 913, 929, 931, 937, 945, 961, 963, 969, 1025, 1025, 1040, 1103, 1105, 1105, 8208, 8208, 8211, 8214, 8216, 8217, 8220, 8221, 8224, 8226, 8228, 8231, 8240, 8240, 8242, 8243, 8245, 8245, 8251, 8251, 8254, 8254, 8308, 8308, 8319, 8319, 8321, 8324, 8364, 8364, 8451, 8451, 8453, 8453, 8457, 8457, 8467, 8467, 8470, 8470, 8481, 8482, 8486, 8486, 8491, 8491, 8531, 8532, 8539, 8542, 8544, 8555, 8560, 8569, 8585, 8585, 8592, 8601, 8632, 8633, 8658, 8658, 8660, 8660, 8679, 8679, 8704, 8704, 8706, 8707, 8711, 8712, 8715, 8715, 8719, 8719, 8721, 8721, 8725, 8725, 8730, 8730, 8733, 8736, 8739, 8739, 8741, 8741, 8743, 8748, 8750, 8750, 8756, 8759, 8764, 8765, 8776, 8776, 8780, 8780, 8786, 8786, 8800, 8801, 8804, 8807, 8810, 8811, 8814, 8815, 8834, 8835, 8838, 8839, 8853, 8853, 8857, 8857, 8869, 8869, 8895, 8895, 8978, 8978, 9312, 9449, 9451, 9547, 9552, 9587, 9600, 9615, 9618, 9621, 9632, 9633, 9635, 9641, 9650, 9651, 9654, 9655, 9660, 9661, 9664, 9665, 9670, 9672, 9675, 9675, 9678, 9681, 9698, 9701, 9711, 9711, 9733, 9734, 9737, 9737, 9742, 9743, 9756, 9756, 9758, 9758, 9792, 9792, 9794, 9794, 9824, 9825, 9827, 9829, 9831, 9834, 9836, 9837, 9839, 9839, 9886, 9887, 9919, 9919, 9926, 9933, 9935, 9939, 9941, 9953, 9955, 9955, 9960, 9961, 9963, 9969, 9972, 9972, 9974, 9977, 9979, 9980, 9982, 9983, 10045, 10045, 10102, 10111, 11094, 11097, 12872, 12879, 57344, 63743, 65024, 65039, 65533, 65533, 127232, 127242, 127248, 127277, 127280, 127337, 127344, 127373, 127375, 127376, 127387, 127404, 917760, 917999, 983040, 1048573, 1048576, 1114109];
var fullwidthRanges = [12288, 12288, 65281, 65376, 65504, 65510];
var halfwidthRanges = [8361, 8361, 65377, 65470, 65474, 65479, 65482, 65487, 65490, 65495, 65498, 65500, 65512, 65518];
var narrowRanges = [32, 126, 162, 163, 165, 166, 172, 172, 175, 175, 10214, 10221, 10629, 10630];
var wideRanges = [4352, 4447, 8986, 8987, 9001, 9002, 9193, 9196, 9200, 9200, 9203, 9203, 9725, 9726, 9748, 9749, 9776, 9783, 9800, 9811, 9855, 9855, 9866, 9871, 9875, 9875, 9889, 9889, 9898, 9899, 9917, 9918, 9924, 9925, 9934, 9934, 9940, 9940, 9962, 9962, 9970, 9971, 9973, 9973, 9978, 9978, 9981, 9981, 9989, 9989, 9994, 9995, 10024, 10024, 10060, 10060, 10062, 10062, 10067, 10069, 10071, 10071, 10133, 10135, 10160, 10160, 10175, 10175, 11035, 11036, 11088, 11088, 11093, 11093, 11904, 11929, 11931, 12019, 12032, 12245, 12272, 12287, 12289, 12350, 12353, 12438, 12441, 12543, 12549, 12591, 12593, 12686, 12688, 12773, 12783, 12830, 12832, 12871, 12880, 42124, 42128, 42182, 43360, 43388, 44032, 55203, 63744, 64255, 65040, 65049, 65072, 65106, 65108, 65126, 65128, 65131, 94176, 94180, 94192, 94198, 94208, 101589, 101631, 101662, 101760, 101874, 110576, 110579, 110581, 110587, 110589, 110590, 110592, 110882, 110898, 110898, 110928, 110930, 110933, 110933, 110948, 110951, 110960, 111355, 119552, 119638, 119648, 119670, 126980, 126980, 127183, 127183, 127374, 127374, 127377, 127386, 127488, 127490, 127504, 127547, 127552, 127560, 127568, 127569, 127584, 127589, 127744, 127776, 127789, 127797, 127799, 127868, 127870, 127891, 127904, 127946, 127951, 127955, 127968, 127984, 127988, 127988, 127992, 128062, 128064, 128064, 128066, 128252, 128255, 128317, 128331, 128334, 128336, 128359, 128378, 128378, 128405, 128406, 128420, 128420, 128507, 128591, 128640, 128709, 128716, 128716, 128720, 128722, 128725, 128728, 128732, 128735, 128747, 128748, 128756, 128764, 128992, 129003, 129008, 129008, 129292, 129338, 129340, 129349, 129351, 129535, 129648, 129660, 129664, 129674, 129678, 129734, 129736, 129736, 129741, 129756, 129759, 129770, 129775, 129784, 131072, 196605, 196608, 262141];

// node_modules/get-east-asian-width/utilities.js
var isInRange = (ranges, codePoint) => {
  let low = 0;
  let high = Math.floor(ranges.length / 2) - 1;
  while (low <= high) {
    const mid = Math.floor((low + high) / 2);
    const i = mid * 2;
    if (codePoint < ranges[i]) {
      high = mid - 1;
    } else if (codePoint > ranges[i + 1]) {
      low = mid + 1;
    } else {
      return true;
    }
  }
  return false;
};

// node_modules/get-east-asian-width/lookup.js
var minimumAmbiguousCodePoint = ambiguousRanges[0];
var maximumAmbiguousCodePoint = ambiguousRanges.at(-1);
var minimumFullWidthCodePoint = fullwidthRanges[0];
var maximumFullWidthCodePoint = fullwidthRanges.at(-1);
var minimumHalfWidthCodePoint = halfwidthRanges[0];
var maximumHalfWidthCodePoint = halfwidthRanges.at(-1);
var minimumNarrowCodePoint = narrowRanges[0];
var maximumNarrowCodePoint = narrowRanges.at(-1);
var minimumWideCodePoint = wideRanges[0];
var maximumWideCodePoint = wideRanges.at(-1);
var commonCjkCodePoint = 19968;
var [wideFastPathStart, wideFastPathEnd] = findWideFastPathRange(wideRanges);
function findWideFastPathRange(ranges) {
  let fastPathStart = ranges[0];
  let fastPathEnd = ranges[1];
  for (let index = 0; index < ranges.length; index += 2) {
    const start = ranges[index];
    const end = ranges[index + 1];
    if (commonCjkCodePoint >= start && commonCjkCodePoint <= end) {
      return [start, end];
    }
    if (end - start > fastPathEnd - fastPathStart) {
      fastPathStart = start;
      fastPathEnd = end;
    }
  }
  return [fastPathStart, fastPathEnd];
}
var isAmbiguous = (codePoint) => {
  if (codePoint < minimumAmbiguousCodePoint || codePoint > maximumAmbiguousCodePoint) {
    return false;
  }
  return isInRange(ambiguousRanges, codePoint);
};
var isFullWidth = (codePoint) => {
  if (codePoint < minimumFullWidthCodePoint || codePoint > maximumFullWidthCodePoint) {
    return false;
  }
  return isInRange(fullwidthRanges, codePoint);
};
var isWide = (codePoint) => {
  if (codePoint >= wideFastPathStart && codePoint <= wideFastPathEnd) {
    return true;
  }
  if (codePoint < minimumWideCodePoint || codePoint > maximumWideCodePoint) {
    return false;
  }
  return isInRange(wideRanges, codePoint);
};

// node_modules/get-east-asian-width/index.js
function validate(codePoint) {
  if (!Number.isSafeInteger(codePoint)) {
    throw new TypeError(`Expected a code point, got \`${typeof codePoint}\`.`);
  }
}
function eastAsianWidth(codePoint, { ambiguousAsWide = false } = {}) {
  validate(codePoint);
  if (isFullWidth(codePoint) || isWide(codePoint) || ambiguousAsWide && isAmbiguous(codePoint)) {
    return 2;
  }
  return 1;
}

// node_modules/emoji-regex/index.mjs
var emoji_regex_default = () => {
  return /[#*0-9]\uFE0F?\u20E3|[\xA9\xAE\u203C\u2049\u2122\u2139\u2194-\u2199\u21A9\u21AA\u231A\u231B\u2328\u23CF\u23ED-\u23EF\u23F1\u23F2\u23F8-\u23FA\u24C2\u25AA\u25AB\u25B6\u25C0\u25FB\u25FC\u25FE\u2600-\u2604\u260E\u2611\u2614\u2615\u2618\u2620\u2622\u2623\u2626\u262A\u262E\u262F\u2638-\u263A\u2640\u2642\u2648-\u2653\u265F\u2660\u2663\u2665\u2666\u2668\u267B\u267E\u267F\u2692\u2694-\u2697\u2699\u269B\u269C\u26A0\u26A7\u26AA\u26B0\u26B1\u26BD\u26BE\u26C4\u26C8\u26CF\u26D1\u26E9\u26F0-\u26F5\u26F7\u26F8\u26FA\u2702\u2708\u2709\u270F\u2712\u2714\u2716\u271D\u2721\u2733\u2734\u2744\u2747\u2757\u2763\u27A1\u2934\u2935\u2B05-\u2B07\u2B1B\u2B1C\u2B55\u3030\u303D\u3297\u3299]\uFE0F?|[\u261D\u270C\u270D](?:\uD83C[\uDFFB-\uDFFF]|\uFE0F)?|[\u270A\u270B](?:\uD83C[\uDFFB-\uDFFF])?|[\u23E9-\u23EC\u23F0\u23F3\u25FD\u2693\u26A1\u26AB\u26C5\u26CE\u26D4\u26EA\u26FD\u2705\u2728\u274C\u274E\u2753-\u2755\u2795-\u2797\u27B0\u27BF\u2B50]|\u26D3\uFE0F?(?:\u200D\uD83D\uDCA5)?|\u26F9(?:\uD83C[\uDFFB-\uDFFF]|\uFE0F)?(?:\u200D[\u2640\u2642]\uFE0F?)?|\u2764\uFE0F?(?:\u200D(?:\uD83D\uDD25|\uD83E\uDE79))?|\uD83C(?:[\uDC04\uDD70\uDD71\uDD7E\uDD7F\uDE02\uDE37\uDF21\uDF24-\uDF2C\uDF36\uDF7D\uDF96\uDF97\uDF99-\uDF9B\uDF9E\uDF9F\uDFCD\uDFCE\uDFD4-\uDFDF\uDFF5\uDFF7]\uFE0F?|[\uDF85\uDFC2\uDFC7](?:\uD83C[\uDFFB-\uDFFF])?|[\uDFC4\uDFCA](?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D[\u2640\u2642]\uFE0F?)?|[\uDFCB\uDFCC](?:\uD83C[\uDFFB-\uDFFF]|\uFE0F)?(?:\u200D[\u2640\u2642]\uFE0F?)?|[\uDCCF\uDD8E\uDD91-\uDD9A\uDE01\uDE1A\uDE2F\uDE32-\uDE36\uDE38-\uDE3A\uDE50\uDE51\uDF00-\uDF20\uDF2D-\uDF35\uDF37-\uDF43\uDF45-\uDF4A\uDF4C-\uDF7C\uDF7E-\uDF84\uDF86-\uDF93\uDFA0-\uDFC1\uDFC5\uDFC6\uDFC8\uDFC9\uDFCF-\uDFD3\uDFE0-\uDFF0\uDFF8-\uDFFF]|\uDDE6\uD83C[\uDDE8-\uDDEC\uDDEE\uDDF1\uDDF2\uDDF4\uDDF6-\uDDFA\uDDFC\uDDFD\uDDFF]|\uDDE7\uD83C[\uDDE6\uDDE7\uDDE9-\uDDEF\uDDF1-\uDDF4\uDDF6-\uDDF9\uDDFB\uDDFC\uDDFE\uDDFF]|\uDDE8\uD83C[\uDDE6\uDDE8\uDDE9\uDDEB-\uDDEE\uDDF0-\uDDF7\uDDFA-\uDDFF]|\uDDE9\uD83C[\uDDEA\uDDEC\uDDEF\uDDF0\uDDF2\uDDF4\uDDFF]|\uDDEA\uD83C[\uDDE6\uDDE8\uDDEA\uDDEC\uDDED\uDDF7-\uDDFA]|\uDDEB\uD83C[\uDDEE-\uDDF0\uDDF2\uDDF4\uDDF7]|\uDDEC\uD83C[\uDDE6\uDDE7\uDDE9-\uDDEE\uDDF1-\uDDF3\uDDF5-\uDDFA\uDDFC\uDDFE]|\uDDED\uD83C[\uDDF0\uDDF2\uDDF3\uDDF7\uDDF9\uDDFA]|\uDDEE\uD83C[\uDDE8-\uDDEA\uDDF1-\uDDF4\uDDF6-\uDDF9]|\uDDEF\uD83C[\uDDEA\uDDF2\uDDF4\uDDF5]|\uDDF0\uD83C[\uDDEA\uDDEC-\uDDEE\uDDF2\uDDF3\uDDF5\uDDF7\uDDFC\uDDFE\uDDFF]|\uDDF1\uD83C[\uDDE6-\uDDE8\uDDEE\uDDF0\uDDF7-\uDDFB\uDDFE]|\uDDF2\uD83C[\uDDE6\uDDE8-\uDDED\uDDF0-\uDDFF]|\uDDF3\uD83C[\uDDE6\uDDE8\uDDEA-\uDDEC\uDDEE\uDDF1\uDDF4\uDDF5\uDDF7\uDDFA\uDDFF]|\uDDF4\uD83C\uDDF2|\uDDF5\uD83C[\uDDE6\uDDEA-\uDDED\uDDF0-\uDDF3\uDDF7-\uDDF9\uDDFC\uDDFE]|\uDDF6\uD83C\uDDE6|\uDDF7\uD83C[\uDDEA\uDDF4\uDDF8\uDDFA\uDDFC]|\uDDF8\uD83C[\uDDE6-\uDDEA\uDDEC-\uDDF4\uDDF7-\uDDF9\uDDFB\uDDFD-\uDDFF]|\uDDF9\uD83C[\uDDE6\uDDE8\uDDE9\uDDEB-\uDDED\uDDEF-\uDDF4\uDDF7\uDDF9\uDDFB\uDDFC\uDDFF]|\uDDFA\uD83C[\uDDE6\uDDEC\uDDF2\uDDF3\uDDF8\uDDFE\uDDFF]|\uDDFB\uD83C[\uDDE6\uDDE8\uDDEA\uDDEC\uDDEE\uDDF3\uDDFA]|\uDDFC\uD83C[\uDDEB\uDDF8]|\uDDFD\uD83C\uDDF0|\uDDFE\uD83C[\uDDEA\uDDF9]|\uDDFF\uD83C[\uDDE6\uDDF2\uDDFC]|\uDF44(?:\u200D\uD83D\uDFEB)?|\uDF4B(?:\u200D\uD83D\uDFE9)?|\uDFC3(?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D(?:[\u2640\u2642]\uFE0F?(?:\u200D\u27A1\uFE0F?)?|\u27A1\uFE0F?))?|\uDFF3\uFE0F?(?:\u200D(?:\u26A7\uFE0F?|\uD83C\uDF08))?|\uDFF4(?:\u200D\u2620\uFE0F?|\uDB40\uDC67\uDB40\uDC62\uDB40(?:\uDC65\uDB40\uDC6E\uDB40\uDC67|\uDC73\uDB40\uDC63\uDB40\uDC74|\uDC77\uDB40\uDC6C\uDB40\uDC73)\uDB40\uDC7F)?)|\uD83D(?:[\uDC3F\uDCFD\uDD49\uDD4A\uDD6F\uDD70\uDD73\uDD76-\uDD79\uDD87\uDD8A-\uDD8D\uDDA5\uDDA8\uDDB1\uDDB2\uDDBC\uDDC2-\uDDC4\uDDD1-\uDDD3\uDDDC-\uDDDE\uDDE1\uDDE3\uDDE8\uDDEF\uDDF3\uDDFA\uDECB\uDECD-\uDECF\uDEE0-\uDEE5\uDEE9\uDEF0\uDEF3]\uFE0F?|[\uDC42\uDC43\uDC46-\uDC50\uDC66\uDC67\uDC6B-\uDC6D\uDC72\uDC74-\uDC76\uDC78\uDC7C\uDC83\uDC85\uDC8F\uDC91\uDCAA\uDD7A\uDD95\uDD96\uDE4C\uDE4F\uDEC0\uDECC](?:\uD83C[\uDFFB-\uDFFF])?|[\uDC6E-\uDC71\uDC73\uDC77\uDC81\uDC82\uDC86\uDC87\uDE45-\uDE47\uDE4B\uDE4D\uDE4E\uDEA3\uDEB4\uDEB5](?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D[\u2640\u2642]\uFE0F?)?|[\uDD74\uDD90](?:\uD83C[\uDFFB-\uDFFF]|\uFE0F)?|[\uDC00-\uDC07\uDC09-\uDC14\uDC16-\uDC25\uDC27-\uDC3A\uDC3C-\uDC3E\uDC40\uDC44\uDC45\uDC51-\uDC65\uDC6A\uDC79-\uDC7B\uDC7D-\uDC80\uDC84\uDC88-\uDC8E\uDC90\uDC92-\uDCA9\uDCAB-\uDCFC\uDCFF-\uDD3D\uDD4B-\uDD4E\uDD50-\uDD67\uDDA4\uDDFB-\uDE2D\uDE2F-\uDE34\uDE37-\uDE41\uDE43\uDE44\uDE48-\uDE4A\uDE80-\uDEA2\uDEA4-\uDEB3\uDEB7-\uDEBF\uDEC1-\uDEC5\uDED0-\uDED2\uDED5-\uDED8\uDEDC-\uDEDF\uDEEB\uDEEC\uDEF4-\uDEFC\uDFE0-\uDFEB\uDFF0]|\uDC08(?:\u200D\u2B1B)?|\uDC15(?:\u200D\uD83E\uDDBA)?|\uDC26(?:\u200D(?:\u2B1B|\uD83D\uDD25))?|\uDC3B(?:\u200D\u2744\uFE0F?)?|\uDC41\uFE0F?(?:\u200D\uD83D\uDDE8\uFE0F?)?|\uDC68(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDC68\uDC69]\u200D\uD83D(?:\uDC66(?:\u200D\uD83D\uDC66)?|\uDC67(?:\u200D\uD83D[\uDC66\uDC67])?)|[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC66(?:\u200D\uD83D\uDC66)?|\uDC67(?:\u200D\uD83D[\uDC66\uDC67])?)|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]))|\uD83C(?:\uDFFB(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC68\uD83C[\uDFFC-\uDFFF])|\uD83E(?:[\uDD1D\uDEEF]\u200D\uD83D\uDC68\uD83C[\uDFFC-\uDFFF]|[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3])))?|\uDFFC(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC68\uD83C[\uDFFB\uDFFD-\uDFFF])|\uD83E(?:[\uDD1D\uDEEF]\u200D\uD83D\uDC68\uD83C[\uDFFB\uDFFD-\uDFFF]|[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3])))?|\uDFFD(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC68\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])|\uD83E(?:[\uDD1D\uDEEF]\u200D\uD83D\uDC68\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF]|[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3])))?|\uDFFE(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC68\uD83C[\uDFFB-\uDFFD\uDFFF])|\uD83E(?:[\uDD1D\uDEEF]\u200D\uD83D\uDC68\uD83C[\uDFFB-\uDFFD\uDFFF]|[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3])))?|\uDFFF(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?\uDC68\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC68\uD83C[\uDFFB-\uDFFE])|\uD83E(?:[\uDD1D\uDEEF]\u200D\uD83D\uDC68\uD83C[\uDFFB-\uDFFE]|[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3])))?))?|\uDC69(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:\uDC8B\u200D\uD83D)?[\uDC68\uDC69]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC66(?:\u200D\uD83D\uDC66)?|\uDC67(?:\u200D\uD83D[\uDC66\uDC67])?|\uDC69\u200D\uD83D(?:\uDC66(?:\u200D\uD83D\uDC66)?|\uDC67(?:\u200D\uD83D[\uDC66\uDC67])?))|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]))|\uD83C(?:\uDFFB(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:[\uDC68\uDC69]|\uDC8B\u200D\uD83D[\uDC68\uDC69])\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC69\uD83C[\uDFFC-\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]|\uDD1D\u200D\uD83D[\uDC68\uDC69]\uD83C[\uDFFC-\uDFFF]|\uDEEF\u200D\uD83D\uDC69\uD83C[\uDFFC-\uDFFF])))?|\uDFFC(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:[\uDC68\uDC69]|\uDC8B\u200D\uD83D[\uDC68\uDC69])\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC69\uD83C[\uDFFB\uDFFD-\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]|\uDD1D\u200D\uD83D[\uDC68\uDC69]\uD83C[\uDFFB\uDFFD-\uDFFF]|\uDEEF\u200D\uD83D\uDC69\uD83C[\uDFFB\uDFFD-\uDFFF])))?|\uDFFD(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:[\uDC68\uDC69]|\uDC8B\u200D\uD83D[\uDC68\uDC69])\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC69\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]|\uDD1D\u200D\uD83D[\uDC68\uDC69]\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF]|\uDEEF\u200D\uD83D\uDC69\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])))?|\uDFFE(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:[\uDC68\uDC69]|\uDC8B\u200D\uD83D[\uDC68\uDC69])\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC69\uD83C[\uDFFB-\uDFFD\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]|\uDD1D\u200D\uD83D[\uDC68\uDC69]\uD83C[\uDFFB-\uDFFD\uDFFF]|\uDEEF\u200D\uD83D\uDC69\uD83C[\uDFFB-\uDFFD\uDFFF])))?|\uDFFF(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D\uD83D(?:[\uDC68\uDC69]|\uDC8B\u200D\uD83D[\uDC68\uDC69])\uD83C[\uDFFB-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83D\uDC69\uD83C[\uDFFB-\uDFFE])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3]|\uDD1D\u200D\uD83D[\uDC68\uDC69]\uD83C[\uDFFB-\uDFFE]|\uDEEF\u200D\uD83D\uDC69\uD83C[\uDFFB-\uDFFE])))?))?|\uDD75(?:\uD83C[\uDFFB-\uDFFF]|\uFE0F)?(?:\u200D[\u2640\u2642]\uFE0F?)?|\uDE2E(?:\u200D\uD83D\uDCA8)?|\uDE35(?:\u200D\uD83D\uDCAB)?|\uDE36(?:\u200D\uD83C\uDF2B\uFE0F?)?|\uDE42(?:\u200D[\u2194\u2195]\uFE0F?)?|\uDEB6(?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D(?:[\u2640\u2642]\uFE0F?(?:\u200D\u27A1\uFE0F?)?|\u27A1\uFE0F?))?)|\uD83E(?:[\uDD0C\uDD0F\uDD18-\uDD1F\uDD30-\uDD34\uDD36\uDD77\uDDB5\uDDB6\uDDBB\uDDD2\uDDD3\uDDD5\uDEC3-\uDEC5\uDEF0\uDEF2-\uDEF8](?:\uD83C[\uDFFB-\uDFFF])?|[\uDD26\uDD35\uDD37-\uDD39\uDD3C-\uDD3E\uDDB8\uDDB9\uDDCD\uDDCF\uDDD4\uDDD6-\uDDDD](?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D[\u2640\u2642]\uFE0F?)?|[\uDDDE\uDDDF](?:\u200D[\u2640\u2642]\uFE0F?)?|[\uDD0D\uDD0E\uDD10-\uDD17\uDD20-\uDD25\uDD27-\uDD2F\uDD3A\uDD3F-\uDD45\uDD47-\uDD76\uDD78-\uDDB4\uDDB7\uDDBA\uDDBC-\uDDCC\uDDD0\uDDE0-\uDDFF\uDE70-\uDE7C\uDE80-\uDE8A\uDE8E-\uDEC2\uDEC6\uDEC8\uDECD-\uDEDC\uDEDF-\uDEEA\uDEEF]|\uDDCE(?:\uD83C[\uDFFB-\uDFFF])?(?:\u200D(?:[\u2640\u2642]\uFE0F?(?:\u200D\u27A1\uFE0F?)?|\u27A1\uFE0F?))?|\uDDD1(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1|\uDDD1\u200D\uD83E\uDDD2(?:\u200D\uD83E\uDDD2)?|\uDDD2(?:\u200D\uD83E\uDDD2)?))|\uD83C(?:\uDFFB(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D(?:\uD83D\uDC8B\u200D)?\uD83E\uDDD1\uD83C[\uDFFC-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83E\uDDD1\uD83C[\uDFFC-\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFF]|\uDEEF\u200D\uD83E\uDDD1\uD83C[\uDFFC-\uDFFF])))?|\uDFFC(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D(?:\uD83D\uDC8B\u200D)?\uD83E\uDDD1\uD83C[\uDFFB\uDFFD-\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83E\uDDD1\uD83C[\uDFFB\uDFFD-\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFF]|\uDEEF\u200D\uD83E\uDDD1\uD83C[\uDFFB\uDFFD-\uDFFF])))?|\uDFFD(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D(?:\uD83D\uDC8B\u200D)?\uD83E\uDDD1\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83E\uDDD1\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFF]|\uDEEF\u200D\uD83E\uDDD1\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])))?|\uDFFE(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D(?:\uD83D\uDC8B\u200D)?\uD83E\uDDD1\uD83C[\uDFFB-\uDFFD\uDFFF]|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFD\uDFFF])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFF]|\uDEEF\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFD\uDFFF])))?|\uDFFF(?:\u200D(?:[\u2695\u2696\u2708]\uFE0F?|\u2764\uFE0F?\u200D(?:\uD83D\uDC8B\u200D)?\uD83E\uDDD1\uD83C[\uDFFB-\uDFFE]|\uD83C[\uDF3E\uDF73\uDF7C\uDF84\uDF93\uDFA4\uDFA8\uDFEB\uDFED]|\uD83D(?:[\uDCBB\uDCBC\uDD27\uDD2C\uDE80\uDE92]|\uDC30\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFE])|\uD83E(?:[\uDDAF\uDDBC\uDDBD](?:\u200D\u27A1\uFE0F?)?|[\uDDB0-\uDDB3\uDE70]|\uDD1D\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFF]|\uDEEF\u200D\uD83E\uDDD1\uD83C[\uDFFB-\uDFFE])))?))?|\uDEF1(?:\uD83C(?:\uDFFB(?:\u200D\uD83E\uDEF2\uD83C[\uDFFC-\uDFFF])?|\uDFFC(?:\u200D\uD83E\uDEF2\uD83C[\uDFFB\uDFFD-\uDFFF])?|\uDFFD(?:\u200D\uD83E\uDEF2\uD83C[\uDFFB\uDFFC\uDFFE\uDFFF])?|\uDFFE(?:\u200D\uD83E\uDEF2\uD83C[\uDFFB-\uDFFD\uDFFF])?|\uDFFF(?:\u200D\uD83E\uDEF2\uD83C[\uDFFB-\uDFFE])?))?)/g;
};

// node_modules/string-width/index.js
var segmenter = new Intl.Segmenter();
var defaultIgnorableCodePointRegex = new RegExp("^\\p{Default_Ignorable_Code_Point}$", "u");
function stringWidth(string, options = {}) {
  if (typeof string !== "string" || string.length === 0) {
    return 0;
  }
  const {
    ambiguousIsNarrow = true,
    countAnsiEscapeCodes = false
  } = options;
  if (!countAnsiEscapeCodes) {
    string = stripAnsi(string);
  }
  if (string.length === 0) {
    return 0;
  }
  let width = 0;
  const eastAsianWidthOptions = { ambiguousAsWide: !ambiguousIsNarrow };
  for (const { segment: character } of segmenter.segment(string)) {
    const codePoint = character.codePointAt(0);
    if (codePoint <= 31 || codePoint >= 127 && codePoint <= 159) {
      continue;
    }
    if (codePoint >= 8203 && codePoint <= 8207 || codePoint === 65279) {
      continue;
    }
    if (codePoint >= 768 && codePoint <= 879 || codePoint >= 6832 && codePoint <= 6911 || codePoint >= 7616 && codePoint <= 7679 || codePoint >= 8400 && codePoint <= 8447 || codePoint >= 65056 && codePoint <= 65071) {
      continue;
    }
    if (codePoint >= 55296 && codePoint <= 57343) {
      continue;
    }
    if (codePoint >= 65024 && codePoint <= 65039) {
      continue;
    }
    if (defaultIgnorableCodePointRegex.test(character)) {
      continue;
    }
    if (emoji_regex_default().test(character)) {
      width += 2;
      continue;
    }
    width += eastAsianWidth(codePoint, eastAsianWidthOptions);
  }
  return width;
}

// node_modules/widest-line/index.js
function widestLine(string) {
  let lineWidth = 0;
  for (const line of string.split("\n")) {
    lineWidth = Math.max(lineWidth, stringWidth(line));
  }
  return lineWidth;
}

// node_modules/ink/build/measure-text.js
var cache = {};
var measureText = (text) => {
  if (text.length === 0) {
    return {
      width: 0,
      height: 0
    };
  }
  const cachedDimensions = cache[text];
  if (cachedDimensions) {
    return cachedDimensions;
  }
  const width = widestLine(text);
  const height = text.split("\n").length;
  cache[text] = { width, height };
  return { width, height };
};
var measure_text_default = measureText;

// node_modules/ansi-styles/index.js
var ANSI_BACKGROUND_OFFSET = 10;
var wrapAnsi16 = (offset = 0) => (code) => `\x1B[${code + offset}m`;
var wrapAnsi256 = (offset = 0) => (code) => `\x1B[${38 + offset};5;${code}m`;
var wrapAnsi16m = (offset = 0) => (red, green, blue) => `\x1B[${38 + offset};2;${red};${green};${blue}m`;
var styles = {
  modifier: {
    reset: [0, 0],
    // 21 isn't widely supported and 22 does the same thing
    bold: [1, 22],
    dim: [2, 22],
    italic: [3, 23],
    underline: [4, 24],
    overline: [53, 55],
    inverse: [7, 27],
    hidden: [8, 28],
    strikethrough: [9, 29]
  },
  color: {
    black: [30, 39],
    red: [31, 39],
    green: [32, 39],
    yellow: [33, 39],
    blue: [34, 39],
    magenta: [35, 39],
    cyan: [36, 39],
    white: [37, 39],
    // Bright color
    blackBright: [90, 39],
    gray: [90, 39],
    // Alias of `blackBright`
    grey: [90, 39],
    // Alias of `blackBright`
    redBright: [91, 39],
    greenBright: [92, 39],
    yellowBright: [93, 39],
    blueBright: [94, 39],
    magentaBright: [95, 39],
    cyanBright: [96, 39],
    whiteBright: [97, 39]
  },
  bgColor: {
    bgBlack: [40, 49],
    bgRed: [41, 49],
    bgGreen: [42, 49],
    bgYellow: [43, 49],
    bgBlue: [44, 49],
    bgMagenta: [45, 49],
    bgCyan: [46, 49],
    bgWhite: [47, 49],
    // Bright color
    bgBlackBright: [100, 49],
    bgGray: [100, 49],
    // Alias of `bgBlackBright`
    bgGrey: [100, 49],
    // Alias of `bgBlackBright`
    bgRedBright: [101, 49],
    bgGreenBright: [102, 49],
    bgYellowBright: [103, 49],
    bgBlueBright: [104, 49],
    bgMagentaBright: [105, 49],
    bgCyanBright: [106, 49],
    bgWhiteBright: [107, 49]
  }
};
var modifierNames = Object.keys(styles.modifier);
var foregroundColorNames = Object.keys(styles.color);
var backgroundColorNames = Object.keys(styles.bgColor);
var colorNames = [...foregroundColorNames, ...backgroundColorNames];
function assembleStyles() {
  const codes = /* @__PURE__ */ new Map();
  for (const [groupName, group] of Object.entries(styles)) {
    for (const [styleName, style] of Object.entries(group)) {
      styles[styleName] = {
        open: `\x1B[${style[0]}m`,
        close: `\x1B[${style[1]}m`
      };
      group[styleName] = styles[styleName];
      codes.set(style[0], style[1]);
    }
    Object.defineProperty(styles, groupName, {
      value: group,
      enumerable: false
    });
  }
  Object.defineProperty(styles, "codes", {
    value: codes,
    enumerable: false
  });
  styles.color.close = "\x1B[39m";
  styles.bgColor.close = "\x1B[49m";
  styles.color.ansi = wrapAnsi16();
  styles.color.ansi256 = wrapAnsi256();
  styles.color.ansi16m = wrapAnsi16m();
  styles.bgColor.ansi = wrapAnsi16(ANSI_BACKGROUND_OFFSET);
  styles.bgColor.ansi256 = wrapAnsi256(ANSI_BACKGROUND_OFFSET);
  styles.bgColor.ansi16m = wrapAnsi16m(ANSI_BACKGROUND_OFFSET);
  Object.defineProperties(styles, {
    rgbToAnsi256: {
      value(red, green, blue) {
        if (red === green && green === blue) {
          if (red < 8) {
            return 16;
          }
          if (red > 248) {
            return 231;
          }
          return Math.round((red - 8) / 247 * 24) + 232;
        }
        return 16 + 36 * Math.round(red / 255 * 5) + 6 * Math.round(green / 255 * 5) + Math.round(blue / 255 * 5);
      },
      enumerable: false
    },
    hexToRgb: {
      value(hex) {
        const matches = /[a-f\d]{6}|[a-f\d]{3}/i.exec(hex.toString(16));
        if (!matches) {
          return [0, 0, 0];
        }
        let [colorString] = matches;
        if (colorString.length === 3) {
          colorString = [...colorString].map((character) => character + character).join("");
        }
        const integer = Number.parseInt(colorString, 16);
        return [
          /* eslint-disable no-bitwise */
          integer >> 16 & 255,
          integer >> 8 & 255,
          integer & 255
          /* eslint-enable no-bitwise */
        ];
      },
      enumerable: false
    },
    hexToAnsi256: {
      value: (hex) => styles.rgbToAnsi256(...styles.hexToRgb(hex)),
      enumerable: false
    },
    ansi256ToAnsi: {
      value(code) {
        if (code < 8) {
          return 30 + code;
        }
        if (code < 16) {
          return 90 + (code - 8);
        }
        let red;
        let green;
        let blue;
        if (code >= 232) {
          red = ((code - 232) * 10 + 8) / 255;
          green = red;
          blue = red;
        } else {
          code -= 16;
          const remainder = code % 36;
          red = Math.floor(code / 36) / 5;
          green = Math.floor(remainder / 6) / 5;
          blue = remainder % 6 / 5;
        }
        const value = Math.max(red, green, blue) * 2;
        if (value === 0) {
          return 30;
        }
        let result = 30 + (Math.round(blue) << 2 | Math.round(green) << 1 | Math.round(red));
        if (value === 2) {
          result += 60;
        }
        return result;
      },
      enumerable: false
    },
    rgbToAnsi: {
      value: (red, green, blue) => styles.ansi256ToAnsi(styles.rgbToAnsi256(red, green, blue)),
      enumerable: false
    },
    hexToAnsi: {
      value: (hex) => styles.ansi256ToAnsi(styles.hexToAnsi256(hex)),
      enumerable: false
    }
  });
  return styles;
}
var ansiStyles = assembleStyles();
var ansi_styles_default = ansiStyles;

// node_modules/wrap-ansi/index.js
var ESCAPES = /* @__PURE__ */ new Set([
  "\x1B",
  "\x9B"
]);
var END_CODE = 39;
var ANSI_ESCAPE_BELL = "\x07";
var ANSI_CSI = "[";
var ANSI_OSC = "]";
var ANSI_SGR_TERMINATOR = "m";
var ANSI_ESCAPE_LINK = `${ANSI_OSC}8;;`;
var wrapAnsiCode = (code) => `${ESCAPES.values().next().value}${ANSI_CSI}${code}${ANSI_SGR_TERMINATOR}`;
var wrapAnsiHyperlink = (url) => `${ESCAPES.values().next().value}${ANSI_ESCAPE_LINK}${url}${ANSI_ESCAPE_BELL}`;
var wordLengths = (string) => string.split(" ").map((character) => stringWidth(character));
var wrapWord = (rows, word, columns) => {
  const characters = [...word];
  let isInsideEscape = false;
  let isInsideLinkEscape = false;
  let visible = stringWidth(stripAnsi(rows.at(-1)));
  for (const [index, character] of characters.entries()) {
    const characterLength = stringWidth(character);
    if (visible + characterLength <= columns) {
      rows[rows.length - 1] += character;
    } else {
      rows.push(character);
      visible = 0;
    }
    if (ESCAPES.has(character)) {
      isInsideEscape = true;
      const ansiEscapeLinkCandidate = characters.slice(index + 1, index + 1 + ANSI_ESCAPE_LINK.length).join("");
      isInsideLinkEscape = ansiEscapeLinkCandidate === ANSI_ESCAPE_LINK;
    }
    if (isInsideEscape) {
      if (isInsideLinkEscape) {
        if (character === ANSI_ESCAPE_BELL) {
          isInsideEscape = false;
          isInsideLinkEscape = false;
        }
      } else if (character === ANSI_SGR_TERMINATOR) {
        isInsideEscape = false;
      }
      continue;
    }
    visible += characterLength;
    if (visible === columns && index < characters.length - 1) {
      rows.push("");
      visible = 0;
    }
  }
  if (!visible && rows.at(-1).length > 0 && rows.length > 1) {
    rows[rows.length - 2] += rows.pop();
  }
};
var stringVisibleTrimSpacesRight = (string) => {
  const words = string.split(" ");
  let last = words.length;
  while (last > 0) {
    if (stringWidth(words[last - 1]) > 0) {
      break;
    }
    last--;
  }
  if (last === words.length) {
    return string;
  }
  return words.slice(0, last).join(" ") + words.slice(last).join("");
};
var exec = (string, columns, options = {}) => {
  if (options.trim !== false && string.trim() === "") {
    return "";
  }
  let returnValue = "";
  let escapeCode;
  let escapeUrl;
  const lengths = wordLengths(string);
  let rows = [""];
  for (const [index, word] of string.split(" ").entries()) {
    if (options.trim !== false) {
      rows[rows.length - 1] = rows.at(-1).trimStart();
    }
    let rowLength = stringWidth(rows.at(-1));
    if (index !== 0) {
      if (rowLength >= columns && (options.wordWrap === false || options.trim === false)) {
        rows.push("");
        rowLength = 0;
      }
      if (rowLength > 0 || options.trim === false) {
        rows[rows.length - 1] += " ";
        rowLength++;
      }
    }
    if (options.hard && lengths[index] > columns) {
      const remainingColumns = columns - rowLength;
      const breaksStartingThisLine = 1 + Math.floor((lengths[index] - remainingColumns - 1) / columns);
      const breaksStartingNextLine = Math.floor((lengths[index] - 1) / columns);
      if (breaksStartingNextLine < breaksStartingThisLine) {
        rows.push("");
      }
      wrapWord(rows, word, columns);
      continue;
    }
    if (rowLength + lengths[index] > columns && rowLength > 0 && lengths[index] > 0) {
      if (options.wordWrap === false && rowLength < columns) {
        wrapWord(rows, word, columns);
        continue;
      }
      rows.push("");
    }
    if (rowLength + lengths[index] > columns && options.wordWrap === false) {
      wrapWord(rows, word, columns);
      continue;
    }
    rows[rows.length - 1] += word;
  }
  if (options.trim !== false) {
    rows = rows.map((row) => stringVisibleTrimSpacesRight(row));
  }
  const preString = rows.join("\n");
  const pre = [...preString];
  let preStringIndex = 0;
  for (const [index, character] of pre.entries()) {
    returnValue += character;
    if (ESCAPES.has(character)) {
      const { groups } = new RegExp(`(?:\\${ANSI_CSI}(?<code>\\d+)m|\\${ANSI_ESCAPE_LINK}(?<uri>.*)${ANSI_ESCAPE_BELL})`).exec(preString.slice(preStringIndex)) || { groups: {} };
      if (groups.code !== void 0) {
        const code2 = Number.parseFloat(groups.code);
        escapeCode = code2 === END_CODE ? void 0 : code2;
      } else if (groups.uri !== void 0) {
        escapeUrl = groups.uri.length === 0 ? void 0 : groups.uri;
      }
    }
    const code = ansi_styles_default.codes.get(Number(escapeCode));
    if (pre[index + 1] === "\n") {
      if (escapeUrl) {
        returnValue += wrapAnsiHyperlink("");
      }
      if (escapeCode && code) {
        returnValue += wrapAnsiCode(code);
      }
    } else if (character === "\n") {
      if (escapeCode && code) {
        returnValue += wrapAnsiCode(escapeCode);
      }
      if (escapeUrl) {
        returnValue += wrapAnsiHyperlink(escapeUrl);
      }
    }
    preStringIndex += character.length;
  }
  return returnValue;
};
function wrapAnsi(string, columns, options) {
  return String(string).normalize().replaceAll("\r\n", "\n").split("\n").map((line) => exec(line, columns, options)).join("\n");
}

// node_modules/is-fullwidth-code-point/index.js
function isFullwidthCodePoint(codePoint) {
  if (!Number.isInteger(codePoint)) {
    return false;
  }
  return codePoint >= 4352 && (codePoint <= 4447 || // Hangul Jamo
  codePoint === 9001 || // LEFT-POINTING ANGLE BRACKET
  codePoint === 9002 || // RIGHT-POINTING ANGLE BRACKET
  // CJK Radicals Supplement .. Enclosed CJK Letters and Months
  11904 <= codePoint && codePoint <= 12871 && codePoint !== 12351 || // Enclosed CJK Letters and Months .. CJK Unified Ideographs Extension A
  12880 <= codePoint && codePoint <= 19903 || // CJK Unified Ideographs .. Yi Radicals
  19968 <= codePoint && codePoint <= 42182 || // Hangul Jamo Extended-A
  43360 <= codePoint && codePoint <= 43388 || // Hangul Syllables
  44032 <= codePoint && codePoint <= 55203 || // CJK Compatibility Ideographs
  63744 <= codePoint && codePoint <= 64255 || // Vertical Forms
  65040 <= codePoint && codePoint <= 65049 || // CJK Compatibility Forms .. Small Form Variants
  65072 <= codePoint && codePoint <= 65131 || // Halfwidth and Fullwidth Forms
  65281 <= codePoint && codePoint <= 65376 || 65504 <= codePoint && codePoint <= 65510 || // Kana Supplement
  110592 <= codePoint && codePoint <= 110593 || // Enclosed Ideographic Supplement
  127488 <= codePoint && codePoint <= 127569 || // CJK Unified Ideographs Extension B .. Tertiary Ideographic Plane
  131072 <= codePoint && codePoint <= 262141);
}

// node_modules/cli-truncate/node_modules/slice-ansi/index.js
var astralRegex = /^[\uD800-\uDBFF][\uDC00-\uDFFF]$/;
var ESCAPES2 = [
  "\x1B",
  "\x9B"
];
var wrapAnsi2 = (code) => `${ESCAPES2[0]}[${code}m`;
var checkAnsi = (ansiCodes, isEscapes, endAnsiCode) => {
  let output = [];
  ansiCodes = [...ansiCodes];
  for (let ansiCode of ansiCodes) {
    const ansiCodeOrigin = ansiCode;
    if (ansiCode.includes(";")) {
      ansiCode = ansiCode.split(";")[0][0] + "0";
    }
    const item = ansi_styles_default.codes.get(Number.parseInt(ansiCode, 10));
    if (item) {
      const indexEscape = ansiCodes.indexOf(item.toString());
      if (indexEscape === -1) {
        output.push(wrapAnsi2(isEscapes ? item : ansiCodeOrigin));
      } else {
        ansiCodes.splice(indexEscape, 1);
      }
    } else if (isEscapes) {
      output.push(wrapAnsi2(0));
      break;
    } else {
      output.push(wrapAnsi2(ansiCodeOrigin));
    }
  }
  if (isEscapes) {
    output = output.filter((element, index) => output.indexOf(element) === index);
    if (endAnsiCode !== void 0) {
      const fistEscapeCode = wrapAnsi2(ansi_styles_default.codes.get(Number.parseInt(endAnsiCode, 10)));
      output = output.reduce((current, next) => next === fistEscapeCode ? [next, ...current] : [...current, next], []);
    }
  }
  return output.join("");
};
function sliceAnsi(string, begin, end) {
  const characters = [...string];
  const ansiCodes = [];
  let stringEnd = typeof end === "number" ? end : characters.length;
  let isInsideEscape = false;
  let ansiCode;
  let visible = 0;
  let output = "";
  for (const [index, character] of characters.entries()) {
    let leftEscape = false;
    if (ESCAPES2.includes(character)) {
      const code = /\d[^m]*/.exec(string.slice(index, index + 18));
      ansiCode = code && code.length > 0 ? code[0] : void 0;
      if (visible < stringEnd) {
        isInsideEscape = true;
        if (ansiCode !== void 0) {
          ansiCodes.push(ansiCode);
        }
      }
    } else if (isInsideEscape && character === "m") {
      isInsideEscape = false;
      leftEscape = true;
    }
    if (!isInsideEscape && !leftEscape) {
      visible++;
    }
    if (!astralRegex.test(character) && isFullwidthCodePoint(character.codePointAt())) {
      visible++;
      if (typeof end !== "number") {
        stringEnd++;
      }
    }
    if (visible > begin && visible <= stringEnd) {
      output += character;
    } else if (visible === begin && !isInsideEscape && ansiCode !== void 0) {
      output = checkAnsi(ansiCodes);
    } else if (visible >= stringEnd) {
      output += checkAnsi(ansiCodes, true, ansiCode);
      break;
    }
  }
  return output;
}

// node_modules/cli-truncate/index.js
function getIndexOfNearestSpace(string, wantedIndex, shouldSearchRight) {
  if (string.charAt(wantedIndex) === " ") {
    return wantedIndex;
  }
  const direction = shouldSearchRight ? 1 : -1;
  for (let index = 0; index <= 3; index++) {
    const finalIndex = wantedIndex + index * direction;
    if (string.charAt(finalIndex) === " ") {
      return finalIndex;
    }
  }
  return wantedIndex;
}
function cliTruncate(text, columns, options = {}) {
  const {
    position = "end",
    space = false,
    preferTruncationOnSpace = false
  } = options;
  let { truncationCharacter = "\u2026" } = options;
  if (typeof text !== "string") {
    throw new TypeError(`Expected \`input\` to be a string, got ${typeof text}`);
  }
  if (typeof columns !== "number") {
    throw new TypeError(`Expected \`columns\` to be a number, got ${typeof columns}`);
  }
  if (columns < 1) {
    return "";
  }
  if (columns === 1) {
    return truncationCharacter;
  }
  const length = stringWidth(text);
  if (length <= columns) {
    return text;
  }
  if (position === "start") {
    if (preferTruncationOnSpace) {
      const nearestSpace = getIndexOfNearestSpace(text, length - columns + 1, true);
      return truncationCharacter + sliceAnsi(text, nearestSpace, length).trim();
    }
    if (space === true) {
      truncationCharacter += " ";
    }
    return truncationCharacter + sliceAnsi(text, length - columns + stringWidth(truncationCharacter), length);
  }
  if (position === "middle") {
    if (space === true) {
      truncationCharacter = ` ${truncationCharacter} `;
    }
    const half = Math.floor(columns / 2);
    if (preferTruncationOnSpace) {
      const spaceNearFirstBreakPoint = getIndexOfNearestSpace(text, half);
      const spaceNearSecondBreakPoint = getIndexOfNearestSpace(text, length - (columns - half) + 1, true);
      return sliceAnsi(text, 0, spaceNearFirstBreakPoint) + truncationCharacter + sliceAnsi(text, spaceNearSecondBreakPoint, length).trim();
    }
    return sliceAnsi(text, 0, half) + truncationCharacter + sliceAnsi(text, length - (columns - half) + stringWidth(truncationCharacter), length);
  }
  if (position === "end") {
    if (preferTruncationOnSpace) {
      const nearestSpace = getIndexOfNearestSpace(text, columns - 1);
      return sliceAnsi(text, 0, nearestSpace) + truncationCharacter;
    }
    if (space === true) {
      truncationCharacter = ` ${truncationCharacter}`;
    }
    return sliceAnsi(text, 0, columns - stringWidth(truncationCharacter)) + truncationCharacter;
  }
  throw new Error(`Expected \`options.position\` to be either \`start\`, \`middle\` or \`end\`, got ${position}`);
}

// node_modules/ink/build/wrap-text.js
var cache2 = {};
var wrapText = (text, maxWidth, wrapType) => {
  const cacheKey = text + String(maxWidth) + String(wrapType);
  const cachedText = cache2[cacheKey];
  if (cachedText) {
    return cachedText;
  }
  let wrappedText = text;
  if (wrapType === "wrap") {
    wrappedText = wrapAnsi(text, maxWidth, {
      trim: false,
      hard: true
    });
  }
  if (wrapType.startsWith("truncate")) {
    let position = "end";
    if (wrapType === "truncate-middle") {
      position = "middle";
    }
    if (wrapType === "truncate-start") {
      position = "start";
    }
    wrappedText = cliTruncate(text, maxWidth, { position });
  }
  cache2[cacheKey] = wrappedText;
  return wrappedText;
};
var wrap_text_default = wrapText;

// node_modules/ink/build/squash-text-nodes.js
var squashTextNodes = (node) => {
  let text = "";
  for (let index = 0; index < node.childNodes.length; index++) {
    const childNode = node.childNodes[index];
    if (childNode === void 0) {
      continue;
    }
    let nodeText = "";
    if (childNode.nodeName === "#text") {
      nodeText = childNode.nodeValue;
    } else {
      if (childNode.nodeName === "ink-text" || childNode.nodeName === "ink-virtual-text") {
        nodeText = squashTextNodes(childNode);
      }
      if (nodeText.length > 0 && typeof childNode.internal_transform === "function") {
        nodeText = childNode.internal_transform(nodeText, index);
      }
    }
    text += nodeText;
  }
  return text;
};
var squash_text_nodes_default = squashTextNodes;

// node_modules/ink/build/dom.js
var createNode = (nodeName) => {
  const node = {
    nodeName,
    style: {},
    attributes: {},
    childNodes: [],
    parentNode: void 0,
    yogaNode: nodeName === "ink-virtual-text" ? void 0 : src_default.Node.create()
  };
  if (nodeName === "ink-text") {
    node.yogaNode?.setMeasureFunc(measureTextNode.bind(null, node));
  }
  return node;
};
var appendChildNode = (node, childNode) => {
  if (childNode.parentNode) {
    removeChildNode(childNode.parentNode, childNode);
  }
  childNode.parentNode = node;
  node.childNodes.push(childNode);
  if (childNode.yogaNode) {
    node.yogaNode?.insertChild(childNode.yogaNode, node.yogaNode.getChildCount());
  }
  if (node.nodeName === "ink-text" || node.nodeName === "ink-virtual-text") {
    markNodeAsDirty(node);
  }
};
var insertBeforeNode = (node, newChildNode, beforeChildNode) => {
  if (newChildNode.parentNode) {
    removeChildNode(newChildNode.parentNode, newChildNode);
  }
  newChildNode.parentNode = node;
  const index = node.childNodes.indexOf(beforeChildNode);
  if (index >= 0) {
    node.childNodes.splice(index, 0, newChildNode);
    if (newChildNode.yogaNode) {
      node.yogaNode?.insertChild(newChildNode.yogaNode, index);
    }
    return;
  }
  node.childNodes.push(newChildNode);
  if (newChildNode.yogaNode) {
    node.yogaNode?.insertChild(newChildNode.yogaNode, node.yogaNode.getChildCount());
  }
  if (node.nodeName === "ink-text" || node.nodeName === "ink-virtual-text") {
    markNodeAsDirty(node);
  }
};
var removeChildNode = (node, removeNode) => {
  if (removeNode.yogaNode) {
    removeNode.parentNode?.yogaNode?.removeChild(removeNode.yogaNode);
  }
  removeNode.parentNode = void 0;
  const index = node.childNodes.indexOf(removeNode);
  if (index >= 0) {
    node.childNodes.splice(index, 1);
  }
  if (node.nodeName === "ink-text" || node.nodeName === "ink-virtual-text") {
    markNodeAsDirty(node);
  }
};
var setAttribute = (node, key, value) => {
  node.attributes[key] = value;
};
var setStyle = (node, style) => {
  node.style = style;
};
var createTextNode = (text) => {
  const node = {
    nodeName: "#text",
    nodeValue: text,
    yogaNode: void 0,
    parentNode: void 0,
    style: {}
  };
  setTextNodeValue(node, text);
  return node;
};
var measureTextNode = function(node, width) {
  const text = node.nodeName === "#text" ? node.nodeValue : squash_text_nodes_default(node);
  const dimensions = measure_text_default(text);
  if (dimensions.width <= width) {
    return dimensions;
  }
  if (dimensions.width >= 1 && width > 0 && width < 1) {
    return dimensions;
  }
  const textWrap = node.style?.textWrap ?? "wrap";
  const wrappedText = wrap_text_default(text, width, textWrap);
  return measure_text_default(wrappedText);
};
var findClosestYogaNode = (node) => {
  if (!node?.parentNode) {
    return void 0;
  }
  return node.yogaNode ?? findClosestYogaNode(node.parentNode);
};
var markNodeAsDirty = (node) => {
  const yogaNode = findClosestYogaNode(node);
  yogaNode?.markDirty();
};
var setTextNodeValue = (node, text) => {
  if (typeof text !== "string") {
    text = String(text);
  }
  node.nodeValue = text;
  markNodeAsDirty(node);
};

// node_modules/ink/build/styles.js
var applyPositionStyles = (node, style) => {
  if ("position" in style) {
    node.setPositionType(style.position === "absolute" ? src_default.POSITION_TYPE_ABSOLUTE : src_default.POSITION_TYPE_RELATIVE);
  }
};
var applyMarginStyles = (node, style) => {
  if ("margin" in style) {
    node.setMargin(src_default.EDGE_ALL, style.margin ?? 0);
  }
  if ("marginX" in style) {
    node.setMargin(src_default.EDGE_HORIZONTAL, style.marginX ?? 0);
  }
  if ("marginY" in style) {
    node.setMargin(src_default.EDGE_VERTICAL, style.marginY ?? 0);
  }
  if ("marginLeft" in style) {
    node.setMargin(src_default.EDGE_START, style.marginLeft || 0);
  }
  if ("marginRight" in style) {
    node.setMargin(src_default.EDGE_END, style.marginRight || 0);
  }
  if ("marginTop" in style) {
    node.setMargin(src_default.EDGE_TOP, style.marginTop || 0);
  }
  if ("marginBottom" in style) {
    node.setMargin(src_default.EDGE_BOTTOM, style.marginBottom || 0);
  }
};
var applyPaddingStyles = (node, style) => {
  if ("padding" in style) {
    node.setPadding(src_default.EDGE_ALL, style.padding ?? 0);
  }
  if ("paddingX" in style) {
    node.setPadding(src_default.EDGE_HORIZONTAL, style.paddingX ?? 0);
  }
  if ("paddingY" in style) {
    node.setPadding(src_default.EDGE_VERTICAL, style.paddingY ?? 0);
  }
  if ("paddingLeft" in style) {
    node.setPadding(src_default.EDGE_LEFT, style.paddingLeft || 0);
  }
  if ("paddingRight" in style) {
    node.setPadding(src_default.EDGE_RIGHT, style.paddingRight || 0);
  }
  if ("paddingTop" in style) {
    node.setPadding(src_default.EDGE_TOP, style.paddingTop || 0);
  }
  if ("paddingBottom" in style) {
    node.setPadding(src_default.EDGE_BOTTOM, style.paddingBottom || 0);
  }
};
var applyFlexStyles = (node, style) => {
  if ("flexGrow" in style) {
    node.setFlexGrow(style.flexGrow ?? 0);
  }
  if ("flexShrink" in style) {
    node.setFlexShrink(typeof style.flexShrink === "number" ? style.flexShrink : 1);
  }
  if ("flexWrap" in style) {
    if (style.flexWrap === "nowrap") {
      node.setFlexWrap(src_default.WRAP_NO_WRAP);
    }
    if (style.flexWrap === "wrap") {
      node.setFlexWrap(src_default.WRAP_WRAP);
    }
    if (style.flexWrap === "wrap-reverse") {
      node.setFlexWrap(src_default.WRAP_WRAP_REVERSE);
    }
  }
  if ("flexDirection" in style) {
    if (style.flexDirection === "row") {
      node.setFlexDirection(src_default.FLEX_DIRECTION_ROW);
    }
    if (style.flexDirection === "row-reverse") {
      node.setFlexDirection(src_default.FLEX_DIRECTION_ROW_REVERSE);
    }
    if (style.flexDirection === "column") {
      node.setFlexDirection(src_default.FLEX_DIRECTION_COLUMN);
    }
    if (style.flexDirection === "column-reverse") {
      node.setFlexDirection(src_default.FLEX_DIRECTION_COLUMN_REVERSE);
    }
  }
  if ("flexBasis" in style) {
    if (typeof style.flexBasis === "number") {
      node.setFlexBasis(style.flexBasis);
    } else if (typeof style.flexBasis === "string") {
      node.setFlexBasisPercent(Number.parseInt(style.flexBasis, 10));
    } else {
      node.setFlexBasis(Number.NaN);
    }
  }
  if ("alignItems" in style) {
    if (style.alignItems === "stretch" || !style.alignItems) {
      node.setAlignItems(src_default.ALIGN_STRETCH);
    }
    if (style.alignItems === "flex-start") {
      node.setAlignItems(src_default.ALIGN_FLEX_START);
    }
    if (style.alignItems === "center") {
      node.setAlignItems(src_default.ALIGN_CENTER);
    }
    if (style.alignItems === "flex-end") {
      node.setAlignItems(src_default.ALIGN_FLEX_END);
    }
  }
  if ("alignSelf" in style) {
    if (style.alignSelf === "auto" || !style.alignSelf) {
      node.setAlignSelf(src_default.ALIGN_AUTO);
    }
    if (style.alignSelf === "flex-start") {
      node.setAlignSelf(src_default.ALIGN_FLEX_START);
    }
    if (style.alignSelf === "center") {
      node.setAlignSelf(src_default.ALIGN_CENTER);
    }
    if (style.alignSelf === "flex-end") {
      node.setAlignSelf(src_default.ALIGN_FLEX_END);
    }
  }
  if ("justifyContent" in style) {
    if (style.justifyContent === "flex-start" || !style.justifyContent) {
      node.setJustifyContent(src_default.JUSTIFY_FLEX_START);
    }
    if (style.justifyContent === "center") {
      node.setJustifyContent(src_default.JUSTIFY_CENTER);
    }
    if (style.justifyContent === "flex-end") {
      node.setJustifyContent(src_default.JUSTIFY_FLEX_END);
    }
    if (style.justifyContent === "space-between") {
      node.setJustifyContent(src_default.JUSTIFY_SPACE_BETWEEN);
    }
    if (style.justifyContent === "space-around") {
      node.setJustifyContent(src_default.JUSTIFY_SPACE_AROUND);
    }
    if (style.justifyContent === "space-evenly") {
      node.setJustifyContent(src_default.JUSTIFY_SPACE_EVENLY);
    }
  }
};
var applyDimensionStyles = (node, style) => {
  if ("width" in style) {
    if (typeof style.width === "number") {
      node.setWidth(style.width);
    } else if (typeof style.width === "string") {
      node.setWidthPercent(Number.parseInt(style.width, 10));
    } else {
      node.setWidthAuto();
    }
  }
  if ("height" in style) {
    if (typeof style.height === "number") {
      node.setHeight(style.height);
    } else if (typeof style.height === "string") {
      node.setHeightPercent(Number.parseInt(style.height, 10));
    } else {
      node.setHeightAuto();
    }
  }
  if ("minWidth" in style) {
    if (typeof style.minWidth === "string") {
      node.setMinWidthPercent(Number.parseInt(style.minWidth, 10));
    } else {
      node.setMinWidth(style.minWidth ?? 0);
    }
  }
  if ("minHeight" in style) {
    if (typeof style.minHeight === "string") {
      node.setMinHeightPercent(Number.parseInt(style.minHeight, 10));
    } else {
      node.setMinHeight(style.minHeight ?? 0);
    }
  }
};
var applyDisplayStyles = (node, style) => {
  if ("display" in style) {
    node.setDisplay(style.display === "flex" ? src_default.DISPLAY_FLEX : src_default.DISPLAY_NONE);
  }
};
var applyBorderStyles = (node, style) => {
  if ("borderStyle" in style) {
    const borderWidth = style.borderStyle ? 1 : 0;
    if (style.borderTop !== false) {
      node.setBorder(src_default.EDGE_TOP, borderWidth);
    }
    if (style.borderBottom !== false) {
      node.setBorder(src_default.EDGE_BOTTOM, borderWidth);
    }
    if (style.borderLeft !== false) {
      node.setBorder(src_default.EDGE_LEFT, borderWidth);
    }
    if (style.borderRight !== false) {
      node.setBorder(src_default.EDGE_RIGHT, borderWidth);
    }
  }
};
var applyGapStyles = (node, style) => {
  if ("gap" in style) {
    node.setGap(src_default.GUTTER_ALL, style.gap ?? 0);
  }
  if ("columnGap" in style) {
    node.setGap(src_default.GUTTER_COLUMN, style.columnGap ?? 0);
  }
  if ("rowGap" in style) {
    node.setGap(src_default.GUTTER_ROW, style.rowGap ?? 0);
  }
};
var styles2 = (node, style = {}) => {
  applyPositionStyles(node, style);
  applyMarginStyles(node, style);
  applyPaddingStyles(node, style);
  applyFlexStyles(node, style);
  applyDimensionStyles(node, style);
  applyDisplayStyles(node, style);
  applyBorderStyles(node, style);
  applyGapStyles(node, style);
};
var styles_default = styles2;

// node_modules/ink/build/reconciler.js
if (process3.env["DEV"] === "true") {
  try {
    await Promise.resolve().then(() => (init_devtools(), devtools_exports));
  } catch (error) {
    if (error.code === "ERR_MODULE_NOT_FOUND") {
      console.warn(`
The environment variable DEV is set to true, so Ink tried to import \`react-devtools-core\`,
but this failed as it was not installed. Debugging with React Devtools requires it.

To install use this command:

$ npm install --save-dev react-devtools-core
				`.trim() + "\n");
    } else {
      throw error;
    }
  }
}
var diff = (before, after) => {
  if (before === after) {
    return;
  }
  if (!before) {
    return after;
  }
  const changed = {};
  let isChanged = false;
  for (const key of Object.keys(before)) {
    const isDeleted = after ? !Object.hasOwn(after, key) : true;
    if (isDeleted) {
      changed[key] = void 0;
      isChanged = true;
    }
  }
  if (after) {
    for (const key of Object.keys(after)) {
      if (after[key] !== before[key]) {
        changed[key] = after[key];
        isChanged = true;
      }
    }
  }
  return isChanged ? changed : void 0;
};
var cleanupYogaNode = (node) => {
  node?.unsetMeasureFunc();
  node?.freeRecursive();
};
var reconciler_default = (0, import_react_reconciler.default)({
  getRootHostContext: () => ({
    isInsideText: false
  }),
  prepareForCommit: () => null,
  preparePortalMount: () => null,
  clearContainer: () => false,
  resetAfterCommit(rootNode) {
    if (typeof rootNode.onComputeLayout === "function") {
      rootNode.onComputeLayout();
    }
    if (rootNode.isStaticDirty) {
      rootNode.isStaticDirty = false;
      if (typeof rootNode.onImmediateRender === "function") {
        rootNode.onImmediateRender();
      }
      return;
    }
    if (typeof rootNode.onRender === "function") {
      rootNode.onRender();
    }
  },
  getChildHostContext(parentHostContext, type) {
    const previousIsInsideText = parentHostContext.isInsideText;
    const isInsideText = type === "ink-text" || type === "ink-virtual-text";
    if (previousIsInsideText === isInsideText) {
      return parentHostContext;
    }
    return { isInsideText };
  },
  shouldSetTextContent: () => false,
  createInstance(originalType, newProps, _root, hostContext) {
    if (hostContext.isInsideText && originalType === "ink-box") {
      throw new Error(`<Box> can\u2019t be nested inside <Text> component`);
    }
    const type = originalType === "ink-text" && hostContext.isInsideText ? "ink-virtual-text" : originalType;
    const node = createNode(type);
    for (const [key, value] of Object.entries(newProps)) {
      if (key === "children") {
        continue;
      }
      if (key === "style") {
        setStyle(node, value);
        if (node.yogaNode) {
          styles_default(node.yogaNode, value);
        }
        continue;
      }
      if (key === "internal_transform") {
        node.internal_transform = value;
        continue;
      }
      if (key === "internal_static") {
        node.internal_static = true;
        continue;
      }
      setAttribute(node, key, value);
    }
    return node;
  },
  createTextInstance(text, _root, hostContext) {
    if (!hostContext.isInsideText) {
      throw new Error(`Text string "${text}" must be rendered inside <Text> component`);
    }
    return createTextNode(text);
  },
  resetTextContent() {
  },
  hideTextInstance(node) {
    setTextNodeValue(node, "");
  },
  unhideTextInstance(node, text) {
    setTextNodeValue(node, text);
  },
  getPublicInstance: (instance) => instance,
  hideInstance(node) {
    node.yogaNode?.setDisplay(src_default.DISPLAY_NONE);
  },
  unhideInstance(node) {
    node.yogaNode?.setDisplay(src_default.DISPLAY_FLEX);
  },
  appendInitialChild: appendChildNode,
  appendChild: appendChildNode,
  insertBefore: insertBeforeNode,
  finalizeInitialChildren(node, _type, _props, rootNode) {
    if (node.internal_static) {
      rootNode.isStaticDirty = true;
      rootNode.staticNode = node;
    }
    return false;
  },
  isPrimaryRenderer: true,
  supportsMutation: true,
  supportsPersistence: false,
  supportsHydration: false,
  scheduleTimeout: setTimeout,
  cancelTimeout: clearTimeout,
  noTimeout: -1,
  getCurrentEventPriority: () => import_constants.DefaultEventPriority,
  beforeActiveInstanceBlur() {
  },
  afterActiveInstanceBlur() {
  },
  detachDeletedInstance() {
  },
  getInstanceFromNode: () => null,
  prepareScopeUpdate() {
  },
  getInstanceFromScope: () => null,
  appendChildToContainer: appendChildNode,
  insertInContainerBefore: insertBeforeNode,
  removeChildFromContainer(node, removeNode) {
    removeChildNode(node, removeNode);
    cleanupYogaNode(removeNode.yogaNode);
  },
  prepareUpdate(node, _type, oldProps, newProps, rootNode) {
    if (node.internal_static) {
      rootNode.isStaticDirty = true;
    }
    const props = diff(oldProps, newProps);
    const style = diff(oldProps["style"], newProps["style"]);
    if (!props && !style) {
      return null;
    }
    return { props, style };
  },
  commitUpdate(node, { props, style }) {
    if (props) {
      for (const [key, value] of Object.entries(props)) {
        if (key === "style") {
          setStyle(node, value);
          continue;
        }
        if (key === "internal_transform") {
          node.internal_transform = value;
          continue;
        }
        if (key === "internal_static") {
          node.internal_static = true;
          continue;
        }
        setAttribute(node, key, value);
      }
    }
    if (style && node.yogaNode) {
      styles_default(node.yogaNode, style);
    }
  },
  commitTextUpdate(node, _oldText, newText) {
    setTextNodeValue(node, newText);
  },
  removeChild(node, removeNode) {
    removeChildNode(node, removeNode);
    cleanupYogaNode(removeNode.yogaNode);
  }
});

// node_modules/indent-string/index.js
function indentString(string, count = 1, options = {}) {
  const {
    indent = " ",
    includeEmptyLines = false
  } = options;
  if (typeof string !== "string") {
    throw new TypeError(
      `Expected \`input\` to be a \`string\`, got \`${typeof string}\``
    );
  }
  if (typeof count !== "number") {
    throw new TypeError(
      `Expected \`count\` to be a \`number\`, got \`${typeof count}\``
    );
  }
  if (count < 0) {
    throw new RangeError(
      `Expected \`count\` to be at least 0, got \`${count}\``
    );
  }
  if (typeof indent !== "string") {
    throw new TypeError(
      `Expected \`options.indent\` to be a \`string\`, got \`${typeof indent}\``
    );
  }
  if (count === 0) {
    return string;
  }
  const regex2 = includeEmptyLines ? /^/gm : /^(?!\s*$)/gm;
  return string.replace(regex2, indent.repeat(count));
}

// node_modules/ink/build/get-max-width.js
var getMaxWidth = (yogaNode) => {
  return yogaNode.getComputedWidth() - yogaNode.getComputedPadding(src_default.EDGE_LEFT) - yogaNode.getComputedPadding(src_default.EDGE_RIGHT) - yogaNode.getComputedBorder(src_default.EDGE_LEFT) - yogaNode.getComputedBorder(src_default.EDGE_RIGHT);
};
var get_max_width_default = getMaxWidth;

// node_modules/ink/build/render-border.js
var import_cli_boxes = __toESM(require_cli_boxes(), 1);

// node_modules/chalk/source/vendor/ansi-styles/index.js
var ANSI_BACKGROUND_OFFSET2 = 10;
var wrapAnsi162 = (offset = 0) => (code) => `\x1B[${code + offset}m`;
var wrapAnsi2562 = (offset = 0) => (code) => `\x1B[${38 + offset};5;${code}m`;
var wrapAnsi16m2 = (offset = 0) => (red, green, blue) => `\x1B[${38 + offset};2;${red};${green};${blue}m`;
var styles3 = {
  modifier: {
    reset: [0, 0],
    // 21 isn't widely supported and 22 does the same thing
    bold: [1, 22],
    dim: [2, 22],
    italic: [3, 23],
    underline: [4, 24],
    overline: [53, 55],
    inverse: [7, 27],
    hidden: [8, 28],
    strikethrough: [9, 29]
  },
  color: {
    black: [30, 39],
    red: [31, 39],
    green: [32, 39],
    yellow: [33, 39],
    blue: [34, 39],
    magenta: [35, 39],
    cyan: [36, 39],
    white: [37, 39],
    // Bright color
    blackBright: [90, 39],
    gray: [90, 39],
    // Alias of `blackBright`
    grey: [90, 39],
    // Alias of `blackBright`
    redBright: [91, 39],
    greenBright: [92, 39],
    yellowBright: [93, 39],
    blueBright: [94, 39],
    magentaBright: [95, 39],
    cyanBright: [96, 39],
    whiteBright: [97, 39]
  },
  bgColor: {
    bgBlack: [40, 49],
    bgRed: [41, 49],
    bgGreen: [42, 49],
    bgYellow: [43, 49],
    bgBlue: [44, 49],
    bgMagenta: [45, 49],
    bgCyan: [46, 49],
    bgWhite: [47, 49],
    // Bright color
    bgBlackBright: [100, 49],
    bgGray: [100, 49],
    // Alias of `bgBlackBright`
    bgGrey: [100, 49],
    // Alias of `bgBlackBright`
    bgRedBright: [101, 49],
    bgGreenBright: [102, 49],
    bgYellowBright: [103, 49],
    bgBlueBright: [104, 49],
    bgMagentaBright: [105, 49],
    bgCyanBright: [106, 49],
    bgWhiteBright: [107, 49]
  }
};
var modifierNames2 = Object.keys(styles3.modifier);
var foregroundColorNames2 = Object.keys(styles3.color);
var backgroundColorNames2 = Object.keys(styles3.bgColor);
var colorNames2 = [...foregroundColorNames2, ...backgroundColorNames2];
function assembleStyles2() {
  const codes = /* @__PURE__ */ new Map();
  for (const [groupName, group] of Object.entries(styles3)) {
    for (const [styleName, style] of Object.entries(group)) {
      styles3[styleName] = {
        open: `\x1B[${style[0]}m`,
        close: `\x1B[${style[1]}m`
      };
      group[styleName] = styles3[styleName];
      codes.set(style[0], style[1]);
    }
    Object.defineProperty(styles3, groupName, {
      value: group,
      enumerable: false
    });
  }
  Object.defineProperty(styles3, "codes", {
    value: codes,
    enumerable: false
  });
  styles3.color.close = "\x1B[39m";
  styles3.bgColor.close = "\x1B[49m";
  styles3.color.ansi = wrapAnsi162();
  styles3.color.ansi256 = wrapAnsi2562();
  styles3.color.ansi16m = wrapAnsi16m2();
  styles3.bgColor.ansi = wrapAnsi162(ANSI_BACKGROUND_OFFSET2);
  styles3.bgColor.ansi256 = wrapAnsi2562(ANSI_BACKGROUND_OFFSET2);
  styles3.bgColor.ansi16m = wrapAnsi16m2(ANSI_BACKGROUND_OFFSET2);
  Object.defineProperties(styles3, {
    rgbToAnsi256: {
      value(red, green, blue) {
        if (red === green && green === blue) {
          if (red < 8) {
            return 16;
          }
          if (red > 248) {
            return 231;
          }
          return Math.round((red - 8) / 247 * 24) + 232;
        }
        return 16 + 36 * Math.round(red / 255 * 5) + 6 * Math.round(green / 255 * 5) + Math.round(blue / 255 * 5);
      },
      enumerable: false
    },
    hexToRgb: {
      value(hex) {
        const matches = /[a-f\d]{6}|[a-f\d]{3}/i.exec(hex.toString(16));
        if (!matches) {
          return [0, 0, 0];
        }
        let [colorString] = matches;
        if (colorString.length === 3) {
          colorString = [...colorString].map((character) => character + character).join("");
        }
        const integer = Number.parseInt(colorString, 16);
        return [
          /* eslint-disable no-bitwise */
          integer >> 16 & 255,
          integer >> 8 & 255,
          integer & 255
          /* eslint-enable no-bitwise */
        ];
      },
      enumerable: false
    },
    hexToAnsi256: {
      value: (hex) => styles3.rgbToAnsi256(...styles3.hexToRgb(hex)),
      enumerable: false
    },
    ansi256ToAnsi: {
      value(code) {
        if (code < 8) {
          return 30 + code;
        }
        if (code < 16) {
          return 90 + (code - 8);
        }
        let red;
        let green;
        let blue;
        if (code >= 232) {
          red = ((code - 232) * 10 + 8) / 255;
          green = red;
          blue = red;
        } else {
          code -= 16;
          const remainder = code % 36;
          red = Math.floor(code / 36) / 5;
          green = Math.floor(remainder / 6) / 5;
          blue = remainder % 6 / 5;
        }
        const value = Math.max(red, green, blue) * 2;
        if (value === 0) {
          return 30;
        }
        let result = 30 + (Math.round(blue) << 2 | Math.round(green) << 1 | Math.round(red));
        if (value === 2) {
          result += 60;
        }
        return result;
      },
      enumerable: false
    },
    rgbToAnsi: {
      value: (red, green, blue) => styles3.ansi256ToAnsi(styles3.rgbToAnsi256(red, green, blue)),
      enumerable: false
    },
    hexToAnsi: {
      value: (hex) => styles3.ansi256ToAnsi(styles3.hexToAnsi256(hex)),
      enumerable: false
    }
  });
  return styles3;
}
var ansiStyles2 = assembleStyles2();
var ansi_styles_default2 = ansiStyles2;

// node_modules/chalk/source/vendor/supports-color/index.js
import process4 from "process";
import os2 from "os";
import tty from "tty";
function hasFlag(flag, argv = globalThis.Deno ? globalThis.Deno.args : process4.argv) {
  const prefix = flag.startsWith("-") ? "" : flag.length === 1 ? "-" : "--";
  const position = argv.indexOf(prefix + flag);
  const terminatorPosition = argv.indexOf("--");
  return position !== -1 && (terminatorPosition === -1 || position < terminatorPosition);
}
var { env: env2 } = process4;
var flagForceColor;
if (hasFlag("no-color") || hasFlag("no-colors") || hasFlag("color=false") || hasFlag("color=never")) {
  flagForceColor = 0;
} else if (hasFlag("color") || hasFlag("colors") || hasFlag("color=true") || hasFlag("color=always")) {
  flagForceColor = 1;
}
function envForceColor() {
  if ("FORCE_COLOR" in env2) {
    if (env2.FORCE_COLOR === "true") {
      return 1;
    }
    if (env2.FORCE_COLOR === "false") {
      return 0;
    }
    return env2.FORCE_COLOR.length === 0 ? 1 : Math.min(Number.parseInt(env2.FORCE_COLOR, 10), 3);
  }
}
function translateLevel(level) {
  if (level === 0) {
    return false;
  }
  return {
    level,
    hasBasic: true,
    has256: level >= 2,
    has16m: level >= 3
  };
}
function _supportsColor(haveStream, { streamIsTTY, sniffFlags = true } = {}) {
  const noFlagForceColor = envForceColor();
  if (noFlagForceColor !== void 0) {
    flagForceColor = noFlagForceColor;
  }
  const forceColor = sniffFlags ? flagForceColor : noFlagForceColor;
  if (forceColor === 0) {
    return 0;
  }
  if (sniffFlags) {
    if (hasFlag("color=16m") || hasFlag("color=full") || hasFlag("color=truecolor")) {
      return 3;
    }
    if (hasFlag("color=256")) {
      return 2;
    }
  }
  if ("TF_BUILD" in env2 && "AGENT_NAME" in env2) {
    return 1;
  }
  if (haveStream && !streamIsTTY && forceColor === void 0) {
    return 0;
  }
  const min = forceColor || 0;
  if (env2.TERM === "dumb") {
    return min;
  }
  if (process4.platform === "win32") {
    const osRelease = os2.release().split(".");
    if (Number(osRelease[0]) >= 10 && Number(osRelease[2]) >= 10586) {
      return Number(osRelease[2]) >= 14931 ? 3 : 2;
    }
    return 1;
  }
  if ("CI" in env2) {
    if (["GITHUB_ACTIONS", "GITEA_ACTIONS", "CIRCLECI"].some((key) => key in env2)) {
      return 3;
    }
    if (["TRAVIS", "APPVEYOR", "GITLAB_CI", "BUILDKITE", "DRONE"].some((sign) => sign in env2) || env2.CI_NAME === "codeship") {
      return 1;
    }
    return min;
  }
  if ("TEAMCITY_VERSION" in env2) {
    return /^(9\.(0*[1-9]\d*)\.|\d{2,}\.)/.test(env2.TEAMCITY_VERSION) ? 1 : 0;
  }
  if (env2.COLORTERM === "truecolor") {
    return 3;
  }
  if (env2.TERM === "xterm-kitty") {
    return 3;
  }
  if (env2.TERM === "xterm-ghostty") {
    return 3;
  }
  if (env2.TERM === "wezterm") {
    return 3;
  }
  if ("TERM_PROGRAM" in env2) {
    const version = Number.parseInt((env2.TERM_PROGRAM_VERSION || "").split(".")[0], 10);
    switch (env2.TERM_PROGRAM) {
      case "iTerm.app": {
        return version >= 3 ? 3 : 2;
      }
      case "Apple_Terminal": {
        return 2;
      }
    }
  }
  if (/-256(color)?$/i.test(env2.TERM)) {
    return 2;
  }
  if (/^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/i.test(env2.TERM)) {
    return 1;
  }
  if ("COLORTERM" in env2) {
    return 1;
  }
  return min;
}
function createSupportsColor(stream, options = {}) {
  const level = _supportsColor(stream, {
    streamIsTTY: stream && stream.isTTY,
    ...options
  });
  return translateLevel(level);
}
var supportsColor = {
  stdout: createSupportsColor({ isTTY: tty.isatty(1) }),
  stderr: createSupportsColor({ isTTY: tty.isatty(2) })
};
var supports_color_default = supportsColor;

// node_modules/chalk/source/utilities.js
function stringReplaceAll(string, substring, replacer) {
  let index = string.indexOf(substring);
  if (index === -1) {
    return string;
  }
  const substringLength = substring.length;
  let endIndex = 0;
  let returnValue = "";
  do {
    returnValue += string.slice(endIndex, index) + substring + replacer;
    endIndex = index + substringLength;
    index = string.indexOf(substring, endIndex);
  } while (index !== -1);
  returnValue += string.slice(endIndex);
  return returnValue;
}
function stringEncaseCRLFWithFirstIndex(string, prefix, postfix, index) {
  let endIndex = 0;
  let returnValue = "";
  do {
    const gotCR = string[index - 1] === "\r";
    returnValue += string.slice(endIndex, gotCR ? index - 1 : index) + prefix + (gotCR ? "\r\n" : "\n") + postfix;
    endIndex = index + 1;
    index = string.indexOf("\n", endIndex);
  } while (index !== -1);
  returnValue += string.slice(endIndex);
  return returnValue;
}

// node_modules/chalk/source/index.js
var { stdout: stdoutColor, stderr: stderrColor } = supports_color_default;
var GENERATOR = /* @__PURE__ */ Symbol("GENERATOR");
var STYLER = /* @__PURE__ */ Symbol("STYLER");
var IS_EMPTY = /* @__PURE__ */ Symbol("IS_EMPTY");
var levelMapping = [
  "ansi",
  "ansi",
  "ansi256",
  "ansi16m"
];
var styles4 = /* @__PURE__ */ Object.create(null);
var applyOptions = (object, options = {}) => {
  if (options.level && !(Number.isInteger(options.level) && options.level >= 0 && options.level <= 3)) {
    throw new Error("The `level` option should be an integer from 0 to 3");
  }
  const colorLevel = stdoutColor ? stdoutColor.level : 0;
  object.level = options.level === void 0 ? colorLevel : options.level;
};
var chalkFactory = (options) => {
  const chalk2 = (...strings) => strings.join(" ");
  applyOptions(chalk2, options);
  Object.setPrototypeOf(chalk2, createChalk.prototype);
  return chalk2;
};
function createChalk(options) {
  return chalkFactory(options);
}
Object.setPrototypeOf(createChalk.prototype, Function.prototype);
for (const [styleName, style] of Object.entries(ansi_styles_default2)) {
  styles4[styleName] = {
    get() {
      const builder = createBuilder(this, createStyler(style.open, style.close, this[STYLER]), this[IS_EMPTY]);
      Object.defineProperty(this, styleName, { value: builder });
      return builder;
    }
  };
}
styles4.visible = {
  get() {
    const builder = createBuilder(this, this[STYLER], true);
    Object.defineProperty(this, "visible", { value: builder });
    return builder;
  }
};
var getModelAnsi = (model, level, type, ...arguments_) => {
  if (model === "rgb") {
    if (level === "ansi16m") {
      return ansi_styles_default2[type].ansi16m(...arguments_);
    }
    if (level === "ansi256") {
      return ansi_styles_default2[type].ansi256(ansi_styles_default2.rgbToAnsi256(...arguments_));
    }
    return ansi_styles_default2[type].ansi(ansi_styles_default2.rgbToAnsi(...arguments_));
  }
  if (model === "hex") {
    return getModelAnsi("rgb", level, type, ...ansi_styles_default2.hexToRgb(...arguments_));
  }
  return ansi_styles_default2[type][model](...arguments_);
};
var usedModels = ["rgb", "hex", "ansi256"];
for (const model of usedModels) {
  styles4[model] = {
    get() {
      const { level } = this;
      return function(...arguments_) {
        const styler = createStyler(getModelAnsi(model, levelMapping[level], "color", ...arguments_), ansi_styles_default2.color.close, this[STYLER]);
        return createBuilder(this, styler, this[IS_EMPTY]);
      };
    }
  };
  const bgModel = "bg" + model[0].toUpperCase() + model.slice(1);
  styles4[bgModel] = {
    get() {
      const { level } = this;
      return function(...arguments_) {
        const styler = createStyler(getModelAnsi(model, levelMapping[level], "bgColor", ...arguments_), ansi_styles_default2.bgColor.close, this[STYLER]);
        return createBuilder(this, styler, this[IS_EMPTY]);
      };
    }
  };
}
var proto = Object.defineProperties(() => {
}, {
  ...styles4,
  level: {
    enumerable: true,
    get() {
      return this[GENERATOR].level;
    },
    set(level) {
      this[GENERATOR].level = level;
    }
  }
});
var createStyler = (open, close, parent) => {
  let openAll;
  let closeAll;
  if (parent === void 0) {
    openAll = open;
    closeAll = close;
  } else {
    openAll = parent.openAll + open;
    closeAll = close + parent.closeAll;
  }
  return {
    open,
    close,
    openAll,
    closeAll,
    parent
  };
};
var createBuilder = (self, _styler, _isEmpty) => {
  const builder = (...arguments_) => applyStyle(builder, arguments_.length === 1 ? "" + arguments_[0] : arguments_.join(" "));
  Object.setPrototypeOf(builder, proto);
  builder[GENERATOR] = self;
  builder[STYLER] = _styler;
  builder[IS_EMPTY] = _isEmpty;
  return builder;
};
var applyStyle = (self, string) => {
  if (self.level <= 0 || !string) {
    return self[IS_EMPTY] ? "" : string;
  }
  let styler = self[STYLER];
  if (styler === void 0) {
    return string;
  }
  const { openAll, closeAll } = styler;
  if (string.includes("\x1B")) {
    while (styler !== void 0) {
      string = stringReplaceAll(string, styler.close, styler.open);
      styler = styler.parent;
    }
  }
  const lfIndex = string.indexOf("\n");
  if (lfIndex !== -1) {
    string = stringEncaseCRLFWithFirstIndex(string, closeAll, openAll, lfIndex);
  }
  return openAll + string + closeAll;
};
Object.defineProperties(createChalk.prototype, styles4);
var chalk = createChalk();
var chalkStderr = createChalk({ level: stderrColor ? stderrColor.level : 0 });
var source_default = chalk;

// node_modules/ink/build/colorize.js
var rgbRegex = /^rgb\(\s?(\d+),\s?(\d+),\s?(\d+)\s?\)$/;
var ansiRegex2 = /^ansi256\(\s?(\d+)\s?\)$/;
var isNamedColor = (color) => {
  return color in source_default;
};
var colorize = (str, color, type) => {
  if (!color) {
    return str;
  }
  if (isNamedColor(color)) {
    if (type === "foreground") {
      return source_default[color](str);
    }
    const methodName = `bg${color[0].toUpperCase() + color.slice(1)}`;
    return source_default[methodName](str);
  }
  if (color.startsWith("#")) {
    return type === "foreground" ? source_default.hex(color)(str) : source_default.bgHex(color)(str);
  }
  if (color.startsWith("ansi256")) {
    const matches = ansiRegex2.exec(color);
    if (!matches) {
      return str;
    }
    const value = Number(matches[1]);
    return type === "foreground" ? source_default.ansi256(value)(str) : source_default.bgAnsi256(value)(str);
  }
  if (color.startsWith("rgb")) {
    const matches = rgbRegex.exec(color);
    if (!matches) {
      return str;
    }
    const firstValue = Number(matches[1]);
    const secondValue = Number(matches[2]);
    const thirdValue = Number(matches[3]);
    return type === "foreground" ? source_default.rgb(firstValue, secondValue, thirdValue)(str) : source_default.bgRgb(firstValue, secondValue, thirdValue)(str);
  }
  return str;
};
var colorize_default = colorize;

// node_modules/ink/build/render-border.js
var renderBorder = (x, y, node, output) => {
  if (node.style.borderStyle) {
    const width = node.yogaNode.getComputedWidth();
    const height = node.yogaNode.getComputedHeight();
    const box = typeof node.style.borderStyle === "string" ? import_cli_boxes.default[node.style.borderStyle] : node.style.borderStyle;
    const topBorderColor = node.style.borderTopColor ?? node.style.borderColor;
    const bottomBorderColor = node.style.borderBottomColor ?? node.style.borderColor;
    const leftBorderColor = node.style.borderLeftColor ?? node.style.borderColor;
    const rightBorderColor = node.style.borderRightColor ?? node.style.borderColor;
    const dimTopBorderColor = node.style.borderTopDimColor ?? node.style.borderDimColor;
    const dimBottomBorderColor = node.style.borderBottomDimColor ?? node.style.borderDimColor;
    const dimLeftBorderColor = node.style.borderLeftDimColor ?? node.style.borderDimColor;
    const dimRightBorderColor = node.style.borderRightDimColor ?? node.style.borderDimColor;
    const showTopBorder = node.style.borderTop !== false;
    const showBottomBorder = node.style.borderBottom !== false;
    const showLeftBorder = node.style.borderLeft !== false;
    const showRightBorder = node.style.borderRight !== false;
    const contentWidth = width - (showLeftBorder ? 1 : 0) - (showRightBorder ? 1 : 0);
    let topBorder = showTopBorder ? colorize_default((showLeftBorder ? box.topLeft : "") + box.top.repeat(contentWidth) + (showRightBorder ? box.topRight : ""), topBorderColor, "foreground") : void 0;
    if (showTopBorder && dimTopBorderColor) {
      topBorder = source_default.dim(topBorder);
    }
    let verticalBorderHeight = height;
    if (showTopBorder) {
      verticalBorderHeight -= 1;
    }
    if (showBottomBorder) {
      verticalBorderHeight -= 1;
    }
    let leftBorder = (colorize_default(box.left, leftBorderColor, "foreground") + "\n").repeat(verticalBorderHeight);
    if (dimLeftBorderColor) {
      leftBorder = source_default.dim(leftBorder);
    }
    let rightBorder = (colorize_default(box.right, rightBorderColor, "foreground") + "\n").repeat(verticalBorderHeight);
    if (dimRightBorderColor) {
      rightBorder = source_default.dim(rightBorder);
    }
    let bottomBorder = showBottomBorder ? colorize_default((showLeftBorder ? box.bottomLeft : "") + box.bottom.repeat(contentWidth) + (showRightBorder ? box.bottomRight : ""), bottomBorderColor, "foreground") : void 0;
    if (showBottomBorder && dimBottomBorderColor) {
      bottomBorder = source_default.dim(bottomBorder);
    }
    const offsetY = showTopBorder ? 1 : 0;
    if (topBorder) {
      output.write(x, y, topBorder, { transformers: [] });
    }
    if (showLeftBorder) {
      output.write(x, y + offsetY, leftBorder, { transformers: [] });
    }
    if (showRightBorder) {
      output.write(x + width - 1, y + offsetY, rightBorder, {
        transformers: []
      });
    }
    if (bottomBorder) {
      output.write(x, y + height - 1, bottomBorder, { transformers: [] });
    }
  }
};
var render_border_default = renderBorder;

// node_modules/ink/build/render-node-to-output.js
var applyPaddingToText = (node, text) => {
  const yogaNode = node.childNodes[0]?.yogaNode;
  if (yogaNode) {
    const offsetX = yogaNode.getComputedLeft();
    const offsetY = yogaNode.getComputedTop();
    text = "\n".repeat(offsetY) + indentString(text, offsetX);
  }
  return text;
};
var renderNodeToOutput = (node, output, options) => {
  const { offsetX = 0, offsetY = 0, transformers = [], skipStaticElements } = options;
  if (skipStaticElements && node.internal_static) {
    return;
  }
  const { yogaNode } = node;
  if (yogaNode) {
    if (yogaNode.getDisplay() === src_default.DISPLAY_NONE) {
      return;
    }
    const x = offsetX + yogaNode.getComputedLeft();
    const y = offsetY + yogaNode.getComputedTop();
    let newTransformers = transformers;
    if (typeof node.internal_transform === "function") {
      newTransformers = [node.internal_transform, ...transformers];
    }
    if (node.nodeName === "ink-text") {
      let text = squash_text_nodes_default(node);
      if (text.length > 0) {
        const currentWidth = widestLine(text);
        const maxWidth = get_max_width_default(yogaNode);
        if (currentWidth > maxWidth) {
          const textWrap = node.style.textWrap ?? "wrap";
          text = wrap_text_default(text, maxWidth, textWrap);
        }
        text = applyPaddingToText(node, text);
        output.write(x, y, text, { transformers: newTransformers });
      }
      return;
    }
    let clipped = false;
    if (node.nodeName === "ink-box") {
      render_border_default(x, y, node, output);
      const clipHorizontally = node.style.overflowX === "hidden" || node.style.overflow === "hidden";
      const clipVertically = node.style.overflowY === "hidden" || node.style.overflow === "hidden";
      if (clipHorizontally || clipVertically) {
        const x1 = clipHorizontally ? x + yogaNode.getComputedBorder(src_default.EDGE_LEFT) : void 0;
        const x2 = clipHorizontally ? x + yogaNode.getComputedWidth() - yogaNode.getComputedBorder(src_default.EDGE_RIGHT) : void 0;
        const y1 = clipVertically ? y + yogaNode.getComputedBorder(src_default.EDGE_TOP) : void 0;
        const y2 = clipVertically ? y + yogaNode.getComputedHeight() - yogaNode.getComputedBorder(src_default.EDGE_BOTTOM) : void 0;
        output.clip({ x1, x2, y1, y2 });
        clipped = true;
      }
    }
    if (node.nodeName === "ink-root" || node.nodeName === "ink-box") {
      for (const childNode of node.childNodes) {
        renderNodeToOutput(childNode, output, {
          offsetX: x,
          offsetY: y,
          transformers: newTransformers,
          skipStaticElements
        });
      }
      if (clipped) {
        output.unclip();
      }
    }
  }
};
var render_node_to_output_default = renderNodeToOutput;

// node_modules/slice-ansi/node_modules/is-fullwidth-code-point/index.js
function isFullwidthCodePoint2(codePoint) {
  if (!Number.isInteger(codePoint)) {
    return false;
  }
  return isFullWidth(codePoint) || isWide(codePoint);
}

// node_modules/slice-ansi/index.js
var ESCAPES3 = /* @__PURE__ */ new Set([27, 155]);
var CODE_POINT_0 = "0".codePointAt(0);
var CODE_POINT_9 = "9".codePointAt(0);
var MAX_ANSI_SEQUENCE_LENGTH = 19;
var endCodesSet = /* @__PURE__ */ new Set();
var endCodesMap = /* @__PURE__ */ new Map();
for (const [start, end] of ansi_styles_default.codes) {
  endCodesSet.add(ansi_styles_default.color.ansi(end));
  endCodesMap.set(ansi_styles_default.color.ansi(start), ansi_styles_default.color.ansi(end));
}
function getEndCode(code) {
  if (endCodesSet.has(code)) {
    return code;
  }
  if (endCodesMap.has(code)) {
    return endCodesMap.get(code);
  }
  code = code.slice(2);
  if (code.includes(";")) {
    code = code[0] + "0";
  }
  const returnValue = ansi_styles_default.codes.get(Number.parseInt(code, 10));
  if (returnValue) {
    return ansi_styles_default.color.ansi(returnValue);
  }
  return ansi_styles_default.reset.open;
}
function findNumberIndex(string) {
  for (let index = 0; index < string.length; index++) {
    const codePoint = string.codePointAt(index);
    if (codePoint >= CODE_POINT_0 && codePoint <= CODE_POINT_9) {
      return index;
    }
  }
  return -1;
}
function parseAnsiCode(string, offset) {
  string = string.slice(offset, offset + MAX_ANSI_SEQUENCE_LENGTH);
  const startIndex = findNumberIndex(string);
  if (startIndex !== -1) {
    let endIndex = string.indexOf("m", startIndex);
    if (endIndex === -1) {
      endIndex = string.length;
    }
    return string.slice(0, endIndex + 1);
  }
}
function tokenize(string, endCharacter = Number.POSITIVE_INFINITY) {
  const returnValue = [];
  let index = 0;
  let visibleCount = 0;
  while (index < string.length) {
    const codePoint = string.codePointAt(index);
    if (ESCAPES3.has(codePoint)) {
      const code = parseAnsiCode(string, index);
      if (code) {
        returnValue.push({
          type: "ansi",
          code,
          endCode: getEndCode(code)
        });
        index += code.length;
        continue;
      }
    }
    const isFullWidth2 = isFullwidthCodePoint2(codePoint);
    const character = String.fromCodePoint(codePoint);
    returnValue.push({
      type: "character",
      value: character,
      isFullWidth: isFullWidth2
    });
    index += character.length;
    visibleCount += isFullWidth2 ? 2 : character.length;
    if (visibleCount >= endCharacter) {
      break;
    }
  }
  return returnValue;
}
function reduceAnsiCodes(codes) {
  let returnValue = [];
  for (const code of codes) {
    if (code.code === ansi_styles_default.reset.open) {
      returnValue = [];
    } else if (endCodesSet.has(code.code)) {
      returnValue = returnValue.filter((returnValueCode) => returnValueCode.endCode !== code.code);
    } else {
      returnValue = returnValue.filter((returnValueCode) => returnValueCode.endCode !== code.endCode);
      returnValue.push(code);
    }
  }
  return returnValue;
}
function undoAnsiCodes(codes) {
  const reduced = reduceAnsiCodes(codes);
  const endCodes = reduced.map(({ endCode }) => endCode);
  return endCodes.reverse().join("");
}
function sliceAnsi2(string, start, end) {
  const tokens = tokenize(string, end);
  let activeCodes = [];
  let position = 0;
  let returnValue = "";
  let include = false;
  for (const token of tokens) {
    if (end !== void 0 && position >= end) {
      break;
    }
    if (token.type === "ansi") {
      activeCodes.push(token);
      if (include) {
        returnValue += token.code;
      }
    } else {
      if (!include && position >= start) {
        include = true;
        activeCodes = reduceAnsiCodes(activeCodes);
        returnValue = activeCodes.map(({ code }) => code).join("");
      }
      if (include) {
        returnValue += token.value;
      }
      position += token.isFullWidth ? 2 : token.value.length;
    }
  }
  returnValue += undoAnsiCodes(activeCodes);
  return returnValue;
}

// node_modules/@alcalzone/ansi-tokenize/build/ansiCodes.js
var ESCAPES4 = /* @__PURE__ */ new Set([27, 155]);
var endCodesSet2 = /* @__PURE__ */ new Set();
var endCodesMap2 = /* @__PURE__ */ new Map();
for (const [start, end] of ansi_styles_default.codes) {
  endCodesSet2.add(ansi_styles_default.color.ansi(end));
  endCodesMap2.set(ansi_styles_default.color.ansi(start), ansi_styles_default.color.ansi(end));
}
var linkStartCodePrefix = "\x1B]8;;";
var linkStartCodePrefixCharCodes = linkStartCodePrefix.split("").map((char) => char.charCodeAt(0));
var linkCodeSuffix = "\x07";
var linkCodeSuffixCharCode = linkCodeSuffix.charCodeAt(0);
var linkEndCode = `\x1B]8;;${linkCodeSuffix}`;
function getEndCode2(code) {
  if (endCodesSet2.has(code))
    return code;
  if (endCodesMap2.has(code))
    return endCodesMap2.get(code);
  if (code.startsWith(linkStartCodePrefix))
    return linkEndCode;
  code = code.slice(2);
  if (code.includes(";")) {
    code = code[0] + "0";
  }
  const ret = ansi_styles_default.codes.get(parseInt(code, 10));
  if (ret) {
    return ansi_styles_default.color.ansi(ret);
  } else {
    return ansi_styles_default.reset.open;
  }
}
function ansiCodesToString(codes) {
  return codes.map((code) => code.code).join("");
}

// node_modules/@alcalzone/ansi-tokenize/build/reduce.js
function reduceAnsiCodes2(codes) {
  return reduceAnsiCodesIncremental([], codes);
}
function reduceAnsiCodesIncremental(codes, newCodes) {
  let ret = [...codes];
  for (const code of newCodes) {
    if (code.code === ansi_styles_default.reset.open) {
      ret = [];
    } else if (endCodesSet2.has(code.code)) {
      ret = ret.filter((retCode) => retCode.endCode !== code.code);
    } else {
      ret = ret.filter((retCode) => retCode.endCode !== code.endCode);
      ret.push(code);
    }
  }
  return ret;
}

// node_modules/@alcalzone/ansi-tokenize/build/undo.js
function undoAnsiCodes2(codes) {
  return reduceAnsiCodes2(codes).reverse().map((code) => ({
    ...code,
    code: code.endCode
  }));
}

// node_modules/@alcalzone/ansi-tokenize/build/diff.js
function diffAnsiCodes(from, to) {
  const endCodesInTo = new Set(to.map((code) => code.endCode));
  const startCodesInFrom = new Set(from.map((code) => code.code));
  return [
    // Ignore all styles in `from` that are not overwritten or removed by `to`
    // Disable all styles in `from` that are removed in `to`
    ...undoAnsiCodes2(from.filter((code) => !endCodesInTo.has(code.endCode))),
    // Add all styles in `to` that don't exist in `from`
    ...to.filter((code) => !startCodesInFrom.has(code.code))
  ];
}

// node_modules/@alcalzone/ansi-tokenize/build/styledChars.js
function styledCharsFromTokens(tokens) {
  let codes = [];
  const ret = [];
  for (const token of tokens) {
    if (token.type === "ansi") {
      codes = reduceAnsiCodesIncremental(codes, [token]);
    } else if (token.type === "char") {
      ret.push({
        ...token,
        styles: [...codes]
      });
    }
  }
  return ret;
}
function styledCharsToString(chars) {
  let ret = "";
  for (let i = 0; i < chars.length; i++) {
    const char = chars[i];
    if (i === 0) {
      ret += ansiCodesToString(char.styles);
    } else {
      ret += ansiCodesToString(diffAnsiCodes(chars[i - 1].styles, char.styles));
    }
    ret += char.value;
    if (i === chars.length - 1) {
      ret += ansiCodesToString(diffAnsiCodes(char.styles, []));
    }
  }
  return ret;
}

// node_modules/@alcalzone/ansi-tokenize/build/tokenize.js
function findNumberIndex2(str) {
  for (let index = 0; index < str.length; index++) {
    const charCode = str.charCodeAt(index);
    if (charCode >= 48 && charCode <= 57) {
      return index;
    }
  }
  return -1;
}
function parseLinkCode(string, offset) {
  string = string.slice(offset);
  for (let index = 1; index < linkStartCodePrefixCharCodes.length; index++) {
    if (string.charCodeAt(index) !== linkStartCodePrefixCharCodes[index]) {
      return void 0;
    }
  }
  const endIndex = string.indexOf("\x07", linkStartCodePrefix.length);
  if (endIndex === -1)
    return void 0;
  return string.slice(0, endIndex + 1);
}
function parseAnsiCode2(string, offset) {
  string = string.slice(offset, offset + 19);
  const startIndex = findNumberIndex2(string);
  if (startIndex !== -1) {
    let endIndex = string.indexOf("m", startIndex);
    if (endIndex === -1) {
      endIndex = string.length;
    }
    return string.slice(0, endIndex + 1);
  }
}
function tokenize2(str, endChar = Number.POSITIVE_INFINITY) {
  const ret = [];
  let index = 0;
  let visible = 0;
  while (index < str.length) {
    const codePoint = str.codePointAt(index);
    if (ESCAPES4.has(codePoint)) {
      const code = parseLinkCode(str, index) || parseAnsiCode2(str, index);
      if (code) {
        ret.push({
          type: "ansi",
          code,
          endCode: getEndCode2(code)
        });
        index += code.length;
        continue;
      }
    }
    const fullWidth = isFullwidthCodePoint(codePoint);
    const character = String.fromCodePoint(codePoint);
    ret.push({
      type: "char",
      value: character,
      fullWidth
    });
    index += character.length;
    visible += fullWidth ? 2 : character.length;
    if (visible >= endChar) {
      break;
    }
  }
  return ret;
}

// node_modules/ink/build/output.js
var Output = class {
  width;
  height;
  operations = [];
  constructor(options) {
    const { width, height } = options;
    this.width = width;
    this.height = height;
  }
  write(x, y, text, options) {
    const { transformers } = options;
    if (!text) {
      return;
    }
    this.operations.push({
      type: "write",
      x,
      y,
      text,
      transformers
    });
  }
  clip(clip) {
    this.operations.push({
      type: "clip",
      clip
    });
  }
  unclip() {
    this.operations.push({
      type: "unclip"
    });
  }
  get() {
    const output = [];
    for (let y = 0; y < this.height; y++) {
      const row = [];
      for (let x = 0; x < this.width; x++) {
        row.push({
          type: "char",
          value: " ",
          fullWidth: false,
          styles: []
        });
      }
      output.push(row);
    }
    const clips = [];
    for (const operation of this.operations) {
      if (operation.type === "clip") {
        clips.push(operation.clip);
      }
      if (operation.type === "unclip") {
        clips.pop();
      }
      if (operation.type === "write") {
        const { text, transformers } = operation;
        let { x, y } = operation;
        let lines = text.split("\n");
        const clip = clips.at(-1);
        if (clip) {
          const clipHorizontally = typeof clip?.x1 === "number" && typeof clip?.x2 === "number";
          const clipVertically = typeof clip?.y1 === "number" && typeof clip?.y2 === "number";
          if (clipHorizontally) {
            const width = widestLine(text);
            if (x + width < clip.x1 || x > clip.x2) {
              continue;
            }
          }
          if (clipVertically) {
            const height = lines.length;
            if (y + height < clip.y1 || y > clip.y2) {
              continue;
            }
          }
          if (clipHorizontally) {
            lines = lines.map((line) => {
              const from = x < clip.x1 ? clip.x1 - x : 0;
              const width = stringWidth(line);
              const to = x + width > clip.x2 ? clip.x2 - x : width;
              return sliceAnsi2(line, from, to);
            });
            if (x < clip.x1) {
              x = clip.x1;
            }
          }
          if (clipVertically) {
            const from = y < clip.y1 ? clip.y1 - y : 0;
            const height = lines.length;
            const to = y + height > clip.y2 ? clip.y2 - y : height;
            lines = lines.slice(from, to);
            if (y < clip.y1) {
              y = clip.y1;
            }
          }
        }
        let offsetY = 0;
        for (let [index, line] of lines.entries()) {
          const currentLine = output[y + offsetY];
          if (!currentLine) {
            continue;
          }
          for (const transformer of transformers) {
            line = transformer(line, index);
          }
          const characters = styledCharsFromTokens(tokenize2(line));
          let offsetX = x;
          for (const character of characters) {
            currentLine[offsetX] = character;
            const isWideCharacter = character.fullWidth || character.value.length > 1;
            if (isWideCharacter) {
              currentLine[offsetX + 1] = {
                type: "char",
                value: "",
                fullWidth: false,
                styles: character.styles
              };
            }
            offsetX += isWideCharacter ? 2 : 1;
          }
          offsetY++;
        }
      }
    }
    const generatedOutput = output.map((line) => {
      const lineWithoutEmptyItems = line.filter((item) => item !== void 0);
      return styledCharsToString(lineWithoutEmptyItems).trimEnd();
    }).join("\n");
    return {
      output: generatedOutput,
      height: output.length
    };
  }
};

// node_modules/ink/build/renderer.js
var renderer = (node) => {
  if (node.yogaNode) {
    const output = new Output({
      width: node.yogaNode.getComputedWidth(),
      height: node.yogaNode.getComputedHeight()
    });
    render_node_to_output_default(node, output, { skipStaticElements: true });
    let staticOutput;
    if (node.staticNode?.yogaNode) {
      staticOutput = new Output({
        width: node.staticNode.yogaNode.getComputedWidth(),
        height: node.staticNode.yogaNode.getComputedHeight()
      });
      render_node_to_output_default(node.staticNode, staticOutput, {
        skipStaticElements: false
      });
    }
    const { output: generatedOutput, height: outputHeight } = output.get();
    return {
      output: generatedOutput,
      outputHeight,
      // Newline at the end is needed, because static output doesn't have one, so
      // interactive output will override last line of static output
      staticOutput: staticOutput ? `${staticOutput.get().output}
` : ""
    };
  }
  return {
    output: "",
    outputHeight: 0,
    staticOutput: ""
  };
};
var renderer_default = renderer;

// node_modules/cli-cursor/index.js
import process6 from "process";

// node_modules/restore-cursor/index.js
var import_onetime = __toESM(require_onetime(), 1);
var import_signal_exit = __toESM(require_signal_exit(), 1);
import process5 from "process";
var restoreCursor = (0, import_onetime.default)(() => {
  (0, import_signal_exit.default)(() => {
    process5.stderr.write("\x1B[?25h");
  }, { alwaysLast: true });
});
var restore_cursor_default = restoreCursor;

// node_modules/cli-cursor/index.js
var isHidden = false;
var cliCursor = {};
cliCursor.show = (writableStream = process6.stderr) => {
  if (!writableStream.isTTY) {
    return;
  }
  isHidden = false;
  writableStream.write("\x1B[?25h");
};
cliCursor.hide = (writableStream = process6.stderr) => {
  if (!writableStream.isTTY) {
    return;
  }
  restore_cursor_default();
  isHidden = true;
  writableStream.write("\x1B[?25l");
};
cliCursor.toggle = (force, writableStream) => {
  if (force !== void 0) {
    isHidden = force;
  }
  if (isHidden) {
    cliCursor.show(writableStream);
  } else {
    cliCursor.hide(writableStream);
  }
};
var cli_cursor_default = cliCursor;

// node_modules/ink/build/log-update.js
var create = (stream, { showCursor = false } = {}) => {
  let previousLineCount = 0;
  let previousOutput = "";
  let hasHiddenCursor = false;
  const render2 = (str) => {
    if (!showCursor && !hasHiddenCursor) {
      cli_cursor_default.hide();
      hasHiddenCursor = true;
    }
    const output = str + "\n";
    if (output === previousOutput) {
      return;
    }
    previousOutput = output;
    stream.write(base_exports.eraseLines(previousLineCount) + output);
    previousLineCount = output.split("\n").length;
  };
  render2.clear = () => {
    stream.write(base_exports.eraseLines(previousLineCount));
    previousOutput = "";
    previousLineCount = 0;
  };
  render2.done = () => {
    previousOutput = "";
    previousLineCount = 0;
    if (!showCursor) {
      cli_cursor_default.show();
      hasHiddenCursor = false;
    }
  };
  return render2;
};
var logUpdate = { create };
var log_update_default = logUpdate;

// node_modules/ink/build/instances.js
var instances = /* @__PURE__ */ new WeakMap();
var instances_default = instances;

// node_modules/ink/build/components/App.js
var import_react9 = __toESM(require_react(), 1);
import { EventEmitter as EventEmitter2 } from "events";
import process10 from "process";

// node_modules/ink/build/components/AppContext.js
var import_react = __toESM(require_react(), 1);
var AppContext = (0, import_react.createContext)({
  exit() {
  }
});
AppContext.displayName = "InternalAppContext";
var AppContext_default = AppContext;

// node_modules/ink/build/components/StdinContext.js
var import_react2 = __toESM(require_react(), 1);
import { EventEmitter } from "events";
import process7 from "process";
var StdinContext = (0, import_react2.createContext)({
  stdin: process7.stdin,
  // eslint-disable-next-line @typescript-eslint/naming-convention
  internal_eventEmitter: new EventEmitter(),
  setRawMode() {
  },
  isRawModeSupported: false,
  // eslint-disable-next-line @typescript-eslint/naming-convention
  internal_exitOnCtrlC: true
});
StdinContext.displayName = "InternalStdinContext";
var StdinContext_default = StdinContext;

// node_modules/ink/build/components/StdoutContext.js
var import_react3 = __toESM(require_react(), 1);
import process8 from "process";
var StdoutContext = (0, import_react3.createContext)({
  stdout: process8.stdout,
  write() {
  }
});
StdoutContext.displayName = "InternalStdoutContext";
var StdoutContext_default = StdoutContext;

// node_modules/ink/build/components/StderrContext.js
var import_react4 = __toESM(require_react(), 1);
import process9 from "process";
var StderrContext = (0, import_react4.createContext)({
  stderr: process9.stderr,
  write() {
  }
});
StderrContext.displayName = "InternalStderrContext";
var StderrContext_default = StderrContext;

// node_modules/ink/build/components/FocusContext.js
var import_react5 = __toESM(require_react(), 1);
var FocusContext = (0, import_react5.createContext)({
  activeId: void 0,
  add() {
  },
  remove() {
  },
  activate() {
  },
  deactivate() {
  },
  enableFocus() {
  },
  disableFocus() {
  },
  focusNext() {
  },
  focusPrevious() {
  },
  focus() {
  }
});
FocusContext.displayName = "InternalFocusContext";
var FocusContext_default = FocusContext;

// node_modules/ink/build/components/ErrorOverview.js
var import_react8 = __toESM(require_react(), 1);
var import_stack_utils = __toESM(require_stack_utils(), 1);
import * as fs from "fs";
import { cwd } from "process";

// node_modules/convert-to-spaces/dist/index.js
var convertToSpaces = (input, spaces = 2) => {
  return input.replace(/^\t+/gm, ($1) => " ".repeat($1.length * spaces));
};
var dist_default2 = convertToSpaces;

// node_modules/code-excerpt/dist/index.js
var generateLineNumbers = (line, around) => {
  const lineNumbers = [];
  const min = line - around;
  const max = line + around;
  for (let lineNumber = min; lineNumber <= max; lineNumber++) {
    lineNumbers.push(lineNumber);
  }
  return lineNumbers;
};
var codeExcerpt = (source, line, options = {}) => {
  var _a;
  if (typeof source !== "string") {
    throw new TypeError("Source code is missing.");
  }
  if (!line || line < 1) {
    throw new TypeError("Line number must start from `1`.");
  }
  const lines = dist_default2(source).split(/\r?\n/);
  if (line > lines.length) {
    return;
  }
  return generateLineNumbers(line, (_a = options.around) !== null && _a !== void 0 ? _a : 3).filter((line2) => lines[line2 - 1] !== void 0).map((line2) => ({ line: line2, value: lines[line2 - 1] }));
};
var dist_default3 = codeExcerpt;

// node_modules/ink/build/components/Box.js
var import_react6 = __toESM(require_react(), 1);
var Box = (0, import_react6.forwardRef)(({ children, ...style }, ref) => {
  return import_react6.default.createElement("ink-box", { ref, style: {
    ...style,
    overflowX: style.overflowX ?? style.overflow ?? "visible",
    overflowY: style.overflowY ?? style.overflow ?? "visible"
  } }, children);
});
Box.displayName = "Box";
Box.defaultProps = {
  flexWrap: "nowrap",
  flexDirection: "row",
  flexGrow: 0,
  flexShrink: 1
};
var Box_default = Box;

// node_modules/ink/build/components/Text.js
var import_react7 = __toESM(require_react(), 1);
function Text({ color, backgroundColor, dimColor = false, bold = false, italic = false, underline = false, strikethrough = false, inverse = false, wrap = "wrap", children }) {
  if (children === void 0 || children === null) {
    return null;
  }
  const transform = (children2) => {
    if (dimColor) {
      children2 = source_default.dim(children2);
    }
    if (color) {
      children2 = colorize_default(children2, color, "foreground");
    }
    if (backgroundColor) {
      children2 = colorize_default(children2, backgroundColor, "background");
    }
    if (bold) {
      children2 = source_default.bold(children2);
    }
    if (italic) {
      children2 = source_default.italic(children2);
    }
    if (underline) {
      children2 = source_default.underline(children2);
    }
    if (strikethrough) {
      children2 = source_default.strikethrough(children2);
    }
    if (inverse) {
      children2 = source_default.inverse(children2);
    }
    return children2;
  };
  return import_react7.default.createElement("ink-text", { style: { flexGrow: 0, flexShrink: 1, flexDirection: "row", textWrap: wrap }, internal_transform: transform }, children);
}

// node_modules/ink/build/components/ErrorOverview.js
var cleanupPath = (path) => {
  return path?.replace(`file://${cwd()}/`, "");
};
var stackUtils = new import_stack_utils.default({
  cwd: cwd(),
  internals: import_stack_utils.default.nodeInternals()
});
function ErrorOverview({ error }) {
  const stack = error.stack ? error.stack.split("\n").slice(1) : void 0;
  const origin = stack ? stackUtils.parseLine(stack[0]) : void 0;
  const filePath = cleanupPath(origin?.file);
  let excerpt;
  let lineWidth = 0;
  if (filePath && origin?.line && fs.existsSync(filePath)) {
    const sourceCode = fs.readFileSync(filePath, "utf8");
    excerpt = dist_default3(sourceCode, origin.line);
    if (excerpt) {
      for (const { line } of excerpt) {
        lineWidth = Math.max(lineWidth, String(line).length);
      }
    }
  }
  return import_react8.default.createElement(
    Box_default,
    { flexDirection: "column", padding: 1 },
    import_react8.default.createElement(
      Box_default,
      null,
      import_react8.default.createElement(
        Text,
        { backgroundColor: "red", color: "white" },
        " ",
        "ERROR",
        " "
      ),
      import_react8.default.createElement(
        Text,
        null,
        " ",
        error.message
      )
    ),
    origin && filePath && import_react8.default.createElement(
      Box_default,
      { marginTop: 1 },
      import_react8.default.createElement(
        Text,
        { dimColor: true },
        filePath,
        ":",
        origin.line,
        ":",
        origin.column
      )
    ),
    origin && excerpt && import_react8.default.createElement(Box_default, { marginTop: 1, flexDirection: "column" }, excerpt.map(({ line, value }) => import_react8.default.createElement(
      Box_default,
      { key: line },
      import_react8.default.createElement(
        Box_default,
        { width: lineWidth + 1 },
        import_react8.default.createElement(
          Text,
          { dimColor: line !== origin.line, backgroundColor: line === origin.line ? "red" : void 0, color: line === origin.line ? "white" : void 0 },
          String(line).padStart(lineWidth, " "),
          ":"
        )
      ),
      import_react8.default.createElement(Text, { key: line, backgroundColor: line === origin.line ? "red" : void 0, color: line === origin.line ? "white" : void 0 }, " " + value)
    ))),
    error.stack && import_react8.default.createElement(Box_default, { marginTop: 1, flexDirection: "column" }, error.stack.split("\n").slice(1).map((line) => {
      const parsedLine = stackUtils.parseLine(line);
      if (!parsedLine) {
        return import_react8.default.createElement(
          Box_default,
          { key: line },
          import_react8.default.createElement(Text, { dimColor: true }, "- "),
          import_react8.default.createElement(Text, { dimColor: true, bold: true }, line)
        );
      }
      return import_react8.default.createElement(
        Box_default,
        { key: line },
        import_react8.default.createElement(Text, { dimColor: true }, "- "),
        import_react8.default.createElement(Text, { dimColor: true, bold: true }, parsedLine.function),
        import_react8.default.createElement(
          Text,
          { dimColor: true, color: "gray" },
          " ",
          "(",
          cleanupPath(parsedLine.file) ?? "",
          ":",
          parsedLine.line,
          ":",
          parsedLine.column,
          ")"
        )
      );
    }))
  );
}

// node_modules/ink/build/components/App.js
var tab = "	";
var shiftTab = "\x1B[Z";
var escape = "\x1B";
var App = class extends import_react9.PureComponent {
  static displayName = "InternalApp";
  static getDerivedStateFromError(error) {
    return { error };
  }
  state = {
    isFocusEnabled: true,
    activeFocusId: void 0,
    focusables: [],
    error: void 0
  };
  // Count how many components enabled raw mode to avoid disabling
  // raw mode until all components don't need it anymore
  rawModeEnabledCount = 0;
  // eslint-disable-next-line @typescript-eslint/naming-convention
  internal_eventEmitter = new EventEmitter2();
  // Determines if TTY is supported on the provided stdin
  isRawModeSupported() {
    return this.props.stdin.isTTY;
  }
  render() {
    return import_react9.default.createElement(
      AppContext_default.Provider,
      {
        // eslint-disable-next-line react/jsx-no-constructed-context-values
        value: {
          exit: this.handleExit
        }
      },
      import_react9.default.createElement(
        StdinContext_default.Provider,
        {
          // eslint-disable-next-line react/jsx-no-constructed-context-values
          value: {
            stdin: this.props.stdin,
            setRawMode: this.handleSetRawMode,
            isRawModeSupported: this.isRawModeSupported(),
            // eslint-disable-next-line @typescript-eslint/naming-convention
            internal_exitOnCtrlC: this.props.exitOnCtrlC,
            // eslint-disable-next-line @typescript-eslint/naming-convention
            internal_eventEmitter: this.internal_eventEmitter
          }
        },
        import_react9.default.createElement(
          StdoutContext_default.Provider,
          {
            // eslint-disable-next-line react/jsx-no-constructed-context-values
            value: {
              stdout: this.props.stdout,
              write: this.props.writeToStdout
            }
          },
          import_react9.default.createElement(
            StderrContext_default.Provider,
            {
              // eslint-disable-next-line react/jsx-no-constructed-context-values
              value: {
                stderr: this.props.stderr,
                write: this.props.writeToStderr
              }
            },
            import_react9.default.createElement(
              FocusContext_default.Provider,
              {
                // eslint-disable-next-line react/jsx-no-constructed-context-values
                value: {
                  activeId: this.state.activeFocusId,
                  add: this.addFocusable,
                  remove: this.removeFocusable,
                  activate: this.activateFocusable,
                  deactivate: this.deactivateFocusable,
                  enableFocus: this.enableFocus,
                  disableFocus: this.disableFocus,
                  focusNext: this.focusNext,
                  focusPrevious: this.focusPrevious,
                  focus: this.focus
                }
              },
              this.state.error ? import_react9.default.createElement(ErrorOverview, { error: this.state.error }) : this.props.children
            )
          )
        )
      )
    );
  }
  componentDidMount() {
    cli_cursor_default.hide(this.props.stdout);
  }
  componentWillUnmount() {
    cli_cursor_default.show(this.props.stdout);
    if (this.isRawModeSupported()) {
      this.handleSetRawMode(false);
    }
  }
  componentDidCatch(error) {
    this.handleExit(error);
  }
  handleSetRawMode = (isEnabled) => {
    const { stdin } = this.props;
    if (!this.isRawModeSupported()) {
      if (stdin === process10.stdin) {
        throw new Error("Raw mode is not supported on the current process.stdin, which Ink uses as input stream by default.\nRead about how to prevent this error on https://github.com/vadimdemedes/ink/#israwmodesupported");
      } else {
        throw new Error("Raw mode is not supported on the stdin provided to Ink.\nRead about how to prevent this error on https://github.com/vadimdemedes/ink/#israwmodesupported");
      }
    }
    stdin.setEncoding("utf8");
    if (isEnabled) {
      if (this.rawModeEnabledCount === 0) {
        stdin.ref();
        stdin.setRawMode(true);
        stdin.addListener("readable", this.handleReadable);
      }
      this.rawModeEnabledCount++;
      return;
    }
    if (--this.rawModeEnabledCount === 0) {
      stdin.setRawMode(false);
      stdin.removeListener("readable", this.handleReadable);
      stdin.unref();
    }
  };
  handleReadable = () => {
    let chunk;
    while ((chunk = this.props.stdin.read()) !== null) {
      this.handleInput(chunk);
      this.internal_eventEmitter.emit("input", chunk);
    }
  };
  handleInput = (input) => {
    if (input === "" && this.props.exitOnCtrlC) {
      this.handleExit();
    }
    if (input === escape && this.state.activeFocusId) {
      this.setState({
        activeFocusId: void 0
      });
    }
    if (this.state.isFocusEnabled && this.state.focusables.length > 0) {
      if (input === tab) {
        this.focusNext();
      }
      if (input === shiftTab) {
        this.focusPrevious();
      }
    }
  };
  handleExit = (error) => {
    if (this.isRawModeSupported()) {
      this.handleSetRawMode(false);
    }
    this.props.onExit(error);
  };
  enableFocus = () => {
    this.setState({
      isFocusEnabled: true
    });
  };
  disableFocus = () => {
    this.setState({
      isFocusEnabled: false
    });
  };
  focus = (id) => {
    this.setState((previousState) => {
      const hasFocusableId = previousState.focusables.some((focusable) => focusable?.id === id);
      if (!hasFocusableId) {
        return previousState;
      }
      return { activeFocusId: id };
    });
  };
  focusNext = () => {
    this.setState((previousState) => {
      const firstFocusableId = previousState.focusables.find((focusable) => focusable.isActive)?.id;
      const nextFocusableId = this.findNextFocusable(previousState);
      return {
        activeFocusId: nextFocusableId ?? firstFocusableId
      };
    });
  };
  focusPrevious = () => {
    this.setState((previousState) => {
      const lastFocusableId = previousState.focusables.findLast((focusable) => focusable.isActive)?.id;
      const previousFocusableId = this.findPreviousFocusable(previousState);
      return {
        activeFocusId: previousFocusableId ?? lastFocusableId
      };
    });
  };
  addFocusable = (id, { autoFocus }) => {
    this.setState((previousState) => {
      let nextFocusId = previousState.activeFocusId;
      if (!nextFocusId && autoFocus) {
        nextFocusId = id;
      }
      return {
        activeFocusId: nextFocusId,
        focusables: [
          ...previousState.focusables,
          {
            id,
            isActive: true
          }
        ]
      };
    });
  };
  removeFocusable = (id) => {
    this.setState((previousState) => ({
      activeFocusId: previousState.activeFocusId === id ? void 0 : previousState.activeFocusId,
      focusables: previousState.focusables.filter((focusable) => {
        return focusable.id !== id;
      })
    }));
  };
  activateFocusable = (id) => {
    this.setState((previousState) => ({
      focusables: previousState.focusables.map((focusable) => {
        if (focusable.id !== id) {
          return focusable;
        }
        return {
          id,
          isActive: true
        };
      })
    }));
  };
  deactivateFocusable = (id) => {
    this.setState((previousState) => ({
      activeFocusId: previousState.activeFocusId === id ? void 0 : previousState.activeFocusId,
      focusables: previousState.focusables.map((focusable) => {
        if (focusable.id !== id) {
          return focusable;
        }
        return {
          id,
          isActive: false
        };
      })
    }));
  };
  findNextFocusable = (state) => {
    const activeIndex = state.focusables.findIndex((focusable) => {
      return focusable.id === state.activeFocusId;
    });
    for (let index = activeIndex + 1; index < state.focusables.length; index++) {
      const focusable = state.focusables[index];
      if (focusable?.isActive) {
        return focusable.id;
      }
    }
    return void 0;
  };
  findPreviousFocusable = (state) => {
    const activeIndex = state.focusables.findIndex((focusable) => {
      return focusable.id === state.activeFocusId;
    });
    for (let index = activeIndex - 1; index >= 0; index--) {
      const focusable = state.focusables[index];
      if (focusable?.isActive) {
        return focusable.id;
      }
    }
    return void 0;
  };
};

// node_modules/ink/build/ink.js
var noop = () => {
};
var Ink = class {
  options;
  log;
  throttledLog;
  // Ignore last render after unmounting a tree to prevent empty output before exit
  isUnmounted;
  lastOutput;
  container;
  rootNode;
  // This variable is used only in debug mode to store full static output
  // so that it's rerendered every time, not just new static parts, like in non-debug mode
  fullStaticOutput;
  exitPromise;
  restoreConsole;
  unsubscribeResize;
  constructor(options) {
    autoBind(this);
    this.options = options;
    this.rootNode = createNode("ink-root");
    this.rootNode.onComputeLayout = this.calculateLayout;
    this.rootNode.onRender = options.debug ? this.onRender : throttle(this.onRender, 32, {
      leading: true,
      trailing: true
    });
    this.rootNode.onImmediateRender = this.onRender;
    this.log = log_update_default.create(options.stdout);
    this.throttledLog = options.debug ? this.log : throttle(this.log, void 0, {
      leading: true,
      trailing: true
    });
    this.isUnmounted = false;
    this.lastOutput = "";
    this.fullStaticOutput = "";
    this.container = reconciler_default.createContainer(
      this.rootNode,
      // Legacy mode
      0,
      null,
      false,
      null,
      "id",
      () => {
      },
      null
    );
    this.unsubscribeExit = (0, import_signal_exit2.default)(this.unmount, { alwaysLast: false });
    if (process11.env["DEV"] === "true") {
      reconciler_default.injectIntoDevTools({
        bundleType: 0,
        // Reporting React DOM's version, not Ink's
        // See https://github.com/facebook/react/issues/16666#issuecomment-532639905
        version: "16.13.1",
        rendererPackageName: "ink"
      });
    }
    if (options.patchConsole) {
      this.patchConsole();
    }
    if (!is_in_ci_default) {
      options.stdout.on("resize", this.resized);
      this.unsubscribeResize = () => {
        options.stdout.off("resize", this.resized);
      };
    }
  }
  resized = () => {
    this.calculateLayout();
    this.onRender();
  };
  resolveExitPromise = () => {
  };
  rejectExitPromise = () => {
  };
  unsubscribeExit = () => {
  };
  calculateLayout = () => {
    const terminalWidth = this.options.stdout.columns || 80;
    this.rootNode.yogaNode.setWidth(terminalWidth);
    this.rootNode.yogaNode.calculateLayout(void 0, void 0, src_default.DIRECTION_LTR);
  };
  onRender = () => {
    if (this.isUnmounted) {
      return;
    }
    const { output, outputHeight, staticOutput } = renderer_default(this.rootNode);
    const hasStaticOutput = staticOutput && staticOutput !== "\n";
    if (this.options.debug) {
      if (hasStaticOutput) {
        this.fullStaticOutput += staticOutput;
      }
      this.options.stdout.write(this.fullStaticOutput + output);
      return;
    }
    if (is_in_ci_default) {
      if (hasStaticOutput) {
        this.options.stdout.write(staticOutput);
      }
      this.lastOutput = output;
      return;
    }
    if (hasStaticOutput) {
      this.fullStaticOutput += staticOutput;
    }
    if (outputHeight >= this.options.stdout.rows) {
      this.options.stdout.write(base_exports.clearTerminal + this.fullStaticOutput + output);
      this.lastOutput = output;
      return;
    }
    if (hasStaticOutput) {
      this.log.clear();
      this.options.stdout.write(staticOutput);
      this.log(output);
    }
    if (!hasStaticOutput && output !== this.lastOutput) {
      this.throttledLog(output);
    }
    this.lastOutput = output;
  };
  render(node) {
    const tree = import_react10.default.createElement(App, { stdin: this.options.stdin, stdout: this.options.stdout, stderr: this.options.stderr, writeToStdout: this.writeToStdout, writeToStderr: this.writeToStderr, exitOnCtrlC: this.options.exitOnCtrlC, onExit: this.unmount }, node);
    reconciler_default.updateContainer(tree, this.container, null, noop);
  }
  writeToStdout(data) {
    if (this.isUnmounted) {
      return;
    }
    if (this.options.debug) {
      this.options.stdout.write(data + this.fullStaticOutput + this.lastOutput);
      return;
    }
    if (is_in_ci_default) {
      this.options.stdout.write(data);
      return;
    }
    this.log.clear();
    this.options.stdout.write(data);
    this.log(this.lastOutput);
  }
  writeToStderr(data) {
    if (this.isUnmounted) {
      return;
    }
    if (this.options.debug) {
      this.options.stderr.write(data);
      this.options.stdout.write(this.fullStaticOutput + this.lastOutput);
      return;
    }
    if (is_in_ci_default) {
      this.options.stderr.write(data);
      return;
    }
    this.log.clear();
    this.options.stderr.write(data);
    this.log(this.lastOutput);
  }
  // eslint-disable-next-line @typescript-eslint/ban-types
  unmount(error) {
    if (this.isUnmounted) {
      return;
    }
    this.calculateLayout();
    this.onRender();
    this.unsubscribeExit();
    if (typeof this.restoreConsole === "function") {
      this.restoreConsole();
    }
    if (typeof this.unsubscribeResize === "function") {
      this.unsubscribeResize();
    }
    if (is_in_ci_default) {
      this.options.stdout.write(this.lastOutput + "\n");
    } else if (!this.options.debug) {
      this.log.done();
    }
    this.isUnmounted = true;
    reconciler_default.updateContainer(null, this.container, null, noop);
    instances_default.delete(this.options.stdout);
    if (error instanceof Error) {
      this.rejectExitPromise(error);
    } else {
      this.resolveExitPromise();
    }
  }
  async waitUntilExit() {
    this.exitPromise ||= new Promise((resolve, reject) => {
      this.resolveExitPromise = resolve;
      this.rejectExitPromise = reject;
    });
    return this.exitPromise;
  }
  clear() {
    if (!is_in_ci_default && !this.options.debug) {
      this.log.clear();
    }
  }
  patchConsole() {
    if (this.options.debug) {
      return;
    }
    this.restoreConsole = dist_default((stream, data) => {
      if (stream === "stdout") {
        this.writeToStdout(data);
      }
      if (stream === "stderr") {
        const isReactMessage = data.startsWith("The above error occurred");
        if (!isReactMessage) {
          this.writeToStderr(data);
        }
      }
    });
  }
};

// node_modules/ink/build/render.js
var render = (node, options) => {
  const inkOptions = {
    stdout: process12.stdout,
    stdin: process12.stdin,
    stderr: process12.stderr,
    debug: false,
    exitOnCtrlC: true,
    patchConsole: true,
    ...getOptions(options)
  };
  const instance = getInstance(inkOptions.stdout, () => new Ink(inkOptions));
  instance.render(node);
  return {
    rerender: instance.render,
    unmount() {
      instance.unmount();
    },
    waitUntilExit: instance.waitUntilExit,
    cleanup: () => instances_default.delete(inkOptions.stdout),
    clear: instance.clear
  };
};
var render_default = render;
var getOptions = (stdout = {}) => {
  if (stdout instanceof Stream) {
    return {
      stdout,
      stdin: process12.stdin
    };
  }
  return stdout;
};
var getInstance = (stdout, createInstance) => {
  let instance = instances_default.get(stdout);
  if (!instance) {
    instance = createInstance();
    instances_default.set(stdout, instance);
  }
  return instance;
};

// node_modules/ink/build/components/Static.js
var import_react11 = __toESM(require_react(), 1);

// node_modules/ink/build/components/Transform.js
var import_react12 = __toESM(require_react(), 1);

// node_modules/ink/build/components/Newline.js
var import_react13 = __toESM(require_react(), 1);

// node_modules/ink/build/components/Spacer.js
var import_react14 = __toESM(require_react(), 1);

// node_modules/ink/build/hooks/use-input.js
var import_react16 = __toESM(require_react(), 1);

// node_modules/ink/build/parse-keypress.js
import { Buffer as Buffer2 } from "buffer";
var metaKeyCodeRe = /^(?:\x1b)([a-zA-Z0-9])$/;
var fnKeyRe = /^(?:\x1b+)(O|N|\[|\[\[)(?:(\d+)(?:;(\d+))?([~^$])|(?:1;)?(\d+)?([a-zA-Z]))/;
var keyName = {
  /* xterm/gnome ESC O letter */
  OP: "f1",
  OQ: "f2",
  OR: "f3",
  OS: "f4",
  /* xterm/rxvt ESC [ number ~ */
  "[11~": "f1",
  "[12~": "f2",
  "[13~": "f3",
  "[14~": "f4",
  /* from Cygwin and used in libuv */
  "[[A": "f1",
  "[[B": "f2",
  "[[C": "f3",
  "[[D": "f4",
  "[[E": "f5",
  /* common */
  "[15~": "f5",
  "[17~": "f6",
  "[18~": "f7",
  "[19~": "f8",
  "[20~": "f9",
  "[21~": "f10",
  "[23~": "f11",
  "[24~": "f12",
  /* xterm ESC [ letter */
  "[A": "up",
  "[B": "down",
  "[C": "right",
  "[D": "left",
  "[E": "clear",
  "[F": "end",
  "[H": "home",
  /* xterm/gnome ESC O letter */
  OA: "up",
  OB: "down",
  OC: "right",
  OD: "left",
  OE: "clear",
  OF: "end",
  OH: "home",
  /* xterm/rxvt ESC [ number ~ */
  "[1~": "home",
  "[2~": "insert",
  "[3~": "delete",
  "[4~": "end",
  "[5~": "pageup",
  "[6~": "pagedown",
  /* putty */
  "[[5~": "pageup",
  "[[6~": "pagedown",
  /* rxvt */
  "[7~": "home",
  "[8~": "end",
  /* rxvt keys with modifiers */
  "[a": "up",
  "[b": "down",
  "[c": "right",
  "[d": "left",
  "[e": "clear",
  "[2$": "insert",
  "[3$": "delete",
  "[5$": "pageup",
  "[6$": "pagedown",
  "[7$": "home",
  "[8$": "end",
  Oa: "up",
  Ob: "down",
  Oc: "right",
  Od: "left",
  Oe: "clear",
  "[2^": "insert",
  "[3^": "delete",
  "[5^": "pageup",
  "[6^": "pagedown",
  "[7^": "home",
  "[8^": "end",
  /* misc. */
  "[Z": "tab"
};
var nonAlphanumericKeys = [...Object.values(keyName), "backspace"];
var isShiftKey = (code) => {
  return [
    "[a",
    "[b",
    "[c",
    "[d",
    "[e",
    "[2$",
    "[3$",
    "[5$",
    "[6$",
    "[7$",
    "[8$",
    "[Z"
  ].includes(code);
};
var isCtrlKey = (code) => {
  return [
    "Oa",
    "Ob",
    "Oc",
    "Od",
    "Oe",
    "[2^",
    "[3^",
    "[5^",
    "[6^",
    "[7^",
    "[8^"
  ].includes(code);
};
var parseKeypress = (s = "") => {
  let parts;
  if (Buffer2.isBuffer(s)) {
    if (s[0] > 127 && s[1] === void 0) {
      s[0] -= 128;
      s = "\x1B" + String(s);
    } else {
      s = String(s);
    }
  } else if (s !== void 0 && typeof s !== "string") {
    s = String(s);
  } else if (!s) {
    s = "";
  }
  const key = {
    name: "",
    ctrl: false,
    meta: false,
    shift: false,
    option: false,
    sequence: s,
    raw: s
  };
  key.sequence = key.sequence || s || key.name;
  if (s === "\r") {
    key.raw = void 0;
    key.name = "return";
  } else if (s === "\n") {
    key.name = "enter";
  } else if (s === "	") {
    key.name = "tab";
  } else if (s === "\b" || s === "\x1B\b") {
    key.name = "backspace";
    key.meta = s.charAt(0) === "\x1B";
  } else if (s === "\x7F" || s === "\x1B\x7F") {
    key.name = "delete";
    key.meta = s.charAt(0) === "\x1B";
  } else if (s === "\x1B" || s === "\x1B\x1B") {
    key.name = "escape";
    key.meta = s.length === 2;
  } else if (s === " " || s === "\x1B ") {
    key.name = "space";
    key.meta = s.length === 2;
  } else if (s.length === 1 && s <= "") {
    key.name = String.fromCharCode(s.charCodeAt(0) + "a".charCodeAt(0) - 1);
    key.ctrl = true;
  } else if (s.length === 1 && s >= "0" && s <= "9") {
    key.name = "number";
  } else if (s.length === 1 && s >= "a" && s <= "z") {
    key.name = s;
  } else if (s.length === 1 && s >= "A" && s <= "Z") {
    key.name = s.toLowerCase();
    key.shift = true;
  } else if (parts = metaKeyCodeRe.exec(s)) {
    key.meta = true;
    key.shift = /^[A-Z]$/.test(parts[1]);
  } else if (parts = fnKeyRe.exec(s)) {
    const segs = [...s];
    if (segs[0] === "\x1B" && segs[1] === "\x1B") {
      key.option = true;
    }
    const code = [parts[1], parts[2], parts[4], parts[6]].filter(Boolean).join("");
    const modifier = (parts[3] || parts[5] || 1) - 1;
    key.ctrl = !!(modifier & 4);
    key.meta = !!(modifier & 10);
    key.shift = !!(modifier & 1);
    key.code = code;
    key.name = keyName[code];
    key.shift = isShiftKey(code) || key.shift;
    key.ctrl = isCtrlKey(code) || key.ctrl;
  }
  return key;
};
var parse_keypress_default = parseKeypress;

// node_modules/ink/build/hooks/use-stdin.js
var import_react15 = __toESM(require_react(), 1);
var useStdin = () => (0, import_react15.useContext)(StdinContext_default);
var use_stdin_default = useStdin;

// node_modules/ink/build/hooks/use-input.js
var useInput = (inputHandler, options = {}) => {
  const { stdin, setRawMode, internal_exitOnCtrlC, internal_eventEmitter } = use_stdin_default();
  (0, import_react16.useEffect)(() => {
    if (options.isActive === false) {
      return;
    }
    setRawMode(true);
    return () => {
      setRawMode(false);
    };
  }, [options.isActive, setRawMode]);
  (0, import_react16.useEffect)(() => {
    if (options.isActive === false) {
      return;
    }
    const handleData = (data) => {
      const keypress = parse_keypress_default(data);
      const key = {
        upArrow: keypress.name === "up",
        downArrow: keypress.name === "down",
        leftArrow: keypress.name === "left",
        rightArrow: keypress.name === "right",
        pageDown: keypress.name === "pagedown",
        pageUp: keypress.name === "pageup",
        return: keypress.name === "return",
        escape: keypress.name === "escape",
        ctrl: keypress.ctrl,
        shift: keypress.shift,
        tab: keypress.name === "tab",
        backspace: keypress.name === "backspace",
        delete: keypress.name === "delete",
        // `parseKeypress` parses \u001B\u001B[A (meta + up arrow) as meta = false
        // but with option = true, so we need to take this into account here
        // to avoid breaking changes in Ink.
        // TODO(vadimdemedes): consider removing this in the next major version.
        meta: keypress.meta || keypress.name === "escape" || keypress.option
      };
      let input = keypress.ctrl ? keypress.name : keypress.sequence;
      if (nonAlphanumericKeys.includes(keypress.name)) {
        input = "";
      }
      if (input.startsWith("\x1B")) {
        input = input.slice(1);
      }
      if (input.length === 1 && typeof input[0] === "string" && /[A-Z]/.test(input[0])) {
        key.shift = true;
      }
      if (!(input === "c" && key.ctrl) || !internal_exitOnCtrlC) {
        reconciler_default.batchedUpdates(() => {
          inputHandler(input, key);
        });
      }
    };
    internal_eventEmitter?.on("input", handleData);
    return () => {
      internal_eventEmitter?.removeListener("input", handleData);
    };
  }, [options.isActive, stdin, internal_exitOnCtrlC, inputHandler]);
};
var use_input_default = useInput;

// node_modules/ink/build/hooks/use-app.js
var import_react17 = __toESM(require_react(), 1);

// node_modules/ink/build/hooks/use-stdout.js
var import_react18 = __toESM(require_react(), 1);
var useStdout = () => (0, import_react18.useContext)(StdoutContext_default);
var use_stdout_default = useStdout;

// node_modules/ink/build/hooks/use-stderr.js
var import_react19 = __toESM(require_react(), 1);

// node_modules/ink/build/hooks/use-focus.js
var import_react20 = __toESM(require_react(), 1);

// node_modules/ink/build/hooks/use-focus-manager.js
var import_react21 = __toESM(require_react(), 1);

// src/index.tsx
import { openSync } from "fs";
import { ReadStream } from "tty";

// src/App.tsx
var import_react25 = __toESM(require_react(), 1);

// src/components/CostMeter.tsx
var import_jsx_runtime = __toESM(require_jsx_runtime(), 1);
function formatCost(usd) {
  return `$${usd.toFixed(2)}`;
}
function CostMeter({ completed, total, costUsd, budget, width }) {
  const barWidth = Math.max(10, width - 40);
  const ratio = total > 0 ? Math.min(completed / total, 1) : 0;
  const filled = Math.round(barWidth * ratio);
  const empty = barWidth - filled;
  const overBudget = budget > 0 && costUsd > budget;
  const barColor = overBudget ? "red" : "green";
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Box_default, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Text, { color: barColor, children: "\u2588".repeat(filled) }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Text, { dimColor: true, children: "\u2591".repeat(empty) }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Text, { children: [
      " ",
      completed,
      " / ",
      total
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Text, { dimColor: true, children: [
      "  ",
      formatCost(costUsd),
      " / ",
      formatCost(budget),
      " budget"
    ] })
  ] });
}

// src/components/Header.tsx
var import_jsx_runtime2 = __toESM(require_jsx_runtime(), 1);
function Header({ state, terminalWidth }) {
  const { runId, autonomy, model, agent, source, featureCount, budget, features, totals } = state;
  const completed = totals.succeeded + totals.failed + totals.skipped;
  const totalCost = totals.costUsd;
  const sourceLabel = source || "unknown";
  const innerWidth = Math.max(20, terminalWidth - 2);
  const runLabel = runId ? `run ${runId.slice(0, 8)}` : "run \u2014";
  const titleLeft = " monozukuri ";
  const titleRight = ` ${runLabel} `;
  const dashes = "\u2500".repeat(Math.max(0, innerWidth - titleLeft.length - titleRight.length));
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Box_default, { flexDirection: "column", children: [
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "\u250C\u2500" }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { bold: true, children: titleLeft }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { dimColor: true, children: dashes }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: titleRight }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "\u2500\u2500\u2510" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Box_default, { paddingLeft: 1, paddingRight: 1, children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "\u2502" }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: " autonomy: " }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { color: "cyan", children: autonomy || "\u2014" }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "   model: " }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { color: "yellow", children: model || "\u2014" }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "   agent: " }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { color: "green", children: agent || "\u2014" }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "   source: " }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { color: "magenta", children: sourceLabel }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: " \u2502" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Box_default, { paddingLeft: 1, children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: "\u2502  " }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(
        CostMeter,
        {
          completed,
          total: featureCount || Object.keys(features).length,
          costUsd: totalCost,
          budget,
          width: innerWidth
        }
      ),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Text, { children: " \u2502" })
    ] })
  ] });
}

// src/components/PhaseTimeline.tsx
var import_jsx_runtime3 = __toESM(require_jsx_runtime(), 1);
var PHASE_LABELS = {
  prd: "PRD",
  techspec: "TechSpec",
  tasks: "Tasks",
  code: "Code",
  tests: "Tests",
  pr: "PR"
};
var PHASES = ["prd", "techspec", "tasks", "code", "tests", "pr"];
function PhaseDot({ status, label }) {
  switch (status) {
    case "done":
      return /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)(Box_default, { marginRight: 1, children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { color: "green", children: "\u25CF " }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { children: label })
      ] });
    case "in_progress":
      return /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)(Box_default, { marginRight: 1, children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { color: "yellow", children: "\u25D0 " }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { color: "yellow", children: label })
      ] });
    case "failed":
      return /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)(Box_default, { marginRight: 1, children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { color: "red", children: "\u2717 " }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { color: "red", children: label })
      ] });
    case "pending":
    default:
      return /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)(Box_default, { marginRight: 1, children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { dimColor: true, children: "\u25CB " }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Text, { dimColor: true, children: label })
      ] });
  }
}
function PhaseTimeline({ phases }) {
  return /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(Box_default, { flexDirection: "row", children: PHASES.map((phase) => /* @__PURE__ */ (0, import_jsx_runtime3.jsx)(PhaseDot, { status: phases[phase], label: PHASE_LABELS[phase] }, phase)) });
}

// src/components/FeatureCard.tsx
var import_jsx_runtime4 = __toESM(require_jsx_runtime(), 1);
function formatElapsed(startedAt, now) {
  if (!startedAt) return "\u2014";
  const start = new Date(startedAt).getTime();
  const elapsed = Math.max(0, Math.floor((now.getTime() - start) / 1e3));
  const m = Math.floor(elapsed / 60);
  const s = elapsed % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}
function formatTokens(tokens) {
  if (tokens === void 0) return "\u2014";
  if (tokens >= 1e3) return `${Math.round(tokens / 1e3)}k`;
  return String(tokens);
}
function truncate(str, maxLen) {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + "\u2026";
}
function WaitingCard(_props) {
  return /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Box_default, { flexDirection: "column", paddingLeft: 2, paddingY: 1, children: /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: "waiting for run..." }) });
}
function FeatureCard({ feature, spinner, now }) {
  if (!feature) {
    return /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(WaitingCard, {});
  }
  if (feature.status === "deferred") {
    const reason = feature.error ?? "no reason given";
    return /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { flexDirection: "column", paddingLeft: 1, children: [
      /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502 " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: "yellow", children: "\u23F8 " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { bold: true, color: "yellow", children: feature.id }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "  " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: truncate(feature.title || feature.id, 42) }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502   " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: "yellow", children: "deferred: " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: truncate(reason, 50) }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
      ] })
    ] });
  }
  const elapsed = formatElapsed(feature.startedAt, now);
  const tokens = formatTokens(feature.tokens);
  const estTokens = feature.estimatedTokens ? formatTokens(feature.estimatedTokens) : "~?";
  const title = truncate(feature.title || feature.id, 42);
  const spinnerText = spinner ? truncate(spinner, 50) : "";
  return /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { flexDirection: "column", paddingLeft: 1, children: [
    /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502 " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: "cyan", children: "\u25B8 " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { bold: true, color: "cyan", children: feature.id }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "  " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: title }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: "  elapsed: " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: "yellow", children: elapsed }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
    ] }),
    feature.currentSkill && /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502   " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: "skill: " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: feature.compaction && feature.compaction !== "none" ? "yellow" : "green", children: feature.currentSkill }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: " \xB7 tier " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: feature.currentTier ?? "\u2014" }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: " \xB7 mem: " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: feature.compaction && feature.compaction !== "none" ? "yellow" : "green", children: feature.compaction && feature.compaction !== "none" ? `compaction:${feature.compaction}` : "ok" }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502   " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(PhaseTimeline, { phases: feature.phases }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: "\u2502   " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: "tokens: " }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: tokens }),
      /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(Text, { dimColor: true, children: [
        " / ",
        estTokens,
        " est."
      ] }),
      spinnerText ? /* @__PURE__ */ (0, import_jsx_runtime4.jsxs)(import_jsx_runtime4.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { dimColor: true, children: "   " }),
        /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { color: "yellow", children: spinnerText })
      ] }) : null,
      /* @__PURE__ */ (0, import_jsx_runtime4.jsx)(Text, { children: " \u2502" })
    ] })
  ] });
}

// src/components/FeatureList.tsx
var import_jsx_runtime5 = __toESM(require_jsx_runtime(), 1);
function truncate2(str, maxLen) {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + "\u2026";
}
function FeatureList({
  features,
  order,
  terminalWidth
}) {
  const queued = [];
  const done = [];
  for (const id of order) {
    const f = features[id];
    if (!f) continue;
    if (f.status === "queued") {
      queued.push(f);
    } else if (f.status === "done" || f.status === "failed" || f.status === "skipped" || f.status === "deferred") {
      done.push(f);
    }
  }
  const halfWidth = Math.max(10, Math.floor((terminalWidth - 4) / 2));
  const maxTitleLen = Math.max(8, halfWidth - 20);
  const maxRows = Math.max(queued.length, done.length, 1);
  const rows = [];
  const queueDashes = "\u2500".repeat(Math.max(0, halfWidth - 8));
  const doneDashes = "\u2500".repeat(Math.max(0, halfWidth - 8));
  rows.push(
    /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u251C\u2500 queue " }),
      /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: queueDashes }),
      /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u252C\u2500 done " }),
      /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: doneDashes }),
      /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2500\u2500\u2524" })
    ] }, "header")
  );
  for (let i = 0; i < maxRows; i++) {
    const qf = queued[i];
    const df = done[i];
    rows.push(
      /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
        qf ? /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { width: halfWidth, children: [
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502  " }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: truncate2(qf.id, 10) }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "  " }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: truncate2(qf.title || qf.id, maxTitleLen) })
        ] }) : /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { width: halfWidth, children: [
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502" }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: " ".repeat(halfWidth - 1) })
        ] }),
        df ? /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { flexDirection: "column", children: [
          /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502  " }),
            /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Text, { color: df.status === "done" ? "green" : df.status === "deferred" ? "yellow" : "red", children: [
              df.status === "done" ? "\u2713" : df.status === "deferred" ? "\u23F8" : "\u2717",
              " "
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: df.status !== "done", children: truncate2(`${df.id}  ${df.title || df.id}`, maxTitleLen + 8) })
          ] }),
          df.status !== "done" && df.error ? /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502     " }),
            /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Text, { color: df.status === "deferred" ? "yellow" : "red", dimColor: true, children: [
              "(",
              df.status === "deferred" ? "deferred: " : "",
              truncate2(df.error, maxTitleLen),
              ")"
            ] })
          ] }) : null
        ] }) : /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Box_default, { children: /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502" }) })
      ] }, `row-${i}`)
    );
  }
  if (queued.length === 0 && done.length === 0) {
    rows.push(
      /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { width: halfWidth, children: [
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502" }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: "  (empty)" })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime5.jsxs)(Box_default, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { children: "\u2502" }),
          /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Text, { dimColor: true, children: "  (empty)" })
        ] })
      ] }, "empty")
    );
  }
  return /* @__PURE__ */ (0, import_jsx_runtime5.jsx)(Box_default, { flexDirection: "column", children: rows });
}

// src/components/LogPane.tsx
var import_jsx_runtime6 = __toESM(require_jsx_runtime(), 1);
var PHASE_COLORS = {
  code: "blue",
  tests: "yellow",
  pr: "cyan",
  prd: "magenta",
  techspec: "green",
  tasks: "white"
};
function formatTime(ts) {
  try {
    const d = new Date(ts);
    if (isNaN(d.getTime())) return ts.slice(0, 8);
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    const ss = String(d.getSeconds()).padStart(2, "0");
    return `${hh}:${mm}:${ss}`;
  } catch {
    return "??:??:??";
  }
}
function truncate3(str, maxLen) {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + "\u2026";
}
function LogPane({ log, terminalWidth }) {
  const tail = log.slice(-5);
  const maxTextLen = Math.max(20, terminalWidth - 42);
  const headerDashes = "\u2500".repeat(Math.max(0, terminalWidth - 16));
  return /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Box_default, { flexDirection: "column", children: [
    /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "\u251C\u2500 log (tail) " }),
      /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { dimColor: true, children: headerDashes }),
      /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "\u2524" })
    ] }),
    tail.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "\u2502  " }),
      /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { dimColor: true, children: "(no log entries yet)" })
    ] }) : tail.map((line, i) => {
      const time = formatTime(line.ts);
      const phaseColor = PHASE_COLORS[line.phase] ?? "white";
      const text = truncate3(line.text, maxTextLen);
      return /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Box_default, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "\u2502  " }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Text, { dimColor: true, children: [
          time,
          " "
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { dimColor: true, children: truncate3(line.featureId, 10) }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "  " }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsxs)(Text, { color: phaseColor, children: [
          "[",
          line.phase,
          "]"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: "  " }),
        /* @__PURE__ */ (0, import_jsx_runtime6.jsx)(Text, { children: text })
      ] }, i);
    })
  ] });
}

// src/components/Footer.tsx
var import_jsx_runtime7 = __toESM(require_jsx_runtime(), 1);
function Footer({ terminalWidth = 70 }) {
  const keysLine = "  q quit  p pause  l learnings  f filter  / search  ?  help";
  const innerWidth = Math.max(keysLine.length, terminalWidth - 2);
  const padded = keysLine.padEnd(innerWidth);
  const bottomDashes = "\u2500".repeat(terminalWidth - 2);
  return /* @__PURE__ */ (0, import_jsx_runtime7.jsxs)(Box_default, { flexDirection: "column", children: [
    /* @__PURE__ */ (0, import_jsx_runtime7.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { dimColor: true, children: "\u2502" }),
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { dimColor: true, children: padded }),
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { dimColor: true, children: "\u2502" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime7.jsxs)(Box_default, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { children: "\u2514" }),
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { dimColor: true, children: bottomDashes }),
      /* @__PURE__ */ (0, import_jsx_runtime7.jsx)(Text, { children: "\u2518" })
    ] })
  ] });
}

// src/components/SetupPanel.tsx
var import_jsx_runtime8 = __toESM(require_jsx_runtime(), 1);
function SetupPanel({ state }) {
  const agentEntries = Object.entries(state.setupAgents);
  const skills = state.setupSkills;
  return /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Box_default, { flexDirection: "column", paddingX: 2, paddingY: 1, children: [
    /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { bold: true, children: "monozukuri setup" }),
    /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { children: " " }),
    agentEntries.length === 0 && skills.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { dimColor: true, children: "waiting for install events..." }) : /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(import_jsx_runtime8.Fragment, { children: [
      agentEntries.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(import_jsx_runtime8.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { bold: true, dimColor: true, children: "Agents" }),
        agentEntries.map(([agent, status]) => /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Box_default, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { color: status === "ok" ? "green" : "yellow", children: status === "ok" ? "\u2713" : "\u2192" }),
          /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Text, { children: [
            "  ",
            agent
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Text, { dimColor: true, children: [
            "  ",
            status
          ] })
        ] }, agent)),
        /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { children: " " })
      ] }),
      skills.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(import_jsx_runtime8.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { bold: true, dimColor: true, children: "Skills installed" }),
        skills.map((s, i) => /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Box_default, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime8.jsx)(Text, { color: "green", children: "\u2713" }),
          /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Text, { children: [
            "  ",
            s.skill
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime8.jsxs)(Text, { dimColor: true, children: [
            "  \u2192 ",
            s.agent
          ] })
        ] }, i))
      ] })
    ] })
  ] });
}

// src/hooks/useEventStream.ts
var import_react22 = __toESM(require_react(), 1);

// src/reducer.ts
var PHASES2 = ["prd", "techspec", "tasks", "code", "tests", "pr"];
var LOG_CAP = 200;
function makeDefaultPhases() {
  return {
    prd: "pending",
    techspec: "pending",
    tasks: "pending",
    code: "pending",
    tests: "pending",
    pr: "pending"
  };
}
function makeDefaultFeature(id, title) {
  return {
    id,
    title,
    status: "queued",
    phases: makeDefaultPhases()
  };
}
function appendLog(log, entry) {
  const next = [...log, entry];
  return next.length > LOG_CAP ? next.slice(next.length - LOG_CAP) : next;
}
function initialState() {
  const budget = Number(process.env["MONOZUKURI_BUDGET"] ?? "40") || 40;
  return {
    runId: null,
    autonomy: "",
    model: "",
    agent: "",
    source: "",
    featureCount: 0,
    budget,
    features: {},
    order: [],
    current: null,
    totals: { succeeded: 0, failed: 0, skipped: 0, costUsd: 0 },
    log: [],
    spinner: "",
    setupMode: false,
    setupAgents: {},
    setupSkills: []
  };
}
function reducer(state, event) {
  switch (event.type) {
    case "run.started": {
      return {
        ...state,
        runId: event.run_id,
        autonomy: event.autonomy ?? "",
        model: event.model ?? "",
        agent: event.agent ?? "",
        source: event.source ?? "",
        featureCount: event.feature_count ?? 0
      };
    }
    case "backlog.loaded": {
      const features = { ...state.features };
      const order = [...state.order];
      for (const f of event.features ?? []) {
        if (!features[f.id]) {
          features[f.id] = makeDefaultFeature(f.id, f.title);
          order.push(f.id);
        }
      }
      return { ...state, features, order };
    }
    case "feature.queued": {
      const { feature_id } = event;
      const features = { ...state.features };
      if (!features[feature_id]) {
        features[feature_id] = makeDefaultFeature(feature_id, feature_id);
      }
      const order = state.order.includes(feature_id) ? state.order : [...state.order, feature_id];
      return { ...state, features, order };
    }
    case "feature.started": {
      const { feature_id } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: "active",
          startedAt: event.ts
        }
      };
      return { ...state, features, current: feature_id };
    }
    case "feature.skipped": {
      const { feature_id, reason } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: "skipped",
          error: reason
        }
      };
      const totals = {
        ...state.totals,
        skipped: state.totals.skipped + 1
      };
      return { ...state, features, totals };
    }
    case "phase.started": {
      const { feature_id, phase } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases };
      for (const p of PHASES2) {
        if (p === phase) {
          phases[p] = "in_progress";
          break;
        }
        if (phases[p] === "pending") {
          phases[p] = "done";
        }
      }
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          phases,
          currentPhase: phase,
          currentSkill: void 0,
          currentTier: void 0
        }
      };
      return {
        ...state,
        features,
        spinner: `${phase}: starting...`
      };
    }
    case "phase.progress": {
      const { feature_id, phase, tokens_used } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases, [phase]: "in_progress" };
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          phases,
          tokens: tokens_used,
          currentPhase: phase
        }
      };
      return {
        ...state,
        features,
        spinner: `${phase}: working...`
      };
    }
    case "phase.completed": {
      const { feature_id, phase, tokens_used, cost_usd } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases, [phase]: "done" };
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          phases,
          tokens: tokens_used,
          costUsd: (prev.costUsd ?? 0) + (cost_usd ?? 0)
        }
      };
      return { ...state, features };
    }
    case "phase.failed": {
      const { feature_id, phase, error } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = { ...prev.phases, [phase]: "failed" };
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          phases,
          error
        }
      };
      return { ...state, features };
    }
    case "feature.completed": {
      const { feature_id, pr_url, total_tokens, total_cost_usd } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const phases = Object.fromEntries(
        PHASES2.map((p) => [p, "done"])
      );
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: "done",
          phases,
          prUrl: pr_url,
          tokens: total_tokens,
          costUsd: total_cost_usd
        }
      };
      const totals = {
        ...state.totals,
        succeeded: state.totals.succeeded + 1,
        costUsd: state.totals.costUsd + (total_cost_usd ?? 0)
      };
      const current = state.current === feature_id ? null : state.current;
      return { ...state, features, totals, current };
    }
    case "feature.failed": {
      const { feature_id, error } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: "failed",
          error
        }
      };
      const totals = {
        ...state.totals,
        failed: state.totals.failed + 1
      };
      const current = state.current === feature_id ? null : state.current;
      return { ...state, features, totals, current };
    }
    case "feature.deferred": {
      const { feature_id, reason } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      const features = {
        ...state.features,
        [feature_id]: {
          ...prev,
          status: "deferred",
          error: reason
        }
      };
      const current = state.current === feature_id ? null : state.current;
      return { ...state, features, current };
    }
    case "learning.captured": {
      return state;
    }
    case "log.line": {
      const { feature_id, stream, text, ts } = event;
      const entry = {
        ts,
        featureId: feature_id ?? "",
        phase: stream ?? "",
        text: text ?? ""
      };
      const log = appendLog(state.log, entry);
      return { ...state, log, spinner: text ?? state.spinner };
    }
    case "run.completed": {
      const totals = {
        succeeded: event.succeeded ?? state.totals.succeeded,
        failed: event.failed ?? state.totals.failed,
        skipped: event.skipped ?? state.totals.skipped,
        costUsd: event.total_cost_usd ?? state.totals.costUsd
      };
      return { ...state, totals, current: null };
    }
    case "skill.invoked": {
      const { feature_id, phase, tier, skill } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      return {
        ...state,
        features: {
          ...state.features,
          [feature_id]: { ...prev, currentSkill: skill, currentTier: tier }
        },
        spinner: `${phase}: ${skill} (tier ${tier})`
      };
    }
    case "skill.completed":
    case "skill.failed": {
      return state;
    }
    case "memory.bootstrap": {
      const { feature_id, memory_dir, compaction } = event;
      const prev = state.features[feature_id] ?? makeDefaultFeature(feature_id, feature_id);
      return {
        ...state,
        features: {
          ...state.features,
          [feature_id]: { ...prev, memoryDir: memory_dir, compaction }
        }
      };
    }
    case "memory.note": {
      return state;
    }
    case "setup.started": {
      return { ...state, setupMode: true };
    }
    case "setup.agent_progress": {
      return {
        ...state,
        setupAgents: { ...state.setupAgents, [event.agent]: event.status }
      };
    }
    case "setup.skill_installed": {
      return {
        ...state,
        setupSkills: [...state.setupSkills, { agent: event.agent, skill: event.skill, status: event.status }]
      };
    }
    case "setup.completed": {
      return state;
    }
    default:
      return state;
  }
}

// src/hooks/useEventStream.ts
function useEventStream() {
  const [state, dispatch] = (0, import_react22.useReducer)(reducer, void 0, initialState);
  (0, import_react22.useEffect)(() => {
    process.stdin.setEncoding("utf8");
    process.stdin.resume();
    let buffer = "";
    const onData = (chunk) => {
      buffer += chunk;
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        try {
          const event = JSON.parse(trimmed);
          dispatch(event);
        } catch {
        }
      }
    };
    const onEnd = () => {
      if (buffer.trim()) {
        try {
          const event = JSON.parse(buffer.trim());
          dispatch(event);
        } catch {
        }
        buffer = "";
      }
    };
    process.stdin.on("data", onData);
    process.stdin.on("end", onEnd);
    return () => {
      process.stdin.off("data", onData);
      process.stdin.off("end", onEnd);
    };
  }, []);
  return state;
}

// src/hooks/useKeybindings.ts
var import_react23 = __toESM(require_react(), 1);
function useKeybindings({ setView }) {
  const orchestratorPid = process.env["MONOZUKURI_ORCHESTRATOR_PID"] ? Number(process.env["MONOZUKURI_ORCHESTRATOR_PID"]) : null;
  const [paused, setPaused] = (0, import_react23.useState)(false);
  function sendSignal(sig) {
    if (orchestratorPid) {
      try {
        process.kill(orchestratorPid, sig);
      } catch {
      }
    }
  }
  use_input_default((input, key) => {
    if (input === "q" || key.ctrl && input === "c") {
      sendSignal("SIGINT");
      process.exit(0);
    }
    if (input === "p") {
      if (paused) {
        sendSignal("SIGUSR2");
        setPaused(false);
      } else {
        sendSignal("SIGUSR1");
        setPaused(true);
      }
      return;
    }
    if (input === "l") {
      setView("learnings");
      return;
    }
    if (input === "f") {
      setView("filter");
      return;
    }
    if (input === "/") {
      setView("search");
      return;
    }
    if (input === "?") {
      setView("help");
      return;
    }
    if (key.escape) {
      setView("main");
      return;
    }
  });
}

// src/hooks/useTicker.ts
var import_react24 = __toESM(require_react(), 1);
function useTicker() {
  const [now, setNow] = (0, import_react24.useState)(() => /* @__PURE__ */ new Date());
  (0, import_react24.useEffect)(() => {
    const id = setInterval(() => setNow(/* @__PURE__ */ new Date()), 1e3);
    return () => clearInterval(id);
  }, []);
  return now;
}

// src/App.tsx
var import_jsx_runtime9 = __toESM(require_jsx_runtime(), 1);
function Separator({ width }) {
  const dashes = "\u2500".repeat(Math.max(0, width - 2));
  return /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Box_default, { children: /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "\u251C" + dashes + "\u2524" }) });
}
function App2() {
  const [view, setView] = (0, import_react25.useState)("main");
  const state = useEventStream();
  const now = useTicker();
  const { stdout } = use_stdout_default();
  const terminalWidth = stdout?.columns ?? 80;
  useKeybindings({ setView });
  const currentFeature = state.current ? state.features[state.current] ?? null : null;
  if (view === "help") {
    return /* @__PURE__ */ (0, import_jsx_runtime9.jsxs)(Box_default, { flexDirection: "column", children: [
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { bold: true, children: "Monozukuri \u2014 Keyboard Shortcuts" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: " " }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  q         Quit (sends SIGINT to orchestrator)" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  p         Pause / resume orchestrator (SIGUSR1)" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  l         View learnings" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  f         Filter features" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  /         Search" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  ?         This help screen" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: "  Escape    Return to main view" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { children: " " }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { dimColor: true, children: "Press Escape to return." })
    ] });
  }
  if (view === "learnings") {
    return /* @__PURE__ */ (0, import_jsx_runtime9.jsxs)(Box_default, { flexDirection: "column", children: [
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { bold: true, children: "Learnings view" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })
    ] });
  }
  if (view === "filter") {
    return /* @__PURE__ */ (0, import_jsx_runtime9.jsxs)(Box_default, { flexDirection: "column", children: [
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { bold: true, children: "Filter view" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })
    ] });
  }
  if (view === "search") {
    return /* @__PURE__ */ (0, import_jsx_runtime9.jsxs)(Box_default, { flexDirection: "column", children: [
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { bold: true, children: "Search view" }),
      /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Text, { dimColor: true, children: "(not yet implemented \u2014 press Escape to return)" })
    ] });
  }
  if (state.setupMode) {
    return /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(SetupPanel, { state });
  }
  return /* @__PURE__ */ (0, import_jsx_runtime9.jsxs)(Box_default, { flexDirection: "column", children: [
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Header, { state, terminalWidth }),
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Separator, { width: terminalWidth }),
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(FeatureCard, { feature: currentFeature, spinner: state.spinner, now }),
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(
      FeatureList,
      {
        features: state.features,
        order: state.order,
        terminalWidth
      }
    ),
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(LogPane, { log: state.log, terminalWidth }),
    /* @__PURE__ */ (0, import_jsx_runtime9.jsx)(Footer, { terminalWidth })
  ] });
}

// src/index.tsx
var import_jsx_runtime10 = __toESM(require_jsx_runtime(), 1);
if (!process.stdout.isTTY) {
  process.stdin.pipe(process.stdout);
} else {
  let ttyStdin;
  try {
    const fd = openSync("/dev/tty", "r+");
    ttyStdin = new ReadStream(fd);
  } catch {
  }
  if (!ttyStdin) {
    process.stdin.pipe(process.stdout);
  } else {
    render_default(/* @__PURE__ */ (0, import_jsx_runtime10.jsx)(App2, {}), { stdin: ttyStdin });
  }
}
/*! Bundled license information:

react/cjs/react.production.min.js:
  (**
   * @license React
   * react.production.min.js
   *
   * Copyright (c) Facebook, Inc. and its affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

scheduler/cjs/scheduler.production.min.js:
  (**
   * @license React
   * scheduler.production.min.js
   *
   * Copyright (c) Facebook, Inc. and its affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

react-reconciler/cjs/react-reconciler.production.min.js:
  (**
   * @license React
   * react-reconciler.production.min.js
   *
   * Copyright (c) Facebook, Inc. and its affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

react-reconciler/cjs/react-reconciler-constants.production.min.js:
  (**
   * @license React
   * react-reconciler-constants.production.min.js
   *
   * Copyright (c) Facebook, Inc. and its affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

react/cjs/react-jsx-runtime.production.min.js:
  (**
   * @license React
   * react-jsx-runtime.production.min.js
   *
   * Copyright (c) Facebook, Inc. and its affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)
*/
