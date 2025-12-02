class UsersController < ApplicationController
  before_action :authenticate_user!
  
  # Page profil (configuration des favoris)
  def show
    @user = current_user
    @available_cities = User.available_cities
    @available_countries = User.available_countries
    @available_teachers = Teacher.order(:first_name, :last_name)
    @available_practices = Practice.order(:name)
  end
  
  # Mise à jour des favoris
  def update
    @user = current_user
    
    if @user.update(user_params)
      redirect_to profile_path, notice: "Préférences mises à jour avec succès !"
    else
      @available_cities = User.available_cities
      @available_countries = User.available_countries
      @available_teachers = Teacher.order(:first_name, :last_name)
      @available_practices = Practice.order(:name)
      render :show, status: :unprocessable_entity
    end
  end
  
  # Toggle union/intersection
  def toggle_filter_mode
    current_user.toggle_filter_mode!
    redirect_to my_events_path, notice: "Mode de filtrage changé : #{current_user.filter_mode == 'union' ? 'OU' : 'ET'}"
  end
  
  def upload_avatar
    if params[:avatar].present?
      begin
        Rails.logger.info "=== DEBUT UPLOAD CLOUDINARY ==="
        Rails.logger.info "Fichier recu: #{params[:avatar].original_filename}"
        
        # Supprimer l'ancien avatar s'il existe
        if current_user.avatar_cloudinary_id.present?
          Cloudinary::Uploader.destroy(current_user.avatar_cloudinary_id)
        end
        
        result = Cloudinary::Uploader.upload(
          params[:avatar].tempfile,
          folder: "avatars",
          public_id: "user_#{current_user.id}_#{Time.current.to_i}",
          transformation: [
            { width: 400, height: 400, crop: :fill, gravity: :face },
            { quality: "auto", fetch_format: "auto" }
          ],
          invalidate: true  # Force l'invalidation du cache CDN
        )
        current_user.update!(avatar_cloudinary_id: result["public_id"])
        redirect_to edit_user_registration_path, notice: "Avatar mis a jour avec succes!"
      rescue => e
        Rails.logger.error "=== ERREUR CLOUDINARY ==="
        Rails.logger.error "#{e.class}: #{e.message}"
        redirect_to edit_user_registration_path, alert: "ERREUR: #{e.message}"
      end
    else
      redirect_to edit_user_registration_path, alert: "Aucun fichier selectionne"
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(
      :search_keywords,
      :filter_mode,
      favorite_cities: [],
      favorite_countries: [],
      favorite_teacher_ids: [],
      favorite_practice_ids: []
    )
  end
end
