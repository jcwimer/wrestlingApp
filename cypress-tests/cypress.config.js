const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost',
    supportFile: false,
    video: false,
  },
  env: {
    CYPRESS_PASSWORD: 'password',
    CYPRESS_USERNAME: 'test@test.com',
  },
})