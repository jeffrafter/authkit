class SessionsController < ApplicationController
  <% if oauth? %>
  include AuthsHelper
  <% end %>

  # Login
  def new
  end

  def create
    remember = params[:remember_me] == "1"

    if user && user.authenticate(params[:password])
      login(user, remember)
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

  protected

  def user
    return @user if defined?(@user)
    username_or_email = "#{params[:email]}".downcase
    return if username_or_email.blank?
    @user = User.where('LOWER(username) = ? OR email = ?', username_or_email, username_or_email).first
  end
end
