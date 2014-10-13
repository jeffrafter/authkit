require 'rails_helper'

describe EmailConfirmationController do
  render_views

  let(:user) { build(:user) }
  let(:token) { "TOKEN" }

  describe "GET 'show'" do
    it "requires a login" do
      allow(controller).to receive(:current_user).and_return(nil)
      get 'show', token: token
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    it "requires a valid token" do
      user.confirmation_token = "OTHER TOKEN"
      allow(controller).to receive(:current_user).and_return(user)
      get 'show', token: token
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    it "requires an unexpired token" do
      user.confirmation_token = token
      user.confirmation_token_created_at = 4.days.ago
      allow(controller).to receive(:current_user).and_return(user)
      get 'show', token: token
      expect(response).to be_redirect
      expect(flash[:error]).to_not be_empty
    end

    describe "with a valid token" do
      before(:each) do
        user.confirmation_email = "new@example.com"
        user.confirmation_token = token
        user.confirmation_token_created_at = Time.now
        allow(controller).to receive(:current_user).and_return(user)
      end

      describe "when the confirmation is successful" do
        it "confirms the user email" do
          expect(user).to receive(:email_confirmed).and_return(true)
          get 'show', token: token
        end

        it "does not sign the user in" do
          expect(controller).to_not receive(:login)
          get 'show', token: token
        end

        it "sets the flash" do
          get 'show', token: token
          expect(flash[:notice]).to_not be_nil
        end

        it "redirects the user" do
          get 'show', token: token
          expect(response).to be_redirect
        end

        describe "from json" do
          it "returns http success" do
            get 'show', token: token, format: 'json'
            expect(response).to be_success
          end
        end

      end

      describe "when the confirmation is not successful" do
        before(:each) do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "handles invalid confirmations" do
          user.should_receive(:email_confirmed).and_return(false)
          get 'show', token: token
          expect(flash[:error]).to_not be_empty
          expect(response).to be_redirect
        end

        describe "from json" do
          it "returns a 422" do
            expect(user).to receive(:email_confirmed).and_return(false)
            get 'show', token: token, format: 'json'
            expect(response.code).to eq('422')
          end
        end

      end
    end
  end
end
