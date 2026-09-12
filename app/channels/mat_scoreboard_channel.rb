# frozen_string_literal: true

class MatScoreboardChannel < ApplicationCable::Channel
  def subscribed
    @mat = Mat.find_by(id: params[:mat_id])
    return reject unless @mat
    return reject unless can?(:read, @mat.tournament)

    stream_for @mat
    transmit(scoreboard_payload(@mat))
  end

  private

  def scoreboard_payload(mat)
    mat.scoreboard_payload
  end
end
