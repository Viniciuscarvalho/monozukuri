// Shared cleanup hook: set by index.tsx, called by App.tsx before exit.
export let cleanup: (() => void) | null = null;

export function registerCleanup(fn: () => void): void {
  cleanup = fn;
}
