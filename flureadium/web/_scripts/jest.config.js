module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  testMatch: ['**/*.test.ts'],
  rootDir: __dirname,
  moduleNameMapper: {
    '\\.css$': '<rootDir>/__mocks__/styleMock.js',
    '^@readium/navigator$': '<rootDir>/__mocks__/@readium/navigator.ts',
    '^@readium/navigator-html-injectables$': '<rootDir>/__mocks__/@readium/navigator-html-injectables.ts',
    '^@readium/shared$': '<rootDir>/__mocks__/@readium/shared.ts',
  },
  transform: {
    '^.+\\.ts$': ['ts-jest', {
      tsconfig: '<rootDir>/tsconfig.json',
    }],
  },
};
