class UsersController < ApplicationController
  before_filter :require_login, only: [:edit, :update]

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    orig_confirmation_email = @user.confirmation_email

    if @user.update_attributes(user_params)
      # Send a new email confirmation if the user updated their email address
      if @user.confirmation_email.present? &&
         @user.confirmation_email != @user.email &&
         @user.confirmation_email != orig_confirmation_email
         @user.send_confirmation
      end
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to account_path }
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
      :confirmation_email,
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
