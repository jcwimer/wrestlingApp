'use strict';

app.factory('Wrestler', function Wrestler(){
    var vm = this;
    
    
    vm.matches = function(wrestler,matches){

        console.log(matches);
        return _.filter(matches, function(match){
            return match.w1 == wrestler.id || match.w2 == wrestler.id;
        });
        
        
    };
    
    return vm;
});