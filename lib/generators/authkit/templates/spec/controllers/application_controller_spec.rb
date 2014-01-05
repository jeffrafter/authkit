require 'spec_helper'

describe ApplicationController do
  let(:user) { create(:user) }
  let(:logged_in_session) { { user_id: user.id } }
  let(:unknown_session) { { user_id: user.id + 1000000 } }

  before(:each) do
    user
  end

  controller do
    before_filter :require_login, only: [:index]

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
      where = double
      where.stub(:first).and_return(nil)
      User.should_receive(:where).and_return(where)
      get :new, {}, unknown_session
      controller.send(:current_user).should be_nil
    end

    it "finds the current user in the session" do
      get :new, {}, logged_in_session
      controller.send(:current_user).should == user
    end

    it "finds the current user from the remember cookie" do
      user.save
      user.set_remember_token
      # Need to sign the cookie
      request.env["action_dispatch.secret_token"] = "SECRET"
      verifier = ActiveSupport::MessageVerifier.new(request.env["action_dispatch.secret_token".freeze])
      request.cookies[:remember] = verifier.generate(user.remember_token)
      get :index
      controller.send(:current_user).should == user
    end

    it "doesn't find the current user from the remember cookie if it is expired" do
      # Setup expired token
      user.set_remember_token
      user.remember_token_created_at = 1.year.ago
      user.save

      # Need to sign the cookie
      request.env["action_dispatch.secret_token"] = "SECRET"
      verifier = ActiveSupport::MessageVerifier.new(request.env["action_dispatch.secret_token".freeze])
      request.cookies[:remember] = verifier.generate(user.remember_token)
      get :index
      controller.send(:current_user).should be_nil
    end

    it "sets the time zone" do
      User.any_instance.should_receive(:time_zone).and_return("Pacific Time (US & Canada)")
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

  describe "login" do
    it "tracks the login" do
      get :new
      user.should_receive(:track_sign_in)
      controller.send(:login, user)
    end

    it "remembers the user using a token and cookie" do
      get :new
      controller.should_receive(:set_remember_cookie)
      user.should_receive(:set_remember_token)
      controller.send(:login, user, true)
    end

    it "does not remember the user using a token and cookie when not requested" do
      get :new
      controller.should_not_receive(:set_remember_cookie)
      user.should_not_receive(:set_remember_token)
      controller.send(:login, user, false)
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
      User.any_instance.should_receive(:clear_remember_token).and_return(:true)
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

