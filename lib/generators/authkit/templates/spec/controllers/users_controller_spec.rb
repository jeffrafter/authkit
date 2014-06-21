require 'spec_helper'

describe UsersController do
  render_views

  let(:user) { create(:user, email: "test@example.com") }
  let(:user_params) { attributes_for(:user) }
  let(:invalid_params) { user_params.merge(password: 'newpassword', password_confirmation: 'wrongpassword') }
  let(:logged_in_session) { { user_id: user.id } }

  describe "GET 'edit'" do
    it "redirects if there is no current user" do
      get :edit
      response.should be_redirect
    end

    it "edits the current user" do
      get :edit, {}, logged_in_session
      response.should be_success
    end
  end

  describe "PUT 'update'" do
    it "redirects if there is no current user" do
      put :update, {user: user_params.merge(first_name: "Alvarez")}
      response.should be_redirect
    end

    describe "with valid params" do
      describe "when changing the email" do
        before(:each) do
          controller.stub(:current_user).and_return(user)
        end

        it "doesn't send the confirmation the email if unchanged" do
          user.email = user.confirmation_email
          user.confirmation_email = nil
          user.should_not_receive(:send_confirmation)
          put :update, {user: user_params.merge(confirmation_email: "test@example.com")}, logged_in_session
        end

        it "doesn't reconfirm if the confirmation email is unchanged" do
          user.should_not_receive(:send_confirmation)
          put :update, {user: user_params.merge(confirmation_email: "test@example.com")}, logged_in_session
        end

        it "confirms the confirmation email" do
          user.email = "old@example.com"
          user.should_receive(:send_confirmation).and_return(true)
          put :update, {user: user_params.merge(confirmation_email: "new@example.com")}, logged_in_session
        end
      end

      describe "from html" do
        before(:each) do
          controller.stub(:current_user).and_return(user)
        end

        it "updates the user" do
          expect {
            put :update, {user: user_params.merge(first_name: "Alvarez")}, logged_in_session
          }.to change(user, :first_name)
        end

        it "redirects the user" do
          put :update, {user: user_params}, logged_in_session
          response.should be_redirect
        end
      end

      describe "from json" do
        before(:each) do
          controller.stub(:current_user).and_return(user)
        end

        it "updates the user" do
          expect {
            put :update, {user: user_params.merge(first_name: "Alvarez"), format: 'json'}, logged_in_session
          }.to change(user, :first_name)
        end
      end
    end

    describe "with invalid params" do
      before(:each) do
        controller.stub(:current_user).and_return(user)
      end

      describe "from html" do
        before(:each) do
          put :update, {user: invalid_params}, logged_in_session
        end

        it "renders the edit page" do
          response.should render_template('edit')
          response.should be_success
        end

        it "sets the errors" do
          user.should have(1).errors_on(:password_confirmation)
        end
      end

      describe "from json" do
        before(:each) do
          put :update, {user: invalid_params, format: 'json'}, logged_in_session
        end

        it "returns a 422" do
          response.code.should == '422'
        end

        it "includes the errors in the json" do
          user.should have(1).errors_on(:password_confirmation)
          response.body.should =~ /doesn't match Password/i
        end
      end
    end
  end
end

