require 'spec_helper'

describe User do
  let(:user_params) { attributes_for(:user) }

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

  describe "validations" do
    describe "unique" do
      before(:each) do
        create(:user)
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
    it "sets the remember token" do
      user = User.new
      user.should_receive(:save!).and_return(true)
      user.set_remember_token
      user.remember_token.should_not be_blank
      user.remember_token_created_at.should_not be_blank
    end

    it "clears the remember token" do
      user = User.new
      user.should_receive(:save!).and_return(true)
      user.remember_token = "TOKEN"
      user.remember_token_created_at = Time.now
      user.clear_remember_token
      user.remember_token.should be_nil
      user.remember_token_created_at.should be_nil
    end
  end

  describe "token expiry" do
    it "should expire reset password tokens" do
      user = User.new
      user.reset_password_token_expired?.should == true
      user.reset_password_token_created_at = 10.minutes.ago
      user.reset_password_token_expired?.should == false
      user.reset_password_token_created_at = 1.day.ago
      user.reset_password_token_expired?.should == true
    end

    it "should expire confirmation tokens" do
      user = User.new
      user.confirmation_token_expired?.should == true
      user.confirmation_token_created_at = 2.days.ago
      user.confirmation_token_expired?.should == false
      user.confirmation_token_created_at = 3.days.ago
      user.confirmation_token_expired?.should == true
    end

    it "should expire remember tokens" do
      user = User.new
      user.remember_token_expired?.should == true
      user.remember_token_created_at = 30.days.ago
      user.remember_token_expired?.should == false
      user.remember_token_created_at = 1.years.ago
      user.remember_token_expired?.should == true
    end
  end

  describe "display name" do
    it "has a display name" do
      user = User.new(first_name: "Boss", last_name: "Hogg")
      user.full_name.should == "Boss Hogg"
      user.first_name = nil
      user.full_name.should == "Hogg"
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
    let(:user) { build(:user) }

    describe "with valid params" do
      it "confirms the email" do
        user = User.new
        user.should_receive(:save!).and_return(true)
        Time.stub(:now).and_return(time = Time.now)

        user.send_confirmation
        user.confirmation_token_created_at.should == time
        user.confirmation_token.should_not be_blank
      end

      it "generates a token before it sends confirmation email instructions" do
        user = User.new
        user.should_receive(:save!).and_return(true)
        user.send_confirmation
        user.confirmation_token.should_not be_blank
        user.confirmation_token_created_at.should_not be_blank
      end

      it "sends confirmation email instructions" do
        user = User.new
        user.should_receive(:save!).and_return(true)
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
      create(:user, email: "new@example.com", username: "newuser")
      user.confirmation_email = "new@example.com"
      user.confirmation_token = "TOKEN"
      user.email_confirmed.should == false
      user.should have(1).errors_on(:email)
    end

    it "is pending confirmation if there is a confirmation token" do
      user = build(:user, confirmation_token: "TOKEN")
      user.should be_pending_confirmation
    end

    it "there is no pending confirmation if there is not a confirmation token" do
      user = build(:user, confirmation_token: nil)
      user.should_not be_pending_confirmation
    end
  end

  describe "passwords" do
    it "changes the password if it matches" do
      user = build(:user)
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
      user.should_receive(:save!).and_return(true)
      Time.stub(:now).and_return(time = Time.now)

      user.send_reset_password
      user.reset_password_token_created_at.should == time
      user.reset_password_token.should_not be_blank
    end

    it "generates a token before it sends reset password instructions" do
      user = User.new
      user.should_receive(:save!).and_return(true)
      user.send_reset_password
      user.reset_password_token.should_not be_blank
      user.reset_password_token_created_at.should_not be_blank
    end

    it "sends reset password instructions" do
      user = User.new
      user.should_receive(:save!).and_return(true)
      user.send_reset_password
    end
  end
end
