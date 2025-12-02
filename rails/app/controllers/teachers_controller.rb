class TeachersController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_teacher, only: %i[ show edit update destroy ]
  before_action :check_teacher_owner, only: %i[ edit update destroy ]

  # GET /teachers
  def index
    if params[:filter] == 'my' && user_signed_in?
      @teachers = current_user.teachers
    else
      @teachers = Teacher.all
    end

    # Appliquer la recherche si présente
    if params[:search].present?
      @teachers = @teachers.search_by_keywords(params[:search])
    end

    # Ordonner par prénom et nom
    @teachers = @teachers.order(:first_name, :last_name)
  end

  # GET /teachers/1
  def show
    @upcoming_occurrences = @teacher.upcoming_event_occurrences
  end

  # GET /teachers/new
  def new
    @teacher = Teacher.new
    @return_to = params[:return_to]
  end

  # GET /teachers/1/edit
  def edit
  end

  # POST /teachers
  def create
    @teacher = current_user.teachers.build(teacher_params)

    respond_to do |format|
      if @teacher.save
        message = "Professeur créé avec succès."

        # Gérer la redirection selon return_to avec flag restored
        if params[:return_to] == 'events_new'
          format.html { redirect_to new_event_path, notice: "#{message} Continuez à créer votre événement." }
        else
          format.html { redirect_to @teacher, notice: message }
        end
        format.json { render :show, status: :created, location: @teacher }
      else
        @return_to = params[:return_to]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teachers/1
  def update
    respond_to do |format|
      if @teacher.update(teacher_params)
        format.html { redirect_to @teacher, notice: "Professeur mis à jour avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @teacher }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teachers/1
  def destroy
    @teacher.destroy!

    respond_to do |format|
      format.html { redirect_to teachers_path, notice: "Professeur supprimé.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def check_teacher_owner
    # Autoriser si l'utilisateur est admin OU propriétaire du teacher
    unless current_user.admin? || @teacher.user == current_user
      redirect_to teachers_path, alert: "Vous n'êtes pas autorisé à modifier ce professeur."
    end
  end

  def set_teacher
    @teacher = Teacher.find(params[:id])
  end

  # Strong params
  def teacher_params
    params.require(:teacher).permit(
      :first_name,
      :last_name,
      :bio,
      :contact_email,
      :phone,
      :photo_cloudinary_id,
      :reference_url,
      practice_ids: [],
      teacher_urls_attributes: [:id, :url, :name, :is_active, :_destroy]
    )
  end
end
