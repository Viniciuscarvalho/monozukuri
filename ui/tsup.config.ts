import { defineConfig } from 'tsup';
import { fileURLToPath } from 'url';
import { resolve, dirname } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  entry: ['src/index.tsx'],
  format: ['esm'],
  target: 'node18',
  platform: 'node',
  bundle: true,
  splitting: false,
  clean: true,
  outDir: 'dist',
  banner: {
    js: `import { createRequire } from 'module'; const require = createRequire(import.meta.url);`,
  },
  esbuildOptions(opts) {
    opts.alias = {
      'react-devtools-core': resolve(__dirname, './stubs/react-devtools-core.js'),
    };
    opts.define = {
      ...opts.define,
      'process.env.NODE_ENV': '"production"',
    };
  },
});
