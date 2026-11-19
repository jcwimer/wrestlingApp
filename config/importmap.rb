# Pin npm packages by running ./bin/importmap

pin "application", preload: true # Preloads app/assets/javascripts/application.js
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js" # For Action Cable

# Pin controllers from app/assets/javascripts/controllers
pin_all_from "app/assets/javascripts/controllers", under: "controllers"
pin "match-state-config", to: "lib/match_state/config.js"
pin "match-state-engine", to: "lib/match_state/engine.js"
pin "match-state-serializers", to: "lib/match_state/serializers.js"
pin "match-state-presenters", to: "lib/match_state/presenters.js"
pin "match-state-transport", to: "lib/match_state/transport.js"
pin "match-state-scoreboard-presenters", to: "lib/match_state/scoreboard_presenters.js"
pin "match-state-scoreboard-state", to: "lib/match_state/scoreboard_state.js"
