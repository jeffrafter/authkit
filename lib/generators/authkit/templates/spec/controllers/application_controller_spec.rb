require 'spec_helper'

describe ApplicationController do
  let(:user_params) { { email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:user) { User.new(user_params) }
  let(:logged_in_session) { { user_id: "1" } }
  let(:unknown_session) { { user_id: "2" } }

  before(:each) do
    User.stub(:find_by).with("1").and_return(user)
  end

  controller do
    before_filter :require_login, only: [:index]
    before_filter :require_token, only: [:show]

    def new
      head :ok
    end

    def index
      head :ok
    end

    def show
      head :ok
    end
  end

  describe "current_user" do
    it "returns nil if there is no current user" do
      get :new
      controller.send(:current_user).should be_nil
    end

    it "does not perform multiple finds" do
      User.should_receive(:find_by)
      get :new, {}, unknown_session
      controller.send(:current_user).should be_nil
    end

    it "finds the current user in the session" do
      get :new, {}, logged_in_session
      controller.send(:current_user).should == user
    end

    it "finds the current user from the remember cookie" do
      # Need to sign the cookie
      request.env["action_dispatch.secret_token"] = "SECRET"
      verifier = ActiveSupport::MessageVerifier.new(request.env["action_dispatch.secret_token".freeze])
      request.cookies[:remember] = verifier.generate("TOKEN")
      User.should_receive(:user_from_remember_token).with("TOKEN").and_return(user)
      get :index
      controller.send(:current_user).should == user
    end

    it "sets the time zone" do
      user.should_receive(:time_zone).and_return("Pacific Time (US & Canada)")
      get :index, {}, logged_in_session
      Time.zone.name.should == "Pacific Time (US & Canada)"
    end

    it "has a logged in helper method" do
      get :new, {}, logged_in_session
      controller.should be_logged_in
    end
  end

  describe "tracking" do
    it "does not allow tracking if there is a do not track header" do
      request.headers["DNT"] = "1"
      get :new
      controller.send(:allow_tracking?).should == false
    end

    it "allows tracking if there is no do not track header" do
      get :new
      controller.send(:allow_tracking?).should == true
    end
  end

  describe "when requiring a user" do
    it "allows access if there is a user" do
      get :index, {}, logged_in_session
      response.should be_success
    end

    it "stores the return path" do
      get :index, {}
      session[:return_url].should == "/anonymous"
    end

    describe "when responding to html" do
      it "sets the flash message" do
        get :index, {}
        flash.should_not be_empty
      end

      it "redirecs the user to login" do
        get :index, {}
        response.should be_redirect
      end
    end

    describe "when responding to json" do
      it "returns a forbidden status" do
        get :index, {format: :json}
        response.code.should == "403"
      end
    end
  end

  describe "tokens" do
    it "requires a user token" do
      User.should_receive(:user_from_token).with('testtoken').and_return(user)
      get 'show', {id: '1',  token: 'testtoken'}
    end

    it "returns an error if there is no user token" do
      User.should_receive(:user_from_token).with('testtoken').and_return(nil)
      controller.should_receive(:deny_user)
      get 'show', {id: '1',  token: 'testtoken'}
    end

    it "verifies the token" do
      request.env["action_dispatch.secret_token"] = "SECRET"
      verifier = ActiveSupport::MessageVerifier.new(request.env["action_dispatch.secret_token".freeze])
      token = verifier.generate("TOKEN")
      User.should_receive(:user_from_token).with(token).and_return(user)
      get 'show', {id: '1', token: token}
    end
  end

  describe "login" do
    it "tracks the login" do
      get :new
      user.should_receive(:track_sign_in)
      controller.send(:login, user)
    end

    it "remembers the user using a token and cookie" do
      get :new
      controller.should_receive(:set_remember_cookie)
      user.should_receive(:set_token).with(:remember_token).and_return(:true)
      controller.send(:login, user)
    end

    it "resets the session" do
      get :new
      controller.should_receive(:reset_session)
      controller.send(:login, user)
    end
  end

  describe "logout" do
    it "resets the session" do
      get :index, {}, logged_in_session
      controller.should_receive(:reset_session)
      controller.send(:logout)
    end

    it "logs the user out" do
      get :index, {}, logged_in_session
      controller.send(:logout)
      controller.send(:current_user).should be_nil
    end

    it "clears the remember token" do
      get :index, {}, logged_in_session
      user.should_receive(:clear_remember_token).and_return(:true)
      controller.send(:logout)
    end
  end

  it "sets the remember cookie" do
    request.env["action_dispatch.secret_token"] = "SECRET"
    get :new
    controller.send(:login, user)
    cookies.permanent.signed[:remember].should == user.remember_token
  end

  it "redirects to a stored session location if present" do
    get :new, {}, {return_url: "/return"}
    controller.should_receive(:redirect_to).with("/return").and_return(true)
    controller.send(:redirect_back_or_default)
  end
end

