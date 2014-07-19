# The AuthsController is used for connecting accounts only. The user must be logged
# in for the connection to work. This controller is not used for creating a new
# session.
class AuthsController < ApplicationController
  before_filter :require_login, only: [:connect]
  before_filter :require_login_when_connecting, only: [:callback]
  before_filter :require_completed_login, only: [:disconnect]
  before_filter :require_auth_hash, only: [:callback]

  # Adjust scope here for particular sets of user using the session
  #
  #   session[:google_oauth_scope] = 'userinfo.email, userinfo.profile, adsense, adsense.readonly'
  #
  #  You can also reset it to the default using nil
  def connect
  end

  def callback
    # If we are not connecting we want to logout any existing user
    logout unless connecting?

    if connecting?
      if auth && auth.user == current_user
        # This is an auth that is already connected to this user (success, noop)
        redirect_to settings_path
      elsif auth && auth.user_id != current_user.id
        # This is an auth that is connected to another user (error)
        deny_user("Sorry, this account is already connected to another account", settings_path)
      else
        # Success, add the auth and redirect to settings
        @auth ||= current_user.auths.build(auth_params)

        if current_user.save
          redirect_to account_path
        else
          flash[:error] = "Sorry, there was an error connecting this account"
          redirect_to accounts_path
        end
      end
    else
      # Could have a check here for login/sign up action to be explicit
      #
      # If login and auth does not exist, confirm that they want to signup (not attach)
      # If signup and auth exists, confirm that they have selected the right account (already exists)
      if auth
        login(auth.user)
        redirect_to account_path
      elsif auth_email.present? && User.where(email: auth_email.downcase).count > 0
        deny_user("Sorry, the email address associated with this account is already connected to an existing user", signup_path)
      else
        @signup = Signup.new_with_oauth(auth_params, {kind: @kind})

        if signup.save
          login(signup.user)
          redirect_to account_path
        else
          flash[:error] = "Sorry, there was an error connecting this account (#{@signup.errors.full_messages.to_sentence})"
          redirect_to signup_path
        end
      end
    end
  end

  def disconnect
    # TODO: you may want to change this lookup to use uid and provider
    @auth = current_user.auths.where(params[:id])
    @auth.destroy
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        redirect_to accounts_path
      }
    end
  end

  def failure
    flash[:error] = "Sorry, there was an error connecting this account: #{params[:message]}"
    if connecting?
      redirect_to settings_path
    elsif signing_up?
      redirect_to signup_path
    else
      redirect_to login_path
    end
  end

  protected

  def signup
    return @signup if defined?(@signup)
  end

  def auth
    return @auth if defined?(@auth)
    @auth = Auth.where(uid: auth_hash.uid, provider: auth_hash.provider).first
  end

  def auth_hash
    @auth_hash ||= request.env["omniauth.auth"]
  end

  def auth_email
    auth_hash.info.try(:email) || auth_hash.extra.try(:raw_info).try(:verified_email)
  end

  def auth_params
    HashWithIndifferentAccess.new({
      uid: auth_hash.uid,
      provider: auth_hash.provider,
      email: auth_hash.info.try(:email),
      verified_email: auth_hash.extra.try(:raw_info).try(:verified_email),
      token: auth_hash.credentials.try(:token),
      token_expires_at: auth_hash.credentials.try(:expires_at),
      refresh_token: auth_hash.credentials.try(:refresh_token),
      secret_token: auth_hash.credentials.try(:secret_token),
      env: auth_hash.to_json
    })
  end

  def require_auth_hash
    if auth_hash.blank? || auth_hash.uid.blank? || auth_hash.provider.blank?
      deny_user("Sorry, there was an error connecting this account", root_path)
    end
  end

  def require_login_when_connecting
    if connecting? && !logged_in?
      deny_user("Sorry, you must be logged in to connect this account", login_path)
    end
  end

  def connecting?
    env['omniauth.params']['connect'].present?
  end

  def logging_in?
    env['omniauth.params']['login'].present?
  end

  def signing_up?
    env['omniauth.params']['signup'].present?
  end
end

