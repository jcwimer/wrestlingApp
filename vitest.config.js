import path from "node:path"
import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "node",
    include: ["test/javascript/**/*.test.js"]
  },
  resolve: {
    alias: {
      "@hotwired/stimulus": path.resolve("test/javascript/support/stimulus_stub.js"),
      "match-state-config": path.resolve("app/assets/javascripts/lib/match_state/config.js"),
      "match-state-engine": path.resolve("app/assets/javascripts/lib/match_state/engine.js"),
      "match-state-serializers": path.resolve("app/assets/javascripts/lib/match_state/serializers.js"),
      "match-state-presenters": path.resolve("app/assets/javascripts/lib/match_state/presenters.js"),
      "match-state-transport": path.resolve("app/assets/javascripts/lib/match_state/transport.js"),
      "match-state-scoreboard-presenters": path.resolve("app/assets/javascripts/lib/match_state/scoreboard_presenters.js"),
      "match-state-scoreboard-state": path.resolve("app/assets/javascripts/lib/match_state/scoreboard_state.js")
    }
  }
})
