'use strict';
app.controller("tournamentController", function($scope, tournamentsService, $routeParams, Wrestler, Auth, $rootScope) {
    $scope.message = "Test message in scope.";
    

    // $scope.tournamentData = "test";
    tournamentsService.tournamentDetails($routeParams.id).then(function(data) {
      //this will execute when the 
      //AJAX call completes.
      $scope.tournament = data;
    });
    
    // refresh tournament data every 10 seconds
    // setInterval(function(){ 
    //   tournamentsService.tournamentDetails($routeParams.id).then(function(data) {
    //     //this will execute when the 
    //     //AJAX call completes.
    //     $scope.tournament = data;
    //   });
    // }, 10000);
    
    $scope.wrestler = Wrestler;
    
    $scope.showSchools = false;
    
    $scope.toggleSchools = function(){
      $scope.showSchools = !$scope.showSchools;
    };
    
    $scope.showWeightSeeds = false;
    
    $scope.toggleWeightSeeds = function(){
      $scope.showWeightSeeds = !$scope.showWeightSeeds;
    };
    
    $scope.showBoutBoard = false;
    
    $scope.toggleBoutBoard = function(){
      $scope.showBoutBoard = !$scope.showBoutBoard;
    };
    

    $scope.isTournamentOwner = function(tournamentId,userId){
      if(userId == tournamentId){
        return true;
      } else {
        return false;
      }
    };
    
  
});