require 'spec_helper'

describe UsersController do
  render_views

  let(:user_params) { { unconfirmed_email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:invalid_params) { user_params.merge(password: 'newpassword', password_confirmation: 'wrongpassword') }
  let(:user) { User.new(user_params) }
  let(:logged_in_session) { { user_id: "1" } }

  before(:each) do
    User.stub(:find_by).with("1").and_return(user)
  end

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
      assigns(:user).should be_a_new(User)
    end
  end

  describe "POST 'create'" do
    describe "with valid params" do
      describe "from html" do
        it "creates a new user" do
          expect {
            post :create, {user: user_params}, {}
          }.to change(User, :count).by(1)
        end

        it "confirms the email" do
          User.any_instance.should_receive(:confirm_email)
          post :create, {user: user_params}, {}
        end

        it "signs the user in" do
          post :create, {user: user_params}, {}
          controller.send(:current_user).should == assigns(:user)
        end

        it "redirects to the root" do
          post :create, {user: user_params}
          response.should be_redirect
        end
      end

      describe "from json" do
        it "creates the user" do
          expect {
            post :create, {user: user_params, format: 'json'}, {}
          }.to change(User, :count).by(1)
        end

        it "signs the user in" do
          post :create, {user: user_params, format: 'json'}, {}
          controller.send(:current_user).should == assigns(:user)
        end

        it "returns http success" do
          post :create, {user: user_params, format: 'json'}
          response.should be_success
        end
      end
    end

    describe "with invalid params" do
      describe "from html" do
        it "renders the new page" do
          post :create, {user: invalid_params}, {}
          response.should render_template("new")
        end

        it "does not create a user" do
          expect {
            post :create, {user: invalid_params}, {}
          }.to_not change(User, :count)
        end

        it "sets the errors" do
          post :create, {user: invalid_params}, {}
          assigns(:user).should have(2).errors_on(:password_confirmation)
        end
      end

      describe "from json" do
        it "returns a 422" do
          post :create, {user: invalid_params, format: 'json'}, {}
          response.code.should == '422'
        end

        it "includes the errors in the json" do
          post :create, {user: invalid_params, format: 'json'}, {}
          assigns(:user).should have(2).errors_on(:password_confirmation)
          response.body.should =~ /doesn't match Password/i
        end
      end
    end
  end

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
        it "doesn't confirm the email if unchanged" do
          user.email = user.unconfirmed_email
          user.unconfirmed_email = nil
          user.should_not_receive(:confirm_email)
          put :update, {user: user_params.merge(unconfirmed_email: "test@example.com")}, logged_in_session
        end

        it "doesn't reconfirm if the unconfirmed email is already set" do
          user.should_not_receive(:confirm_email)
          put :update, {user: user_params.merge(unconfirmed_email: "test@example.com")}, logged_in_session
        end

        it "confirms the unconfirmed email" do
          user.email = "old@example.com"
          user.should_receive(:confirm_email).and_return(true)
          put :update, {user: user_params.merge(unconfirmed_email: "new@example.com")}, logged_in_session
        end
      end

      describe "from html" do
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
        it "updates the user" do
          expect {
            put :update, {user: user_params.merge(first_name: "Alvarez"), format: 'json'}, logged_in_session
          }.to change(user, :first_name)
        end
      end
    end

    describe "with invalid params" do
      describe "from html" do
        before(:each) do
          put :update, {user: invalid_params}, logged_in_session
        end

        it "renders the edit page" do
          response.should render_template('edit')
          response.should be_success
        end

        it "sets the errors" do
          user.should have(2).errors_on(:password_confirmation)
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
          user.should have(2).errors_on(:password_confirmation)
          response.body.should =~ /doesn't match Password/i
        end
      end
    end
  end
end

