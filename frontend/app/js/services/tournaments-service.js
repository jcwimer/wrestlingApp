
app.factory('tournamentsService', tournamentsService);

function tournamentsService($http){
    var service = {};
    


    service.getAllTournaments = function(){
        return $http({
            url: '/api/tournaments/',
            method: "GET"
        }).then(successResponse, errorCallback);
    };

    service.searchTournaments = function(search){
        return $http({
          method: 'GET',
          url: '/api/tournaments/',
          params: {
              search: search
          }
        }).then(successResponse, errorCallback);
    };

    service.tournamentDetails = function(tournamentId){
        return $http({
            url: '/api/tournaments/' + tournamentId,
            method: "GET"
        }).then(successResponse, errorCallback);
    };

    function successResponse(response){
        // console.log("success log below");
        // console.log(response);
        return response.data;
    }

    function errorCallback(err){
        console.log("error log below");
        console.log(err);
        return err;
    }

    return service;
}

