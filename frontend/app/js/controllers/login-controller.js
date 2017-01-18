'use strict';
app.controller("loginController", function($scope, $routeParams, Auth, $rootScope) {
    $scope.credentials = {
        email: '',
        password: ''
    };
    
    var config = {
        headers: {
            'X-HTTP-Method-Override': 'POST'
        }
    };
    
    
    $scope.login = function(){
      Auth.login($scope.credentials, config).then(function(user) {
            console.log(user); // => {id: 1, ect: '...'}
            $rootScope.user = user;
            $rootScope.alertClass = "alert alert-success";
            $rootScope.alertMessage = "Logged in successfully";
        }, function(error) {
            console.log(error);
            $rootScope.alertClass = "alert alert-danger";
            $rootScope.alertMessage = "Username and/or password is incorrect";
        });
    };
    
    $scope.logout = function(){
      Auth.logout(config).then(function(oldUser) {
            // alert(oldUser.name + "you're signed out now.");
            $rootScope.user = null;
            $rootScope.alertClass = "alert alert-success";
            $rootScope.alertMessage = "Logged out successfully";
      }, function(error) {
            // An error occurred logging out.
            $rootScope.alertClass = "alert alert-danger";
            $rootScope.alertMessage = "There was an error logging out";
      });  
    };
    
    Auth.currentUser().then(function(user) {
        // User was logged in, or Devise returned
        // previously authenticated session.
        $rootScope.user = user;
    }, function(error) {
        // unauthenticated error
        $rootScope.user = null;
    });
    
  
});