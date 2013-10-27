require 'spec_helper'

describe User do
  let(:user_params) { { email: "test@example.com", username: "test", password: "example", password_confirmation: "example" } }

  it "has secure password support" do
    User.new.should respond_to(:authenticate)
  end

  it "has one time password support" do
    User.new.should respond_to(:otp_secret_key)
  end

  it "accepts a password confirmation" do
    User.new.should respond_to(:password_confirmation=)
  end

  it "downcases the email address" do
    user = User.new
    user.email = "SIR@CAPSALOCK.COM"
    user.valid?
    user.email.should == "sir@capsalock.com"
  end

  it "knows if the password was set" do
    user = User.new
    user.send(:password_set?).should == false
    user.password = "example"
    user.send(:password_set?).should == true
  end

  describe "validations" do
    describe "unique" do
      before(:each) do
        User.create!(user_params)
      end
      it { should validate_uniqueness_of(:username) }
      it { should validate_uniqueness_of(:email) }
      it "validates the uniqueness of the the confirmation email" do
        user = User.new(user_params.merge(email: "old@example.com", username: "old"))
        user.confirmation_email = "new@example.com"
        user.should be_valid
        user.confirmation_email = "test@example.com"
        user.should_not be_valid
      end
    end
    it { should validate_presence_of(:confirmation_email) }
    it { should validate_presence_of(:username) }
    it { should validate_presence_of(:password) }
    it { should validate_confirmation_of(:password) }

  end

  describe "tokens" do
    it "finds a user from a token" do
      verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_key_base)
      token = verifier.generate(1)
      user = User.new
      User.should_receive(:find_by_id).with(1).and_return(user)
      User.user_from_token(token).should == user
    end

    it "does not find a user from an invalid token" do
      User.user_from_token("INVALID").should be_nil
    end

    describe "for fields" do
      before(:each) do
        User.should_receive(:user_from_token).with("TOKEN").and_return("USER")
      end

      it "finds a user from the remember token" do
        User.user_from_remember_token("TOKEN").should == "USER"
      end

      it "finds a user from the reset password token" do
        User.user_from_reset_password_token("TOKEN").should == "USER"
      end

      it "finds a user from the confirm token" do
        User.user_from_confirmation_token("TOKEN").should == "USER"
      end

      it "finds a user from the unlock token" do
        User.user_from_unlock_token("TOKEN").should == "USER"
      end
    end

    it "sets a token" do
      user = User.new
      user.should_receive(:persisted?).and_return(true)
      user.should_receive(:id).and_return(1)
      user.should_receive(:save).and_return(true)
      user.set_token(:remember_token)
      user.remember_token.should_not be_nil
    end

    it "does not set a token for a new record" do
      user = User.new
      user.set_token(:remember_token)
      user.remember_token.should be_nil
    end

    it "sets the created at for the token" do
      Time.stub(:now).and_return(time = Time.now)
      user = User.new
      user.should_receive(:persisted?).and_return(true)
      user.should_receive(:id).and_return(1)
      user.should_receive(:save).and_return(true)
      user.set_token(:remember_token)
      user.remember_token_created_at.should == time
    end

    it "clears the remember token" do
      user = User.new
      user.should_receive(:save).and_return(true)
      user.remember_token = "TOKEN"
      user.remember_token_created_at = Time.now
      user.clear_remember_token
      user.remember_token.should be_nil
      user.remember_token_created_at.should be_nil
    end
  end

  describe "display name" do
    it "has a display name" do
      user = User.new(first_name: "Boss", last_name: "Hogg")
      user.display_name.should == "Boss Hogg"
      user.first_name = nil
      user.display_name.should == "Hogg"
    end
  end

  describe "tracking" do
    let(:user) do
      user = User.new
      user.should_receive(:save).and_return(true)
      user
    end

    it "tracks sign in count" do
      expect {
        user.track_sign_in(nil)
      }.to change(user, :sign_in_count).by(1)
    end

    it "tracks current sign in" do
      Time.stub(:now).and_return(time = Time.now)
      user.track_sign_in(nil)
      user.current_sign_in_at.should == time
    end

    it "tracks last sign in" do
      time = Time.now
      user.current_sign_in_at = time
      user.track_sign_in(nil)
      user.last_sign_in_at.should == time
    end

    it "tracks current and last ip" do
      user.track_sign_in(ip = "123.456.789.001")
      user.current_sign_in_ip.should == ip
    end

    it "tracks current and last ip" do
      ip = "123.456.789.001"
      user.current_sign_in_ip = ip
      user.track_sign_in(nil)
      user.last_sign_in_ip.should == ip
    end
  end

  describe "emails" do
    let(:user) { User.new(user_params) }

    describe "with valid params" do
      it "confirms the email" do
        user = User.new
        user.should_receive(:persisted?).and_return(true)
        user.should_receive(:id).and_return(1)
        user.should_receive(:save).and_return(true)
        Time.stub(:now).and_return(time = Time.now)

        user.send_confirmation
        user.confirmation_token_created_at.should == time
        user.confirmation_token.should_not be_blank
      end

      it "sends confirmation email instructions" do
        user = User.new
        user.should_receive(:persisted?).and_return(true)
        user.should_receive(:id).and_return(1)
        user.should_receive(:save).and_return(true)
        user.send_confirmation
      end

      it "handles confirmed emails" do
        user.should_receive(:save).and_return(true)
        user.confirmation_email = "new@example.com"
        user.confirmation_token = "TOKEN"
        user.email_confirmed.should == true
        user.confirmation_email.should == user.email
        user.confirmation_token.should be_nil
        user.confirmation_token_created_at.should be_nil
        user.email.should == "new@example.com"
      end
    end

    it "does not confirm if there is no confirmation token" do
      user.confirmation_email = "new@example.com"
      user.confirmation_token = nil
      user.email_confirmed.should == false
    end

    it "does not confirm if there is no confirmation email" do
      user.confirmation_email = ""
      user.confirmation_token = "TOKEN"
      user.email_confirmed.should == false
    end

    it "does not confirm emails if they are already used" do
      User.create(user_params.merge(email: "new@example.com", username: "newuser"))
      user.confirmation_email = "new@example.com"
      user.confirmation_token = "TOKEN"
      user.email_confirmed.should == false
      user.should have(1).errors_on(:email)
    end
  end

  describe "passwords" do
    it "changes the password if it matches" do
      user = User.new(user_params)
      user.should_receive(:save).and_return(true)
      user.change_password("password", "password")
      user.password_digest.should_not be_blank
      user.remember_token.should be_nil
      user.remember_token_created_at.should be_nil
    end

    it "doesn't change the password if it doesn't match" do
      user = User.new
      user.remember_token = "token"
      user.change_password("password", "typotypo")
      user.should_not be_valid
      user.remember_token.should == "token"
    end

    it "resets the password" do
      user = User.new
      user.should_receive(:persisted?).and_return(true)
      user.should_receive(:id).and_return(1)
      user.should_receive(:save).and_return(true)
      Time.stub(:now).and_return(time = Time.now)

      user.send_reset_password
      user.reset_password_token_created_at.should == time
      user.reset_password_token.should_not be_blank
    end

    it "sends reset password instructions" do
      user = User.new
      user.should_receive(:persisted?).and_return(true)
      user.should_receive(:id).and_return(1)
      user.should_receive(:save).and_return(true)
      user.send_reset_password
    end
  end
end
