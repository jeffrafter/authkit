require 'rails_helper'

describe SessionsController do
  render_views

  let(:user_session) { create(:user_session) }
  let(:user) { user_session.user }
  let(:logged_in_session) { { user_session_id: user_session.id } }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    before(:each) do
      user
    end

    it "redirects the user" do
      post :create, params: { email: user.email, password: "example" }
      expect(response).to be_redirect
    end

    it "authenticates if it finds the user" do
      expect_any_instance_of(User).to receive(:authenticate).and_return(true)
      post :create, params: { email: user.email, password: "example" }
    end

    it "does not authenticate if it does not find a user" do
      expect_any_instance_of(User).to_not receive(:authenticate)
      post :create, params: { email: "unknown@example.com", password: "example" }
    end

    it "downcases the email or user name" do
      expect_any_instance_of(User).to receive(:authenticate).and_return(true)
      post :create, params: { email: user.email, password: "example" }
    end

    it "signs the user in" do
      post :create, params: { email: user.email, password: "example" }
      expect(controller.send(:current_user)).to eq(user)
    end

    it "remembers the user if remember me is chosen" do
      expect(controller).to receive(:set_remember_cookie)
      post :create, params: { email: user.email, password: "example", remember_me: "1" }
      expect(controller.send(:current_user)).to eq(user)
    end

    it "does not remember the user if remember me is not chosen" do
      expect(controller).to_not receive(:set_remember_cookie)
      post :create, params: { email: user.email, password: "example", remember_me: "" }
      expect(controller.send(:current_user)).to eq(user)
    end

    describe "from json" do
      it "returns http success" do
        post :create, params: { email: user.email, password: "example", format: "json" }
        expect(response).to be_success
      end
    end

    describe "with invalid password" do
      describe "from html" do
        it "sets the flash message" do
          post :create, params: { email: user.email, password: "wrongpassword" }
          expect(flash.now[:error]).to_not be_empty
        end
      end

      describe "from json" do
        it "returns an error" do
          post :create, params: { email: user.email, password: "wrongpassword", format: "json" }
          expect(response.body).to match(/invalid user name or password/i)
        end

        it "returns forbidden status" do
          post :create, params: { email: user.email, password: "wrongpassword", format: "json" }
          expect(response.code).to eq('422')
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "logs the user out" do
      delete "destroy", session: logged_in_session
      expect(controller.send(:current_user)).to be_nil
    end

    describe "from html" do
      it "redirects the user" do
        delete "destroy", session: logged_in_session
        expect(response).to redirect_to(root_path)
      end
    end

    describe "from json" do
      it "returns http success" do
        delete "destroy", params: { format: 'json' }, session: logged_in_session
        expect(response).to be_success
      end
    end
  end
end
