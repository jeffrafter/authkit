class EmailConfirmationController < ApplicationController
  before_filter :require_token

  def show
    # TODO check for confirm token expiry?
    @user.confirm_email

    login(@user)
    flash[:notice] = "Thanks for confirming your email address"
    redirect_to root_path
  end
end

