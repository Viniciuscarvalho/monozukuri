const tsJestTransformer = require.resolve('ts-jest');

module.exports = {
  rootDir: __dirname,
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts', '.tsx'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  transform: {
    '^.+\\.tsx?$': [
      tsJestTransformer,
      {
        useESM: true,
        tsconfig: {
          jsx: 'react-jsx',
          moduleResolution: 'bundler',
          module: 'ESNext',
          baseUrl: '.',
          paths: {
            'ink-testing-library': ['./node_modules/ink-testing-library/build/index.d.ts'],
          },
          strict: true,
          esModuleInterop: true,
          skipLibCheck: true,
        },
      },
    ],
  },
  testMatch: ['**/__tests__/**/*.{ts,tsx}'],
};
