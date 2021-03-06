require 'rails_helper'

RSpec.describe UsersController do
  render_views

  let(:user_session) { create(:user_session) }
  let(:user) { user_session.user }
  let(:user_params) { attributes_for(:user) }
  let(:invalid_params) { user_params.merge(password: 'newpassword', password_confirmation: 'wrongpassword') }
  let(:logged_in_session) { { user_session_id: user_session.id } }

  describe "GET 'edit'" do
    it "redirects if there is no current user" do
      get :edit
      expect(response).to be_redirect
    end

    it "edits the current user" do
      get :edit, session: logged_in_session
      expect(response).to be_success
    end
  end

  describe "PUT 'update'" do
    it "redirects if there is no current user" do
      put :update, params: { user: user_params.merge(first_name: "Alvarez") }
      expect(response).to be_redirect
    end

    describe "with valid params" do
      describe "when changing the email" do
        before(:each) do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "doesn't send the confirmation the email if unchanged" do
          user.email = user.confirmation_email
          user.confirmation_email = nil
          expect(user).to_not receive(:send_confirmation)
          put :update, params: { user: user_params.merge(confirmation_email: user.email) }, session: logged_in_session
        end

        it "doesn't reconfirm if the confirmation email is unchanged" do
          expect(user).to_not receive(:send_confirmation)
          put :update, params: { user: user_params.merge(confirmation_email: user.email) }, session: logged_in_session
        end

        it "confirms the confirmation email" do
          user.email = "old@example.com"
          expect(user).to receive(:send_confirmation).and_return(true)
          put :update, params: { user: user_params.merge(confirmation_email: "new@example.com") }, session: logged_in_session
        end
      end

      describe "from html" do
        before(:each) do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "updates the user" do
          expect {
            put :update, params: { user: user_params.merge(first_name: "Alvarez")}, session: logged_in_session
          }.to change(user, :first_name)
        end

        it "redirects the user" do
          put :update, params: { user: user_params }, session: logged_in_session
          expect(response).to be_redirect
        end
      end

      describe "from json" do
        before(:each) do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "updates the user" do
          expect {
            put :update, params: { user: user_params.merge(first_name: "Alvarez"), format: 'json' }, session: logged_in_session
          }.to change(user, :first_name)
        end
      end
    end

    describe "with invalid params" do
      before(:each) do
        allow(controller).to receive(:current_user).and_return(user)
      end

      describe "from html" do
        before(:each) do
          put :update, params: { user: invalid_params }, session: logged_in_session
        end

        it "sets the errors" do
          expect(user.errors[:password_confirmation].size).to eq(1)
        end
      end

      describe "from json" do
        before(:each) do
          put :update, params: { user: invalid_params, format: 'json' }, session: logged_in_session
        end

        it "returns a 422" do
          expect(response.code).to eq('422')
        end

        it "includes the errors in the json" do
          expect(user.errors[:password_confirmation].size).to eq(1)
          expect(response.body).to match(/doesn't match Password/i)
        end
      end
    end
  end
end

