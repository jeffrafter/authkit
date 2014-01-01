class PasswordResetController < ApplicationController
  def show
  end

  def create
    if user && user.send_reset_password
      logout

      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "We've sent an email which can be used to change your password"
          redirect_to login_path
        }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: ["Invalid user name or email"], status: "error" }, status: 422 }
        format.html {
          flash.now[:error] = "Invalid user name or email"
          render :show
        }
      end
    end
  end

  protected

  def user
    return @user if defined?(@user)
    username_or_email = "#{params[:email]}".downcase
    return if username_or_email.blank?
    @user = User.where('username = ? OR email = ?', username_or_email, username_or_email).first
  end
end
