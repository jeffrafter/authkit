class UsersController < ApplicationController
  before_filter :require_login, only: [:edit, :update]

  # Signup
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)
    if @user.save
      @user.confirm_email
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
    # Set the unconfirmed email for displaying on the form
    @user.unconfirmed_email ||= @user.email
  end

  def update
    @user = current_user
    # Set the unconfirmed email for displaying on the form
    @user.unconfirmed_email ||= @user.email

    if email_params[:unconfirmed_email].present? &&
       email_params[:unconfirmed_email] != @user.email &&
       email_params[:unconfirmed_email] != @user.unconfirmed_email
      # Assign the updated email before validation in case it is invalid
      @user.unconfirmed_email = email_params[:unconfirmed_email]
      # Don't actually confirm until after validation
      @confirm_email = true
    end

    if @user.update_attributes(user_update_params)
      @user.confirm_email if @confirm_email
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

  def user_create_params
    params.require(:user).permit(
      :unconfirmed_email,
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

  def email_params
    params.require(:user).permit(
      :unconfirmed_email)
  end
end
