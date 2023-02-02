const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://wrestlingdev-test.wimer.house',
    supportFile: false,
    video: false,
  },
  env: {
    CYPRESS_PASSWORD: 'password',
    CYPRESS_USERNAME: 'test@test.com',
  },
})