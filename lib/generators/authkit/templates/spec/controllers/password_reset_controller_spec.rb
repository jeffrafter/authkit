require 'rails_helper'

RSpec.describe PasswordResetController do
  render_views

  let(:user) { create(:user) }

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    before(:each) do
      user
    end

    it "redirects the user" do
      post :create, params: { email: user.email }
      expect(response).to be_redirect
    end

    it "finds the user by the email or user name" do
      post :create, params: { email: user.email }
      expect(controller.send(:user)).to eq(user)
    end

    it "logs any current user out if it finds the user" do
      expect(controller).to receive(:logout)
      post :create, params: { email: user.email }
    end

    it "resets the password if it finds the user" do
      expect_any_instance_of(User).to receive(:send_reset_password).and_return(true)
      post :create, params: { email: user.email }
    end

    it "does not reset the password if it does not find a user" do
      expect_any_instance_of(User).to_not receive(:send_reset_password)
      post :create, params: { email: "unknown@example.com" }
    end

    it "downcases the email or user name" do
      expect_any_instance_of(User).to receive(:send_reset_password).and_return(true)
      post :create, params: { email: user.email.upcase }
    end

    describe "from json" do
      it "returns http success" do
        post :create, params: { email: user.email, format: "json" }
        expect(response).to be_success
      end
    end

    describe "with invalid email" do
      describe "from html" do
        it "sets the flash message" do
          post :create, params: { email: "unknown@example.com" }
          expect(flash.now[:error]).to_not be_empty
        end
      end

      describe "from json" do
        it "returns an error" do
          post :create, params: { email: "unknown@example.com", format: "json" }
          expect(response.body).to match(/invalid user name or email/i)
        end

        it "returns forbidden status" do
          post :create, params: { email: "unknown@example.com", format: "json" }
          expect(response.code).to eq('422')
        end
      end
    end
  end
end
