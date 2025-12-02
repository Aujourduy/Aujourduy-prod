class VenuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_venue, only: %i[ show edit update destroy ]
  before_action :check_owner, only: %i[ edit update destroy ]

  skip_before_action :verify_authenticity_token, only: [:geocode]

  # GET /venues or /venues.json
  def index
    @venues = Venue.includes(:user).all
    
    # Filtres
    @venues = @venues.by_city(params[:city]) if params[:city].present?
    @venues = @venues.by_country(params[:country]) if params[:country].present?
    
    # Pour les options de filtres
    @cities = Venue.distinct.pluck(:city).compact.sort
    @countries = Venue.distinct.pluck(:country).compact.sort
    
    @venues = @venues.page(params[:page]).per(10) if defined?(Kaminari)
  end

  # GET /venues/1 or /venues/1.json
  def show
  end

  # GET /venues/new
  def new
    @venue = current_user.venues.build
  end

  # GET /venues/1/edit
  def edit
  end

  # POST /venues or /venues.json
  def create
    @venue = current_user.venues.build(venue_params)

    # Géolocalisation automatique si pas de coordonnées
    if @venue.address_line1.present? && !@venue.coordinates?
      geocode_result = GeocodingService.geocode(@venue.full_address)
      if geocode_result[:success]
        @venue.latitude = geocode_result[:latitude]
        @venue.longitude = geocode_result[:longitude]
      end
    end

    respond_to do |format|
      if @venue.save
        format.html { redirect_to @venue, notice: "Lieu créé avec succès." }
        # ✅ Réponse JSON adaptée pour l'AJAX depuis events/new
        format.json { render json: { id: @venue.id, name: @venue.name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        # ✅ Réponse d'erreur en JSON lisible
        format.json { render json: { error: @venue.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /venues/1 or /venues/1.json
  def update
    respond_to do |format|
      if @venue.update(venue_params)
        format.html { redirect_to @venue, notice: "Lieu modifié avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @venue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1 or /venues/1.json
  def destroy
    @venue.destroy!

    respond_to do |format|
      format.html { redirect_to venues_path, notice: "Lieu supprimé avec succès.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def geocode
    address = params[:address]
  
    if address.blank?
      render json: { success: false, error: "Adresse requise" }
      return
    end

    result = GeocodingService.geocode(address)
    render json: result
  end

  private

  def set_venue
    @venue = Venue.find(params[:id]) # ✅ corrigé : :id, pas :expect
  end

  def check_owner
    unless @venue.user == current_user
      redirect_to venues_path, alert: "Vous n'êtes pas autorisé à modifier ce lieu."
    end
  end

  def venue_params
    # ✅ corrigé : params.require, pas params.expect
    params.require(:venue).permit(
      :name, :address_line1, :address_line2, :postal_code, :city, :department_code, :department_name, :region, :country, :latitude, :longitude
    )
  end
end