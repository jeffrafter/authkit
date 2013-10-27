class UsersController < ApplicationController
  before_filter :require_login, only: [:edit, :update]

  respond_to :html, :json

  # Signup
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)
    if @user.save
      @user.send_confirmation
      login(@user)
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @user.errors }.to_json, status: 422 }
        format.html { render :new }
      end
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    orig_confirmation_email = @user.confirmation_email

    if @user.update_attributes(user_update_params)
      # Send a new email confirmation if the user updated their email address
      if @user.confirmation_email.present? &&
         @user.confirmation_email != @user.email &&
         @user.confirmation_email != orig_confirmation_email
         @user.send_confirmation
      end
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to @user }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @user.errors }.to_json, status: 422 }
        format.html { render :edit }
      end
    end
  end

  protected

  # It would be nice to find a strategy to merge these. The only difference is that
  # when signing up you are setting the email, and when changing your settings you
  # are setting the confirmation email.

  def user_create_params
    params.require(:user).permit(
      :email,
      :username,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :bio,
      :website,
      :phone_number,
      :time_zone)
  end

  def user_update_params
    params.require(:user).permit(
      :confirmation_email,
      :username,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :bio,
      :website,
      :phone_number,
      :time_zone)
  end
end
