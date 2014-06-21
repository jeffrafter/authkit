require 'spec_helper'

describe SignupController do
  render_views

  let(:signup_params) { attributes_for(:user) }
  let(:invalid_params) { signup_params.merge(password: 'newpassword', password_confirmation: 'wrongpassword') }

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
      assigns(:signup).should_not be_nil
    end
  end

  describe "POST 'create'" do
    describe "with valid params" do
      describe "from html" do
        it "creates a new user" do
          expect {
            post :create, {signup: signup_params}, {}
          }.to change(User, :count).by(1)
        end

        it "confirms the email" do
          User.any_instance.should_receive(:send_confirmation)
          post :create, {signup: signup_params}, {}
        end

        it "signs the user in" do
          post :create, {signup: signup_params}, {}
          controller.send(:current_user).should == assigns(:signup).user
        end

        it "remembers the user if remember me is chosen" do
          User.any_instance.should_receive(:set_remember_token)
          controller.should_receive(:set_remember_cookie)
          post :create, {signup: signup_params, remember_me: "1"}, {}
          controller.send(:current_user).should == assigns(:signup).user
        end

        it "does not remember the user if remember me is not chosen" do
          User.any_instance.should_not_receive(:set_remember_token)
          controller.should_not_receive(:set_remember_cookie)
          post :create, {signup: signup_params, remember_me: ""}, {}
          controller.send(:current_user).should == assigns(:signup).user
        end

        it "redirects to the root" do
          post :create, {signup: signup_params}
          response.should be_redirect
        end
      end

      describe "from json" do
        it "creates the user" do
          expect {
            post :create, {signup: signup_params, format: 'json'}, {}
          }.to change(User, :count).by(1)
        end

        it "signs the user in" do
          post :create, {signup: signup_params, format: 'json'}, {}
          controller.send(:current_user).should == assigns(:signup).user
        end

        it "returns http success" do
          post :create, {signup: signup_params, format: 'json'}
          response.should be_success
        end
      end
    end

    describe "with invalid params" do
      describe "from html" do
        it "renders the new page" do
          post :create, {signup: invalid_params}, {}
          response.should render_template("new")
        end

        it "does not create a user" do
          expect {
            post :create, {signup: invalid_params}, {}
          }.to_not change(User, :count)
        end

        it "sets the errors" do
          post :create, {signup: invalid_params}, {}
          assigns(:signup).should have(1).errors_on(:password_confirmation)
        end
      end

      describe "from json" do
        it "returns a 422" do
          post :create, {signup: invalid_params, format: 'json'}, {}
          response.code.should == '422'
        end

        it "includes the errors in the json" do
          post :create, {signup: invalid_params, format: 'json'}, {}
          assigns(:signup).should have(1).errors_on(:password_confirmation)
          response.body.should =~ /doesn't match Password/i
        end
      end
    end
  end
end

