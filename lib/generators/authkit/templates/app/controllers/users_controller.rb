class UsersController < ApplicationController
  before_filter :login_required, only: [:edit, :update]

  # Signup
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      respond_to do |format|
        format.json { render head: :no_content }
        format.html {
          login(@user)
          redirect_to root_path
        }
      end
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if current_user.update_attributes(user_params)
      respond_to do |format|
        format.json { render head: :no_content }
        format.html {
          redirect_to current_user
        }
      end
    else
      render 'edit'
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
