class ApiController < ApplicationController
    protect_from_forgery with: :null_session
    
    def index
        
    end
    
    def tournaments
       @tournaments = Tournament.all 
    end
    
    def tournament
        @tournament = Tournament.where(:id => params[:tournament]).includes(:schools,:weights,:mats,:matches,:user,:wrestlers).first
    end
    
    def newTournament
        @tournament = Tournament.new(JSON.parse(params[:tournament]))
        @tournament.save
    end
end
