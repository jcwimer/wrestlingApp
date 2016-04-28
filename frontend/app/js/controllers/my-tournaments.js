'use strict';

app.controller("myTournamentsController", function($scope, tournamentsService, $rootScope) {

    tournamentsService.getMyTournaments().then(function(data) {
       //this will execute when the 
       //AJAX call completes.
       $scope.allTournaments = data;
    });
    
});