class InvitesController < ApplicationController
  def create
    email_sender = current_gestionnaire.email

    user = User.find_by_email(params[:email])
    invite = Invite.create(dossier_id: params[:dossier_id], user: user, email: params[:email].downcase, email_sender: email_sender)

    if invite.valid?
      InviteMailer.invite_user(invite).deliver_now!   unless invite.user.nil?
      InviteMailer.invite_guest(invite).deliver_now!  if     invite.user.nil?

      flash.notice = "Invitation envoyée (#{invite.email})"
    else
      flash.alert = invite.errors.full_messages.join('<br />').html_safe
    end

    if gestionnaire_signed_in?
      redirect_to url_for(controller: 'backoffice/dossiers', action: :show, id: params['dossier_id'])
      # else
      #   redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: params['dossier_id'])
    end
  end
end
