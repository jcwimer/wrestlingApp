'use strict';

app.controller("tournamentsController", function($scope, tournamentsService) {

    tournamentsService.getAllTournaments().then(function(data) {
       //this will execute when the 
       //AJAX call completes.
       $scope.allTournaments = data;
    });
    
    $scope.searchTournaments = function (){
      tournamentsService.searchTournaments($scope.searchTerms).then(function(data) {
         //this will execute when the 
         //AJAX call completes.
         $scope.allTournaments = data;
      });
    };
    
});