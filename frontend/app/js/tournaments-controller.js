app.controller("tournamentsController", function($scope, tournamentsService) {
    $scope.message = "Test message in scope.";

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