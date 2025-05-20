# Pin npm packages by running ./bin/importmap

pin "application", preload: true # Preloads app/assets/javascripts/application.js
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js" # For Action Cable

# Pin jQuery. jquery-rails should make "jquery.js" or "jquery.min.js" available.
# If this doesn't work, you might need to copy jquery.js/jquery.min.js to vendor/javascript
# and pin it directly, e.g., pin "jquery", to: "jquery.min.js"
pin "jquery", to: "jquery.js"

# Pin Bootstrap and DataTables from vendor/assets/javascripts/
pin "bootstrap", to: "bootstrap.min.js"
pin "datatables.net", to: "jquery.dataTables.min.js" # Assuming this is how you want to import it

# If Bootstrap requires Popper.js, and you have it in vendor/assets/javascripts/
# pin "@popperjs/core", to: "popper.min.js" # Or the actual filename if different

# Pin controllers from app/assets/javascripts/controllers
pin_all_from "app/assets/javascripts/controllers", under: "controllers"

# Pin all JS files from app/assets/javascripts directory
pin_all_from "app/assets/javascripts", under: "assets/javascripts" 