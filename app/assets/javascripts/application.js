// Entry point for your JavaScript application

// These are pinned in config/importmap.rb
import "@hotwired/turbo-rails";
import { createConsumer } from "@rails/actioncable"; // Import createConsumer directly
import "jquery";
import "bootstrap"; 
import "datatables.net";

// Your existing Action Cable consumer setup
(function() {
  try {
    window.App || (window.App = {});
    window.App.cable = createConsumer(); // Use the imported createConsumer
    console.log('Action Cable Consumer Created via app/javascript/application.js');
  } catch (e) {
    console.error('Error creating ActionCable consumer:', e);
    console.error('ActionCable not loaded or createConsumer failed, App.cable not created.');
  }
}).call(this);

console.log("Propshaft/Importmap application.js initialized with jQuery, Bootstrap, and DataTables.");

// If you have custom JavaScript files in app/javascript/ that were previously
// handled by Sprockets `require_tree`, you'll need to import them here explicitly.
// For example:
// import "./my_custom_logic"; 