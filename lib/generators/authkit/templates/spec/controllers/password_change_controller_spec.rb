require 'rails_helper'

describe PasswordChangeController do
  render_views

  let(:token) { "TOKEN" }
  let(:user) { build(:user, reset_password_token: token, reset_password_token_created_at: Time.now) }
  let(:valid_params) { {token: token, email: user.email} }
  let(:password_params) { valid_params.merge(password: 'newpassword', password_confirmation: 'newpassword') }

  describe "GET 'show'" do
    it "requires no user" do
      allow(controller).to receive(:email_user).and_return(user)
      expect(controller).to receive(:logout)
      get 'show', valid_params
    end

    it "requires an email user" do
      user.save
      get 'show', valid_params
      expect(assigns(:user).id).to eq(user.id)
    end

    it "redirects if there is no email user" do
      user.save
      expect {
        get 'show', {token: token, email: "invalid@example.com"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "requires a valid token" do
      allow(controller).to receive(:email_user).and_return(user)
      user.reset_password_token = "OTHER TOKEN"
      get 'show', valid_params
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    it "requires an unexpired token" do
      allow(controller).to receive(:email_user).and_return(user)
      user.reset_password_token_created_at = 1.year.ago
      get 'show', valid_params
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    it "returns http success" do
      allow(controller).to receive(:email_user).and_return(user)
      get 'show', valid_params
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "requires no user" do
      allow(controller).to receive(:email_user).and_return(user)
      expect(controller).to receive(:logout)
      get 'show', valid_params
    end

    it "requires an email user" do
      user.save
      post 'create', password_params
      expect(assigns(:user).id).to eq(user.id)
    end

    it "redirects if there is no email user" do
      user.save
      expect {
        get 'show', {token: token, email: "invalid@example.com"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "requires a valid token" do
      allow(controller).to receive(:email_user).and_return(user)
      user.reset_password_token = "OTHER TOKEN"
      post 'create', password_params
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    describe "with valid params" do
      before(:each) do
        allow(controller).to receive(:email_user).and_return(user)
      end

      it "changes the password" do
        expect {
          post 'create', password_params
        }.to change(user, :password_digest)

        expect(user).to be_valid
      end

      it "does not sign the user in" do
        expect(controller).to_not receive(:login)
        post 'create', password_params
      end

      it "redirects the user" do
        post 'create', password_params
        expect(response).to be_redirect
      end

      it "sets the flash" do
        post 'create', password_params
        expect(flash[:notice]).to match(/successfully/i)
      end

      describe "from json" do
        it "returns http success" do
          post 'create', password_params.merge(format: 'json')
          expect(response).to be_success
        end
      end
    end

    describe "with invalid params" do
      before(:each) do
        allow(controller).to receive(:email_user).and_return(user)
      end

      it "doesn't sign the user in" do
        expect(controller).to_not receive(:login)
        post 'create', {token: token, email: user.email, password: 'newpassword', password_confirmation: 'invalid'}
      end

      it "renders the show template" do
        post 'create', {token: token, email: user.email, password: 'newpassword', password_confirmation: 'invalid'}
        expect(response).to render_template(:show)
      end

      it "has errors" do
        post 'create', {token: token, email: user.email, password: 'newpassword', password_confirmation: 'invalid'}
        expect(user.errors[:password_confirmation].size).to eq(1)
      end

      describe "from json" do
        it "returns an error" do
          post 'create', {token: token, email: user.email, password: 'newpassword', password_confirmation: 'invalid', format: 'json'}
          expect(response.code).to eq('422')
          expect(response.body).to match(/doesn't match/i)
        end
      end
    end
  end
end
