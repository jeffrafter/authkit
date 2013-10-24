require 'spec_helper'

describe PasswordChangeController do
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

    it "returns http success" do
      User.should_receive(:user_from_token).with(token).and_return(user)
      get 'show', token: token
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "requires a valid token" do
      User.should_receive(:user_from_token).with(token).and_return(nil)
      post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword'}
      response.should be_redirect
      flash[:error].should_not be_empty
    end

    describe "with valid params" do
      before(:each) do
        User.should_receive(:user_from_token).with(token).and_return(user)
      end

      it "changes the password" do
        expect {
          post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword'}
        }.to change(user, :password_digest)

        user.should be_valid
      end

      it "signs the user in" do
        controller.should_receive(:login).with(user)
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword'}
      end

      it "redirects the user" do
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword'}
        response.should be_redirect
      end

      it "sets the flash" do
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword'}
        flash[:notice].should =~ /successfully/i
      end

      describe "from json" do
        it "returns http success" do
          post 'create', {token: token, password: 'newpassword', password_confirmation: 'newpassword', format: 'json'}
          response.should be_success
        end
      end
    end

    describe "with invalid params" do
      before(:each) do
        User.should_receive(:user_from_token).with(token).and_return(user)
      end

      it "doesn't sign the user in" do
        controller.should_not_receive(:login)
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'invalid'}
      end

      it "renders the show template" do
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'invalid'}
        response.should render_template(:show)
      end

      it "has errors" do
        post 'create', {token: token, password: 'newpassword', password_confirmation: 'invalid'}
        assigns(:user).should have(2).errors_on(:password_confirmation)
      end

      describe "from json" do
        it "returns an error" do
          post 'create', {token: token, password: 'newpassword', password_confirmation: 'invalid', format: 'json'}
          response.code.should == '422'
          response.body.should =~ /doesn't match/i
        end
      end
    end
  end
end
