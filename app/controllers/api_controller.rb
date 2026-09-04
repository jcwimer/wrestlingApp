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
        @tournament = Tournament.where(:id => params[:tournament]).includes(:user, :mats, :schools, :weights, :matches, wrestlers: [:school, :weight, :matches_as_w1, :matches_as_w2]).first
        @schools = @tournament.schools.includes(wrestlers: [:weight, :matches_as_w1, :matches_as_w2])
        @weights = @tournament.weights.includes(wrestlers: [:school, :matches_as_w1, :matches_as_w2])
        @matches = @tournament.matches.includes({ wrestler1: :school }, { wrestler2: :school }, { weight: :matches })
        @mats = @tournament.up_matches_mats
        @api_cache_fingerprint = [
          @tournament.updated_at,
          @schools.maximum(:updated_at),
          @weights.maximum(:updated_at),
          @tournament.wrestlers.maximum(:updated_at),
          @tournament.matches.maximum(:updated_at)
        ]
    end
    
    def newTournament
        @tournament = Tournament.new(JSON.parse(params[:tournament]))
        @tournament.save
    end
    
    def currentUserTournaments
       @tournaments = current_user.tournaments
    end
end
