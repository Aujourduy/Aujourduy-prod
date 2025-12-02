class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def update_resource(resource, params)
    if resource.google_uid.present?
      # On supprime current_password pour éviter l'erreur
      params.delete(:current_password)

      # Met à jour sans demander de mot de passe
      resource.update_without_password(params)
    else
      super
    end
  end

  def after_sign_up_path_for(resource)
    root_path
  end
end
