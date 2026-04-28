// Stub for react-devtools-core so the bundle has no external dependency on it.
// Ink imports this package only when process.env.DEV === 'true'; the esbuild
// alias directs the import here so the bundle stays self-contained.
export default { connectToDevTools: () => {} };
