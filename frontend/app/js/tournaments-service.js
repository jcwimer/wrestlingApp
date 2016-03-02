app.factory('tournamentsService', function($http){

      
   return {
     getAllTournaments: function() {
       //since $http.get returns a promise,
       //and promise.then() also returns a promise
       //that resolves to whatever value is returned in it's 
       //callback argument, we can return that.
       return $http.get('/api/tournaments/').then(function(result) {
           return result.data;
       });
     },
     
     searchTournaments: function(search){
        return $http({
          method: 'GET',
          url: '/api/tournaments/',
          params: {
              search: search
          }
        }).then(function successCallback(response) {
            // this callback will be called asynchronously
            // when the response is available
            return response.data;
          }, function errorCallback(response) {
            // called asynchronously if an error occurs
            // or server returns response with an error status.
            return response;
          }); 
     }
    };

});

