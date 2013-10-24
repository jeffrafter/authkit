class PasswordResetController < ApplicationController
  def show
  end

  def create
    username_or_email = "#{params[:email]}".downcase
    user = User.find_by_username_or_email(username_or_email) if username_or_email.present?

    if user && user.reset_password
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
end
