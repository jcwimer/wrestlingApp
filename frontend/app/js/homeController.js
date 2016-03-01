app.controller("homeController", function($scope, $http) {
    $scope.message = "Test message in scope.";
    
    
    $http({
      method: 'GET',
      url: '/api/tournaments/'
    }).then(function successCallback(response) {
        // this callback will be called asynchronously
        // when the response is available
        $scope.query =  response.data;
      }, function errorCallback(response) {
        // called asynchronously if an error occurs
        // or server returns response with an error status.
        $scope.query =  "Nothing there";
      });
});