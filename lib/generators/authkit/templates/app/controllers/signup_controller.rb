class SignupController < ApplicationController
  <% if oauth? %>include AuthsHelper
  <% end %>

  # Create a new Signup form model (found in app/forms/signup.rb)
  def new
    @signup = Signup.new
  end

  def create
    remember = params[:remember_me] == "1"

    @signup = Signup.new(signup_params)

    if @signup.save
      login(@signup.user, remember)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          redirect_to root_path
        }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @signup.errors }.to_json, status: 422 }
        format.html { render :new }
      end
    end
  end

  protected

  def signup_params
    params.require(:signup).permit(
      :email,
      <% if username? %>:username,
      <% end %>:password,
      :password_confirmation,
      :first_name,
      :last_name,
      :bio,
      :website,
      :phone_number,
      :time_zone)
  end
end

