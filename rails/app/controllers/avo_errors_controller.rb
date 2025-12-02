class AvoErrorsController < ApplicationController
  layout 'avo_error'

  def show
    @title = params[:title] || "Erreur"
    @details = params[:details] || "Une erreur est survenue"
    @hint = params[:hint]
    @back_url = params[:back_url] || :back
  end
end
