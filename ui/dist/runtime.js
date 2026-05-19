// Shared cleanup hook: set by index.tsx, called by App.tsx before exit.
export let cleanup = null;
export function registerCleanup(fn) {
    cleanup = fn;
}
