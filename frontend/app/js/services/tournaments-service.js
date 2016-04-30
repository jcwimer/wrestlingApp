
app.factory('tournamentsService', tournamentsService);

function tournamentsService($http,$rootScope){
    var service = {};
    
    service.getMyTournaments = function(user){
        return $http({
            url: '/api/tournaments/user/',
            method: "GET"
        }).then(successResponse, errorCallback);
    };

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
    
    service.saveNewSchool = function(newSchool){
        return $http({
            url: '/schools.json',
            method: "POST",

            data: {
                school: {
                    'name': newSchool.name,
                    'tournament_id': newSchool.tournament_id
                }
            },
            headers: {
                "Content-Type": "application/json"
            }
        }).then(successResponse, errorCallback);
    };
    
    service.deleteSchool = function(school){
        return $http({
            url: '/schools/' + school.id + '/',
            method: "DELETE"
        }).then(successResponse, errorCallback);
    };
    
    service.updateSchool = function(schoolToEdit){
        return $http({
            url: '/schools/' + schoolToEdit.id,
            method: "PATCH",
            data: {
                school: {
                    'name': schoolToEdit.name,
                    'tournament_id': schoolToEdit.tournament_id
                }
            },
            headers: {
                "Content-Type": "application/json"
            }
        }).then(successResponse, errorCallback);
    };

    function successResponse(response){
        // console.log("success log below");
        // console.log(response);
        if(response.config.method == "POST" || response.config.method == "DELETE" || response.config.method == "PATCH"){
            $rootScope.alertClass = "alert alert-success";
            $rootScope.alertMessage = response.statusText;
        }
        return response.data;
    }

    function errorCallback(err){
        // console.log("error log below");
        // console.log(err);
        if(err.status > 0){
            $rootScope.alertClass = "alert alert-danger";
            $rootScope.alertMessage = err.statusText;
        }
        
        return err;
    }

    return service;
}

