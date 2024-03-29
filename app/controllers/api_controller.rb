class ApiController < ApplicationController
    protect_from_forgery with: :null_session
    
    def index
        
    end
    
    def tournaments
        if params[:search]
          @tournaments = Tournament.search(params[:search]).order("created_at DESC")
        else
          @tournaments = Tournament.all.sort_by{|t| t.days_until_start}.first(20)
        end 
    end
    
    def tournament
        @tournament = Tournament.where(:id => params[:tournament]).includes(:schools,:weights,:mats,:matches,:user,:wrestlers).first
        @schools = @tournament.schools.includes(:wrestlers)
        @weights = @tournament.weights.includes(:wrestlers)
        @matches = @tournament.matches.includes(:wrestlers,:schools)
        @mats = @tournament.mats.includes(:matches)
    end
    
    def newTournament
        @tournament = Tournament.new(JSON.parse(params[:tournament]))
        @tournament.save
    end
    
    def currentUserTournaments
       @tournaments = current_user.tournaments
    end
end
