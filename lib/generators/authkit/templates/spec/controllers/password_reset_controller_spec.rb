require 'spec_helper'

describe PasswordResetController do
  render_views

  let(:user) { create(:user, email: "test@example.com") }

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before(:each) do
      user
    end

    it "redirects the user" do
      post :create, {email: "test@example.com"}
      response.should be_redirect
    end

    it "finds the user by the email or user name" do
      post :create, {email: "test@example.com"}
      controller.send(:user).should == user
    end

    it "logs any current user out if it finds the user" do
      controller.should_receive(:logout)
      post :create, {email: "test@example.com"}
    end

    it "resets the password if it finds the user" do
      User.any_instance.should_receive(:send_reset_password).and_return(true)
      post :create, {email: "test@example.com"}
    end

    it "does not reset the password if it does not find a user" do
      User.any_instance.should_not_receive(:send_reset_password)
      post :create, {email: "unknown@example.com"}
    end

    it "downcases the email or user name" do
      User.any_instance.should_receive(:send_reset_password).and_return(true)
      post :create, {email: "TEST@EXAMPLE.COM"}
    end

    describe "from json" do
      it "returns http success" do
        post :create, {email: "test@example.com", format: "json"}
        response.should be_success
      end
    end

    describe "with invalid email" do
      describe "from html" do
        it "sets the flash message" do
          post :create, {email: "unknown@example.com"}
          flash.now[:error].should_not be_empty
        end

        it "renders the show page" do
          post :create, {email: "unknown@example.com"}
          response.should render_template(:show)
        end
      end

      describe "from json" do
        it "returns an error" do
          post :create, {email: "unknown@example.com", format: "json"}
          response.body.should =~ /invalid user name or email/i
        end

        it "returns forbidden status" do
          post :create, {email: "unknown@example.com", format: "json"}
          response.code.should == '422'
        end
      end
    end
  end
end
