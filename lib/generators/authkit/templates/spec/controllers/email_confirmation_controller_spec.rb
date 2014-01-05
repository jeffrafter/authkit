require 'spec_helper'

describe EmailConfirmationController do
  render_views

  let(:user) { build(:user) }
  let(:token) { "TOKEN" }

  describe "GET 'show'" do
    it "requires a login" do
      controller.stub(:current_user).and_return(nil)
      get 'show', token: token
      response.should be_redirect
      flash[:error].should_not be_empty
    end

    it "requires a valid token" do
      user.confirmation_token = "OTHER TOKEN"
      controller.stub(:current_user).and_return(user)
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
          controller.stub(:current_user).and_return(user)
          user.should_receive(:email_confirmed).and_return(true)
          get 'show', token: token
        end

        it "does not sign the user in" do
          controller.stub(:current_user).and_return(user)
          controller.should_not_receive(:login)
          get 'show', token: token
        end

        it "sets the flash" do
          controller.stub(:current_user).and_return(user)
          get 'show', token: token
          flash[:notice].should_not be_nil
        end

        it "redirects the user" do
          controller.stub(:current_user).and_return(user)
          get 'show', token: token
          response.should be_redirect
        end

        describe "from json" do
          it "returns http success" do
            controller.stub(:current_user).and_return(user)
            get 'show', token: token, format: 'json'
            response.should be_success
          end
        end

      end

      describe "when the confirmation is not successful" do
        it "handles invalid confirmations" do
          controller.stub(:current_user).and_return(user)
          user.should_receive(:email_confirmed).and_return(false)
          get 'show', token: token
          flash[:error].should_not be_empty
          response.should be_redirect
        end

        describe "from json" do
          it "returns a 422" do
            controller.stub(:current_user).and_return(user)
            user.should_receive(:email_confirmed).and_return(false)
            get 'show', token: token, format: 'json'
            response.code.should == '422'
          end
        end

      end
    end
  end
end
