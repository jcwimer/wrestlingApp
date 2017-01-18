'use strict';
app.controller("tournamentController", function($scope, tournamentsService, $routeParams, Wrestler, Auth, $rootScope) {
    $scope.message = "Test message in scope.";
    

    // $scope.tournamentData = "test";
    tournamentsService.tournamentDetails($routeParams.id).then(function(data) {
      //this will execute when the 
      //AJAX call completes.
      $scope.tournament = data;
    });
    
    $scope.refreshTournamentData = function(){
      tournamentsService.tournamentDetails($routeParams.id).then(function(data) {
        //this will execute when the 
        //AJAX call completes.
        $scope.tournament = data;
      });
    };
    
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
    
    
    $scope.newSchool = null;
    
    $scope.saveNewSchool = function(){
      $scope.newSchool.tournament_id = $scope.tournament.id;
      tournamentsService.saveNewSchool($scope.newSchool).then(function(data) {
        $scope.tournament.schools.push(data);
      });
      $scope.newSchool = null;
      $('#NewSchool').modal('hide');
    };
    
    $scope.deleteSchool = function(school){
      if (confirm('Are you sure you want to delete ' + school.name + '?')) {
        tournamentsService.deleteSchool(school).then(function(data) {
          $scope.tournament.schools.splice( $scope.tournament.schools.indexOf(school), 1 );
        });
      }
    };
    
    $scope.updateSchool = function(school){
      tournamentsService.updateSchool(school);
      $('#EditSchool' + school.id).modal('hide');
    };
    
  
});