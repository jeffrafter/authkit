require 'spec_helper'

describe EmailConfirmationController do
  render_views

  let(:user_params) { { unconfirmed_email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:user) { User.new(user_params) }
  let(:token) { "TOKEN" }

  describe "GET 'show'" do
    it "requires a valid token" do
      User.should_receive(:user_from_token).with(token).and_return(nil)
      get 'show', token: token
      response.should be_redirect
      flash[:error].should_not be_empty
    end

    describe "with a valid token" do
      it "confirms the user email" do
        User.should_receive(:user_from_token).with(token).and_return(user)
        user.should_receive(:confirm_email)
        get 'show', token: token
      end

      it "signs the user in" do
        User.should_receive(:user_from_token).with(token).and_return(user)
        controller.should_receive(:login).with(user)
        get 'show', token: token
      end

      it "redirects the user" do
        User.should_receive(:user_from_token).with(token).and_return(user)
        get 'show', token: token
        response.should be_redirect
      end

      it "sets the flash" do
        User.should_receive(:user_from_token).with(token).and_return(user)
        get 'show', token: token
        flash[:notice].should_not be_empty
      end
    end
  end
end
