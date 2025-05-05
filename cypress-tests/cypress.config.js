const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost',
    supportFile: 'cypress/support/e2e.js', // Path to e2e.js
    video: false,
    experimentalMemoryManagement: true,
    numTestsKeptInMemory: 0,
  },
  env: {
    CYPRESS_PASSWORD: 'password',
    CYPRESS_USERNAME: 'test@test.com',
  },
})