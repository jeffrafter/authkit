class EmailConfirmationController < ApplicationController
  before_filter :require_token

  respond_to :html

  def show
    if @user.email_confirmed
      login(@user)
      flash[:notice] = "Thanks for confirming your email address"
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @user.errors }.to_json, status: 422 }
        format.html {
          flash[:error] = "Could not confirm email address because it is already in use"
          redirect_to root_path
        }
      end
    end
  end
end

