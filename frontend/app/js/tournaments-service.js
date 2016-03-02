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
     }
    };

});

