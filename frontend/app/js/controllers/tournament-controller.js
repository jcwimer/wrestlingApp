'use strict';
app.controller("tournamentController", function($scope, tournamentsService, $routeParams) {
    $scope.message = "Test message in scope.";
    
    // $scope.tournamentData = "test";
    tournamentsService.tournamentDetails($routeParams.id).then(function(data) {
      //this will execute when the 
      //AJAX call completes.
      $scope.tournament = data;
    });
    
});