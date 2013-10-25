class EmailConfirmationController < ApplicationController
  before_filter :require_token

  respond_to :html, :json

  def show
    @user.email_confirmed
    login(@user)
    flash[:notice] = "Thanks for confirming your email address"
    redirect_to root_path
  end
end

