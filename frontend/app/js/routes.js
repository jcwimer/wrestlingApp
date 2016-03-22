
  
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



app.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider.
      when('/tournaments', {
        templateUrl: 'tournaments.html',
        controller: 'tournamentsController'
      }).
    //   when('/phones/:phoneId', {
    //     templateUrl: 'partials/phone-detail.html',
    //     controller: 'PhoneDetailCtrl'
    //   }).
      otherwise({
        redirectTo: '/tournaments'
      });
  }]);