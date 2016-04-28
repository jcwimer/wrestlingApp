
  
//   $routeProvider.when('/list-of-books', {
//     templateUrl: 'angular/books.html',
//     controller: 'BooksController'
//     // uncomment if you want to see an example of a route that resolves a request prior to rendering
//     // resolve: {
//     //   books : function(BookService) {
//     //     return BookService.get();
//     //   }
//     // }
//   });



app.config(['$routeProvider', '$locationProvider', function($routeProvider,$locationProvider) {
  
  $routeProvider.when('/', {
    templateUrl: 'home.html',
  });   

  $routeProvider.when('/tournaments', {
    templateUrl: 'tournaments-search.html',
    controller: 'tournamentsController'
  });
  
  $routeProvider.when('/tournaments/user', {
    templateUrl: 'my-tournaments.html',
    controller: 'myTournamentsController'
  });
  
  $routeProvider.when('/tournaments/:id', {
    templateUrl: 'tournaments-show.html',
    controller: 'tournamentController'
  });
  
  $routeProvider.when('/about', {
    templateUrl: 'about.html',
  });
  
  $routeProvider.when('/tutorials', {
    templateUrl: 'tutorials.html',
  });
  
  $routeProvider.otherwise({redirectTo: '/'});
  
  //this give me normal routes instead of /#/
  // $locationProvider.html5Mode(true);
}]);