// Entry point for your JavaScript application

// These are pinned in config/importmap.rb
import "@hotwired/turbo-rails";
import { createConsumer } from "@rails/actioncable"; // Import createConsumer directly
import "jquery";
import "bootstrap"; 

// Stimulus setup
import { Application } from "@hotwired/stimulus";
import { cleanupExpiredLocalStorage } from "match-state-transport";

// Initialize Stimulus application
const application = Application.start();
window.Stimulus = application;

// Load all controllers from app/assets/javascripts/controllers
// Import controllers manually
import WrestlerColorController from "controllers/wrestler_color_controller";
import MatchScoreController from "controllers/match_score_controller";
import MatchDataController from "controllers/match_data_controller";
import MatchStateController from "controllers/match_state_controller";
import MatchScoreboardController from "controllers/match_scoreboard_controller";
import MatStateController from "controllers/mat_state_controller";
import MatchSpectateController from "controllers/match_spectate_controller";
import UpMatchesConnectionController from "controllers/up_matches_connection_controller";

// Register controllers
application.register("wrestler-color", WrestlerColorController);
application.register("match-score", MatchScoreController);
application.register("match-data", MatchDataController);
application.register("match-state", MatchStateController);
application.register("match-scoreboard", MatchScoreboardController);
application.register("mat-state", MatStateController);
application.register("match-spectate", MatchSpectateController);
application.register("up-matches-connection", UpMatchesConnectionController);

function cleanupWrestlingAppLocalStorage() {
  cleanupExpiredLocalStorage(window.localStorage);
}

document.addEventListener("turbo:load", cleanupWrestlingAppLocalStorage);
cleanupWrestlingAppLocalStorage();

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

console.log("Propshaft/Importmap application.js initialized with jQuery, Bootstrap, and Stimulus.");

// If you have custom JavaScript files in app/javascript/ that were previously
// handled by Sprockets `require_tree`, you'll need to import them here explicitly.
// For example:
// import "./my_custom_logic"; 
