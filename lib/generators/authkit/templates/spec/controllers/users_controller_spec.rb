require 'spec_helper'

describe UsersController do
  render_views

  let(:user_params) { { unconfirmed_email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
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
    it "returns http success" do
      post :create, {user: user_params}
      response.should be_redirect
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get :edit, {}, logged_in_session
      response.should be_success
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      put 'update', {user: user_params}, logged_in_session
      response.should be_redirect
    end
  end
end

