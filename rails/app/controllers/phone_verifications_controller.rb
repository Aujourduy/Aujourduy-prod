class PhoneVerificationsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Formulaire d'entrée : téléphone et/ou code OTP
  end

  def create
    if current_user.phone.blank?
      redirect_to new_phone_verification_path, alert: "Veuillez renseigner un numéro de téléphone." and return
    end

    unless current_user.can_request_new_code?
      redirect_to new_phone_verification_path, alert: "Veuillez attendre avant de redemander un code." and return
    end

    channel = params[:channel] == "call" ? "call" : "sms"

    begin
      client.verify
            .services(ENV["TWILIO_VERIFY_SID"])
            .verifications
            .create(to: current_user.normalized_phone, channel: channel)

      current_user.mark_code_sent!
      flash[:notice] = "Un code vous a été envoyé par #{channel == 'sms' ? 'SMS' : 'appel vocal'}."
    rescue StandardError => e
      Rails.logger.error "Erreur Twilio Verify: #{e.message}"
      flash[:alert] = "Impossible d'envoyer le code. Réessayez plus tard."
    end

    redirect_to new_phone_verification_path
  end

  def verify
    if params[:code].blank?
      redirect_to new_phone_verification_path, alert: "Veuillez entrer le code reçu." and return
    end

    begin
      check = client.verify
                    .services(ENV["TWILIO_VERIFY_SID"])
                    .verification_checks
                    .create(to: current_user.normalized_phone, code: params[:code])

      if check.status == "approved"
        current_user.mark_phone_as_verified!
        redirect_to dashboard_path, notice: "Votre téléphone a été validé avec succès."
      else
        current_user.increment_verification_attempts!
        redirect_to new_phone_verification_path, alert: "Code invalide, veuillez réessayer."
      end
    rescue StandardError => e
      Rails.logger.error "Erreur Twilio Verify: #{e.message}"
      redirect_to new_phone_verification_path, alert: "Erreur lors de la vérification du code."
    end
  end

  private

  def client
    @client ||= Twilio::REST::Client.new(
      ENV["TWILIO_ACCOUNT_SID"],
      ENV["TWILIO_AUTH_TOKEN"]
    )
  end
end
