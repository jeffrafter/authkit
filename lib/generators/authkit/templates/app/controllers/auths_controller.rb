# The AuthsController is used for connecting accounts only. The user must be logged
# in for the connection to work. This controller is not used for creating a new
# session.
class AuthsController < ApplicationController
  before_filter :require_login
  before_filter :require_auth_hash, only: [:callback]
  before_filter :require_auth_user, only: [:callback]

  def connect
  end

  def callback
    @auth ||= current_user.auths.build
    auth.attributes = {
      uid: auth_hash.uid,
      provider: auth_hash.provider,
      email: auth_hash.info.try(:email),
      verified_email: auth_hash.extra.try(:raw_info).try(:verified_email),
      token: auth_hash.credentials.try(:token),
      token_expires_at: auth_hash.credentials.try(:expires_at),
      refresh_token: auth_hash.credentials.try(:refresh_token),
      secret_token: auth_hash.credentials.try(:secret_token),
      env: auth_hash.to_json
    }
    if current_user.save
      redirect_to dashboard_path
    else
      flash[:error] = "Sorry, there was an error connecting this account"
      redirect_to root_path
    end
  end

  def disconnect
    @auth = current_user.auths.find(params[:id])
    @auth.destroy
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        redirect_to settings_path
      }
    end
  end

  def failure
    flash[:error] = "Sorry, there was an error connecting this account: #{params[:message]}"
    redirect_to dashboard_path
  end

  protected

  def auth
    return @auth if defined?(@auth)
    @auth = Auth.where(uid: auth_hash.uid, provider: auth_hash.provider).first
  end

  def auth_hash
    @auth_hash ||= request.env["omniauth.auth"]
  end

  def require_auth_hash
    if auth_hash.blank? || auth_hash.uid.blank? || auth_hash.provider.blank?
      deny_user("Sorry, there was an error connecting this account", root_path)
    end
  end

  def require_auth_user
    if auth && auth.user_id != current_user.id
      deny_user("Sorry, this account is already connected to another account", login_path)
    end
  end
end
