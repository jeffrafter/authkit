class PasswordChangeController < ApplicationController
  before_filter :require_token

  def show
    respond_to do |format|
      format.json { head :no_content }
      format.html
    end
  end

  def create
    if @user.change_password(params[:password], params[:password_confirmation])
      login(@user)

      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash.now[:notice] = "Password updated successfully"
          redirect_to(root_path)
        }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @user.errors }.to_json, status: 422 }
        format.html { render :show }
      end
    end
  end
end
