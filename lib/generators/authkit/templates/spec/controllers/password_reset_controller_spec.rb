require 'spec_helper'

describe PasswordResetController do
  render_views

  let(:user_params) { { unconfirmed_email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:user) { User.new(user_params) }

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before(:each) do
      User.stub(:find_by_username_or_email).with("test@example.com").and_return(user)
      User.stub(:find_by_username_or_email).with("unknown@example.com").and_return(nil)
      user.stub(:persisted?).and_return(true)
      user.stub(:id).and_return(1)
    end

    it "redirects the user" do
      post :create, {email: "test@example.com"}
      response.should be_redirect
    end

    it "finds the user by the email or user name" do
      User.should_receive(:find_by_username_or_email).with("test@example.com").and_return(user)
      post :create, {email: "test@example.com"}
    end

    it "downcases the email or user name" do
      User.should_receive(:find_by_username_or_email).with("test@example.com").and_return(user)
      post :create, {email: "TEST@EXAMPLE.COM"}
    end

    it "logs any current user out if it finds the user" do
      controller.should_receive(:logout)
      post :create, {email: "test@example.com"}
    end

    it "resets the password if it finds the user" do
      user.should_receive(:reset_password).and_return(true)
      post :create, {email: "test@example.com"}
    end

    it "does not reset the password if it does not find a user" do
      User.any_instance.should_not_receive(:reset_password)
      post :create, {email: "unknown@example.com"}
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
