// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
// Bootstrap 3.3.6 in vendor/assets/javascripts
//= require bootstrap.min.js
// Data Tables 1.10.6 in vendor/assets/javascripts
//= require jquery.dataTables.min.js
//= require turbolinks
//
//= require actioncable
//= require_self
//= require_tree .

// Create the Action Cable consumer instance
(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();

}).call(this);

