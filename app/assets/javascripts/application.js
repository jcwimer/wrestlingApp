// Entry point for your JavaScript application

// These are pinned in config/importmap.rb
import "@hotwired/turbo-rails";
import { createConsumer } from "@rails/actioncable"; // Import createConsumer directly
import "jquery";
import "bootstrap"; 
import "datatables.net";

// Stimulus setup
import { Application } from "@hotwired/stimulus";

// Initialize Stimulus application
const application = Application.start();
window.Stimulus = application;

// Load all controllers from app/assets/javascripts/controllers
// Import controllers manually
import WrestlerColorController from "controllers/wrestler_color_controller";
import MatchScoreController from "controllers/match_score_controller";
import MatchDataController from "controllers/match_data_controller";
import MatchSpectateController from "controllers/match_spectate_controller";

// Register controllers
application.register("wrestler-color", WrestlerColorController);
application.register("match-score", MatchScoreController);
application.register("match-data", MatchDataController);
application.register("match-spectate", MatchSpectateController);

// Your existing Action Cable consumer setup
(function() {
  try {
    window.App || (window.App = {});
    window.App.cable = createConsumer(); // Use the imported createConsumer
    console.log('Action Cable Consumer Created via app/assets/javascripts/application.js');
  } catch (e) {
    console.error('Error creating ActionCable consumer:', e);
    console.error('ActionCable not loaded or createConsumer failed, App.cable not created.');
  }
}).call(this);

console.log("Propshaft/Importmap application.js initialized with jQuery, Bootstrap, Stimulus, and DataTables.");

// If you have custom JavaScript files in app/javascript/ that were previously
// handled by Sprockets `require_tree`, you'll need to import them here explicitly.
// For example:
// import "./my_custom_logic"; 