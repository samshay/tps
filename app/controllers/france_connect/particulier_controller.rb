class FranceConnect::ParticulierController < ApplicationController

  def login
    client = FranceConnectParticulierClient.new

    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    authorization_uri = client.authorization_uri(
        scope: [:profile, :email],
        state: session[:state],
        nonce: session[:nonce]
    )
    redirect_to URI.parse(authorization_uri).to_s
  end

  def callback
    return redirect_to new_user_session_path unless params.has_key?(:code)

    user_infos = FranceConnectService.retrieve_user_informations_particulier(params[:code])

    unless user_infos.nil?
      france_connect_information = FranceConnectInformation.find_by_france_connect_particulier user_infos

      france_connect_information = FranceConnectInformation.create(
          {gender: user_infos[:gender],
           given_name: user_infos[:given_name],
           family_name: user_infos[:family_name],
           email_france_connect: user_infos[:email],
           birthdate: user_infos[:birthdate],
           birthplace: user_infos[:birthplace],
           france_connect_particulier_id: user_infos[:france_connect_particulier_id]}
      ) if france_connect_information.nil?

      user = france_connect_information.user
      salt = FranceConnectSaltService.new(france_connect_information).salt

      return redirect_to france_connect_particulier_new_path(fci_id: france_connect_information.id, salt: salt) if user.nil?

      connect_france_connect_particulier user
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  def new
    return redirect_france_connect_error_connection unless valid_salt_and_fci_id_params?

    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    @user = User.new(france_connect_information: france_connect_information).decorate
  rescue ActiveRecord::RecordNotFound
    redirect_france_connect_error_connection
  end

  def check_email
    return redirect_france_connect_error_connection unless valid_salt_and_fci_id_params?

    user = User.find_by_email(params[:user][:email_france_connect])

    return create if user.nil?

    unless params[:user][:password].nil?

      if user.valid_password?(params[:user][:password])
        user.france_connect_information = FranceConnectInformation.find(params[:fci_id])

        return connect_france_connect_particulier user
      else
        flash.now.alert = 'Mot de passe invalide'
      end
    end

    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    france_connect_information.update_attribute(:email_france_connect, params[:user][:email_france_connect])

    @user = User.new(france_connect_information: france_connect_information).decorate
  end

  def create
    user = User.new email: params[:user][:email_france_connect]
    user.password = Devise.friendly_token[0, 20]

    unless user.valid?
      flash.alert = 'Email non valide'
      return redirect_to france_connect_particulier_new_path fci_id: params[:fci_id], salt: params[:salt], user: params[:user]
    end

    user.save
    FranceConnectInformation.find(params[:fci_id]).update_attribute(:user, user)

    connect_france_connect_particulier user
  end

  private

  def connect_france_connect_particulier user
    sign_out :user if user_signed_in?
    sign_out :gestionnaire if gestionnaire_signed_in?
    sign_out :administrateur if administrateur_signed_in?

    sign_in user

    user.loged_in_with_france_connect = 'particulier'
    user.save

    redirect_to stored_location_for(current_user) || signed_in_root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  def valid_salt_and_fci_id_params?
    france_connect_information = FranceConnectInformation.find(params[:fci_id])
    FranceConnectSaltService.new(france_connect_information).valid? params[:salt]
  end
end