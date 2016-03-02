app.controller("tournamentsController", function($scope, tournamentsService) {
    $scope.message = "Test message in scope.";

    tournamentsService.getAllTournaments().then(function(data) {
       //this will execute when the 
       //AJAX call completes.
       console.log(data);
       $scope.allTournaments = data;
    });
    
    $scope.searchTournaments = function (){
      console.log("Tried search");
      tournamentsService.searchTournaments($scope.searchTerms).then(function(data) {
         //this will execute when the 
         //AJAX call completes.
         console.log(data);
         $scope.allTournaments = data;
      });
    }
    
});