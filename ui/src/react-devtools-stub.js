// Stub for react-devtools-core. Ink imports this at module level but only
// invokes connectToDevTools() when process.env.DEV === 'true'. Production
// installs (Homebrew, npx) don't ship the real package, so we alias the
// import to this no-op via esbuild's --alias flag.
const stub = {
  connectToDevTools: () => {},
};

export default stub;
