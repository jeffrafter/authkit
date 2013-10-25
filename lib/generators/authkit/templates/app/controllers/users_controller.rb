class UsersController < ApplicationController
  before_filter :require_login, only: [:edit, :update]

  respond_to :html, :json

  # Signup
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
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
  end

  def update
    @user = current_user

    orig_unconfirmed_email = @user.unconfirmed_email

    if @user.update_attributes(user_params)
      # Send a new email confirmation if the user updated their email address
      if @user.unconfirmed_email.present? &&
         @user.unconfirmed_email != @user.email &&
         @user.unconfirmed_email != orig_unconfirmed_email
         @user.confirm_email
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

  def user_params
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
end
