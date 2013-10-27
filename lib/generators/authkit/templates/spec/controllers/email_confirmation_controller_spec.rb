require 'spec_helper'

describe EmailConfirmationController do
  render_views

  let(:user_params) { { email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }
  let(:user) { User.new(user_params) }
  let(:token) { "TOKEN" }

  describe "GET 'show'" do
    it "requires a valid token" do
      User.should_receive(:user_from_token).with(token).and_return(nil)
      get 'show', token: token
      response.should be_redirect
      flash[:error].should_not be_empty
    end

    describe "with a valid token" do
      before(:each) do
        user.confirmation_email = "new@example.com"
        user.confirmation_token = token
      end

      describe "when the confirmation is successful" do
        it "confirms the user email" do
          User.should_receive(:user_from_token).with(token).and_return(user)
          user.should_receive(:email_confirmed).and_return(true)
          get 'show', token: token
        end

        it "signs the user in" do
          User.should_receive(:user_from_token).with(token).and_return(user)
          controller.should_receive(:login).with(user)
          get 'show', token: token
        end

        it "sets the flash" do
          User.should_receive(:user_from_token).with(token).and_return(user)
          get 'show', token: token
          flash[:notice].should_not be_nil
        end

        it "redirects the user" do
          User.should_receive(:user_from_token).with(token).and_return(user)
          get 'show', token: token
          response.should be_redirect
        end

        describe "from json" do
          it "returns http success" do
            User.should_receive(:user_from_token).with(token).and_return(user)
            get 'show', token: token, format: 'json'
            response.should be_success
          end
        end

      end

      describe "when the confirmation is not successful" do
        it "handles invalid confirmations" do
          User.should_receive(:user_from_token).with(token).and_return(user)
          user.should_receive(:email_confirmed).and_return(false)
          get 'show', token: token
          flash[:error].should_not be_empty
          response.should be_redirect
        end

        describe "from json" do
          it "returns a 422" do
            User.should_receive(:user_from_token).with(token).and_return(user)
            user.should_receive(:email_confirmed).and_return(false)
            get 'show', token: token, format: 'json'
            response.code.should == '422'
          end
        end

      end
    end
  end
end
