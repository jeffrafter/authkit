require 'spec_helper'

describe ApplicationController do
  before(:each) do
    User.stub(:find_by).with("1").and_return(user)
  end

  describe "current_user" do
    it "does not perform multiple finds"
    it "finds the current user in the session"
    it "finds the current user from the remember cookie"
    it "sets the time zone"
    it "returns nil if there is no current user"
    it "has a logged in helper method"
  end

  describe "tracking" do
    it "does not allows tracking if there is a do not track header"
    it "allows tracking if there is no do not track header"
  end

  describe "when requiring a user" do
    it "denies access if there is no user"
    it "stores the return path"
    describe "when responding to html" do
      it "sets the flash message"
      it "redirecs the user to login"
    end

    describe "when responding to json" do
      it "returns a forbidden status"
    end
  end

  describe "login" do
    it "tracks the login"
    it "remembers the user using a token and cookie"
    it "resets the session"
  end

  describe "logout" do
    it "resets the session"
    it "logs the user out"
    it "clears the remember token"
  end

  it "sets the timezone"
  it "sets the remember cookie"
  it "redirects to a stored session location if present"
end

