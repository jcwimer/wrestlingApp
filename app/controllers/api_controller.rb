class ApiController < ApplicationController
    
    def tournaments
       @tournaments = Tournament.all 
    end
    
    def tournament
        @tournament = Tournament.where(:id => params[:tournament]).includes(:schools,:weights,:mats,:matches,:user,:wrestlers).first
    end
end
