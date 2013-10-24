require 'spec_helper'

describe SessionsController do
  render_views

  let(:user_params) { { unconfirmed_email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:user) { User.new(user_params) }
  let(:logged_in_session) { { user_id: "1" } }

  before(:each) do
    User.stub(:find_by).with("1").and_return(user)
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before(:each) do
      User.stub(:find_by_username_or_email).with("test@example.com").and_return(user)
      User.stub(:find_by_username_or_email).with("unknown@example.com").and_return(nil)
    end

    it "redirects the user" do
      post :create, {email: "test@example.com", password: "example"}
      response.should be_redirect
    end

    it "looks finds the user by the email or user name" do
      User.should_receive(:find_by_username_or_email).with("test@example.com").and_return(user)
      post :create, {email: "test@example.com", password: "example"}
    end

    it "downcases the email or user name" do
      User.should_receive(:find_by_username_or_email).with("test@example.com").and_return(user)
      post :create, {email: "TEST@EXAMPLE.COM", password: "example"}
    end

    it "authenticates if it finds the user" do
      user.should_receive(:authenticate).and_return(true)
      post :create, {email: "test@example.com", password: "example"}
    end

    it "does not authenticate if it does not find a user" do
      User.any_instance.should_not_receive(:authenticate)
      post :create, {email: "unknown@example.com", password: "example"}
    end

    it "signs the user in" do
      post :create, {email: "test@example.com", password: "example"}
      controller.send(:current_user).should == user
    end

    describe "from json" do
      it "returns http success" do
        post :create, {email: "test@example.com", password: "example", format: "json"}
        response.should be_success
      end
    end

    describe "with invalid password" do
      describe "from html" do
        it "sets the flash message" do
          post :create, {email: "test@example.com", password: "wrongpassword"}
          flash.now[:error].should_not be_empty
        end

        it "renders the new page" do
          post :create, {email: "test@example.com", password: "wrongpassword"}
          response.should render_template(:new)
        end
      end

      describe "from json" do
        it "returns an error" do
          post :create, {email: "test@example.com", password: "wrongpassword", format: "json"}
          response.body.should =~ /invalid user name or password/i
        end

        it "returns forbidden status" do
          post :create, {email: "test@example.com", password: "wrongpassword", format: "json"}
          response.code.should == '422'
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "logs the user out" do
      delete "destroy", {}, logged_in_session
      controller.send(:current_user).should be_nil
    end

    describe "from html" do
      it "redirects the user" do
        delete "destroy", {}, logged_in_session
        response.should redirect_to(root_path)
      end
    end

    describe "from json" do
      it "returns http success" do
        delete "destroy", {format: 'json'}, logged_in_session
        response.should be_success
      end
    end
  end
end
