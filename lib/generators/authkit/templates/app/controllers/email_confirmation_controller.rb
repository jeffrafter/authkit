class EmailConfirmationController < ApplicationController
  before_filter :require_login
  before_filter :require_token

  respond_to :html

  def show
    if current_user.email_confirmed
      # Do not automatically log in the user
      flash[:notice] = "Thanks for confirming your email address"

      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: current_user.errors }.to_json, status: 422 }
        format.html {
          flash[:error] = "Could not confirm email address because it is already in use"
          redirect_to root_path
        }
      end
    end
  end

  protected

  # Confirmation tokens confirm an email address. It is conceivable
  # that an attacker might choose an address out of their control and attempt to
  # brute-force a confirmation. By default this gains the attacker nothing.
  #
  # It is possible to consider failed confirmation tokens failed attempts and
  # lock the account.
  def require_token
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_key_base)
    valid = params[:token].present? && current_user.confirmation_token.present?
    valid = valid && verifier.send(:secure_compare, params[:token], current_user.confirmation_token)
    valid = valid && !current_user.confirmation_token_expired?
    deny_user("Invalid token", root_path) unless valid
  end
end

