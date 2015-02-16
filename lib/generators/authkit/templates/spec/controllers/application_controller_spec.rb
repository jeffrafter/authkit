require 'rails_helper'

describe ApplicationController do
  let(:user_session) { create(:user_session) }
  let(:user) { user_session.user }
  let(:logged_in_session) { { user_session_id: user_session.id } }
  let(:unknown_session) { { user_session_id: user_session.id + 1000000 } }

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
      expect(controller.send(:current_user)).to be_nil
    end
  end

  describe "current_user_session" do
    it "returns nil if there is no current user session" do
      get :new
      expect(controller.send(:current_user_session)).to be_nil
    end

    it "finds the current user session in the session" do
      get :new, {}, logged_in_session
      expect(controller.send(:current_user_session)).to eq(user_session)
    end

    it "finds the current user from the remember cookie" do
      cookies.signed[:remember] = user_session.remember_token
      get :index
      expect(controller.send(:current_user_session)).to eq(user_session)
    end

    it "sets the time zone" do
      expect_any_instance_of(User).to receive(:time_zone).and_return("Pacific Time (US & Canada)")
      get :index, {}, logged_in_session
      expect(Time.zone.name).to eq("Pacific Time (US & Canada)")
    end

    it "has a logged in helper method" do
      get :new, {}, logged_in_session
      expect(controller.send(:logged_in?)).to eq(true)
    end
  end

  describe "tracking" do
    it "does not allow tracking if there is a do not track header" do
      request.headers["DNT"] = "1"
      get :new
      expect(controller.send(:allow_tracking?)).to eq(false)
    end

    it "allows tracking if there is no do not track header" do
      get :new
      expect(controller.send(:allow_tracking?)).to eq(true)
    end
  end

  describe "when requiring a user" do
    it "allows access if there is a user" do
      get :index, {}, logged_in_session
      expect(response).to be_success
    end

    it "stores the return path" do
      get :index, {}
      expect(session[:return_url]).to eq("/anonymous")
    end

    describe "when responding to html" do
      it "sets the flash message" do
        get :index, {}
        expect(flash).to_not be_empty
      end

      it "redirecs the user to login" do
        get :index, {}
        expect(response).to be_redirect
      end
    end

    describe "when responding to json" do
      it "returns a forbidden status" do
        get :index, {format: :json}
        expect(response.code).to eq("403")
      end
    end
  end

  describe "login" do
    it "tracks the login" do
      get :new
      expect(user).to receive(:track_sign_in)
      controller.send(:login, user)
    end

    it "creates a session" do
      expect {
        get :new
        controller.send(:login, user, true)
      }.to change(UserSession, :count).by(1)
    end

    it "remembers the user using a token and cookie" do
      get :new
      expect(controller).to receive(:set_remember_cookie)
      controller.send(:login, user, true)
    end

    it "does not remember the user using a token and cookie when not requested" do
      get :new
      expect(controller).to_not receive(:set_remember_cookie)
      controller.send(:login, user, false)
    end

    it "resets the session" do
      get :new
      expect(controller).to receive(:reset_session)
      controller.send(:login, user)
    end
  end

  describe "logout" do
    it "resets the session" do
      get :index, {}, logged_in_session
      expect(controller).to receive(:reset_session)
      controller.send(:logout)
    end

    it "marks the user session as logged out" do
      get :index, {}, logged_in_session
      controller.send(:logout)
      expect(user_session.reload).to be_logged_out
    end

    it "logs the user out" do
      get :index, {}, logged_in_session
      controller.send(:logout)
      expect(controller.send(:current_user)).to be_nil
    end
  end

  it "sets the remember cookie" do
    request.env["action_dispatch.secret_token"] = "SECRET"
    get :new
    new_session = controller.send(:login, user, true)
    expect(cookies.permanent.signed[:remember]).to eq(new_session.remember_token)
  end

  it "redirects to a stored session location if present" do
    get :new, {}, {return_url: "/return"}
    expect(controller).to receive(:redirect_to).with("/return").and_return(true)
    controller.send(:redirect_back_or_default)
  end
end

