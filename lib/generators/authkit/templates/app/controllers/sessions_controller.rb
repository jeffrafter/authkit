class SessionsController < ApplicationController
  # Login
  def new
  end

  def create
    username_or_email = "#{params[:email]}".downcase
    user = User.find_by_username_or_email(username_or_email) if username_or_email.present?

    if user && user.authenticate(params[:password])
      login(user)
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_back_or_default }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: ["Invalid user name or password"], status: "error" }, status: 422 }
        format.html {
          flash.now[:error] = "Invalid user name or password"
          render :new
        }
      end
    end
  end

  # Logout
  def destroy
    logout
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to root_path }
    end
  end
end
