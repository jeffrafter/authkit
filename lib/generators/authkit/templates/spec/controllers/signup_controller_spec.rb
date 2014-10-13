require 'rails_helper'

describe SignupController do
  render_views

  let(:signup_params) { attributes_for(:user) }
  let(:invalid_params) { signup_params.merge(password: 'newpassword', password_confirmation: 'wrongpassword') }

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      expect(response).to be_success
      expect(assigns(:signup)).to_not be_nil
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
          expect_any_instance_of(User).to receive(:send_confirmation)
          post :create, {signup: signup_params}, {}
        end

        it "signs the user in" do
          post :create, {signup: signup_params}, {}
          expect(controller.send(:current_user)).to eq(assigns(:signup).user)
        end

        it "remembers the user if remember me is chosen" do
          expect_any_instance_of(User).to receive(:set_remember_token)
          expect(controller).to receive(:set_remember_cookie)
          post :create, {signup: signup_params, remember_me: "1"}, {}
          expect(controller.send(:current_user)).to eq(assigns(:signup).user)
        end

        it "does not remember the user if remember me is not chosen" do
          expect_any_instance_of(User).to_not receive(:set_remember_token)
          expect(:controller).to_not receive(:set_remember_cookie)
          post :create, {signup: signup_params, remember_me: ""}, {}
          expect(controller.send(:current_user)).to eq(assigns(:signup).user)
        end

        it "redirects to the root" do
          post :create, {signup: signup_params}
          expect(response).to be_redirect
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
          expect(controller.send(:current_user)).to eq(assigns(:signup).user)
        end

        it "returns http success" do
          post :create, {signup: signup_params, format: 'json'}
          expect(response).to be_success
        end
      end
    end

    describe "with invalid params" do
      describe "from html" do
        it "renders the new page" do
          post :create, {signup: invalid_params}, {}
          expect(response).to render_template("new")
        end

        it "does not create a user" do
          expect {
            post :create, {signup: invalid_params}, {}
          }.to_not change(User, :count)
        end

        it "sets the errors" do
          post :create, {signup: invalid_params}, {}
          expect(assigns(:signup).errors[:password_confirmation].size).to eq(1)
        end
      end

      describe "from json" do
        it "returns a 422" do
          post :create, {signup: invalid_params, format: 'json'}, {}
          expect(response.code).to eq('422')
        end

        it "includes the errors in the json" do
          post :create, {signup: invalid_params, format: 'json'}, {}
          expect(assigns(:signup).errors[:password_confirmation].size).to eq(1)
          expect(response.body).to match(/doesn't match Password/i)
        end
      end
    end
  end
end

