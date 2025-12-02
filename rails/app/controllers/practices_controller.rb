class PracticesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_practice, only: [:show, :edit, :update, :destroy]
  before_action :authorize_practice!, only: [:edit, :update, :destroy]
  
  def index
    @practices = Practice.includes(:teachers, :events, :user).ordered_by_name
  end
  
  def show
    @teachers = @practice.teachers.includes(:user)
    @events = @practice.events.includes(:principal_teacher).active
  end
  
  def new
    @practice = Practice.new
    @return_to = params[:return_to]
  end
  
  def create
    @practice = current_user.practices.build(practice_params)
    
    if @practice.save
      message = 'Pratique créée avec succès.'
      
      # Gérer la redirection selon return_to avec flag restored
      if params[:return_to] == 'events_new'
        redirect_to new_event_path, notice: "#{message} Continuez à créer votre événement."
      elsif params[:return_to] == 'teachers_new'
        redirect_to new_teacher_path, notice: "#{message} Continuez à créer votre professeur."
      else
        redirect_to @practice, notice: message
      end
    else
      @return_to = params[:return_to]
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @practice.update(practice_params)
      redirect_to @practice, notice: 'Pratique mise à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @practice.events.any?
      redirect_to @practice, alert: 'Impossible de supprimer: des événements utilisent cette pratique.'
    else
      @practice.destroy
      redirect_to practices_path, notice: 'Pratique supprimée avec succès.'
    end
  end
  
  private
  
  def set_practice
    @practice = Practice.find(params[:id])
  end
  
  def authorize_practice!
    unless current_user.admin? || @practice.user == current_user
      redirect_to practices_path, alert: 'Vous n\'êtes pas autorisé à modifier cette pratique.'
    end
  end
  
  def practice_params
    params.require(:practice).permit(:name, :description)
  end
end
