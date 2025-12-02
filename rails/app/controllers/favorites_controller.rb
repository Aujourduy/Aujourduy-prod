class FavoritesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
    
    if @user.has_favorites?
      @occurrences = @user.favorite_occurrences
                          .includes(:venue, :event, :teachers)
                          .where('date >= ?', Date.current)
                          .order(date: :asc, start_time: :asc)
                          .limit(100)
      @occurrences_count = @occurrences.count
    else
      @occurrences = []
      @occurrences_count = 0
    end
  end
end
