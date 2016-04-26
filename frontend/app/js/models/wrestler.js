'use strict';

app.factory('Wrestler', function Wrestler(){
    var vm = this;
    
    
    vm.matches = function(matches,wrestler){
        var givenWrestler = wrestler;

        console.log(givenWrestler.id);
        return _.filter(matches, function(match){
            return match.w1 == givenWrestler.id || match.w2 == givenWrestler.id;
        });
        
        
    }
    
    return vm;
});