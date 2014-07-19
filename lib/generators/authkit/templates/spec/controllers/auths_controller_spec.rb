require 'spec_helper'

describe AuthsController do
  render_views

  describe "GET 'connect'" do
    it "returns http success" do
      get :connect
      response.should be_success
    end

    it "requires login"
  end

  describe "POST 'callback'" do
    it "returns http success" do
      get :connect
      response.should be_success
    end

    it "validates the authenticity of the omniauth hash"
    it "requires login when connecting"
    it "does not require login when signing up or signing in"
    it "requires an auth hash"
    it "finds an existing auth"

    describe "when connecting" do
      it "does not log out the user"
      it "redirects to the settings path if the user has already connected the auth"
      it "does not connect the auth if it is already connected to another user"
      it "creates a new auth and connects it to the user"
      it "redirects to the account path"
      it "adds a flash message if there is an error"
    end

    describe "when signing in or singning up" do
      it "logs out any currently logged in user"
      it "logs in the auth user if found"

      # This is a pessimistic protection. We assume that if another user already has the
      # same email address then it is likely that the user is about to create two accounts
      # and force them to sign in to the original account to connect the accounts.
      # You could automatically merge the two together, but if you do not require
      # email confirmation this presents a case where a malicious user could sign up using
      # an email address they do not control, then when the actual user connects their account
      # the malicious user would have access via the email and password they setup.
      it "fails if the email address associated with the account is already attached to another user"
      it "creates a new user using the auth"
      it "logs the user in when signing up"
      it "redirects to the accounts path"
      it "redirects to the signup path with errors"
    end

    describe "DELETE 'callback'" do
      # If you do not require a completed login, it is possible for a user to disconnect
      # their only means of authentication
      it "requires a completed login"
      it "finds the auth"
      it "destroys the auth"
      it "redirects to the account path"
    end

    describe "POST 'failure'" do
      it "redirects to settings path if connecting"
      it "redirects to signup path if signing up"
      it "redirects to login path if logging in"
      it "sets the flash error"
    end

  end
end

