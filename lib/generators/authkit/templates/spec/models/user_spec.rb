require 'rails_helper'

describe User do
  let(:user_params) { attributes_for(:user) }

  it { should have_many(:sessions) }

  it "has secure password support" do
    expect(User.new).to respond_to(:authenticate)
  end

  it "has one time password support" do
    expect(User.new).to respond_to(:otp_secret_key)
  end

  it "accepts a password confirmation" do
    expect(User.new).to respond_to(:password_confirmation=)
  end

  it "downcases the email address" do
    user = User.new
    user.email = "SIR@CAPSALOCK.COM"
    user.valid?
    expect(user.email).to eq("sir@capsalock.com")
  end

  describe "validations" do
    describe "unique" do
      before(:each) do
        create(:user)
      end
      <% if username? %>it { should validate_uniqueness_of(:username) }
      <% end %>it { should validate_uniqueness_of(:email) }
      it "validates the uniqueness of the confirmation email" do
        existing_user = create(:user)
        user = build(:user, email: "old@example.com")
        user.confirmation_email = "new@example.com"
        expect(user).to be_valid
        user.confirmation_email = existing_user.email
        expect(user).to_not be_valid
      end
    end
    it { should validate_presence_of(:confirmation_email) }
    <% if username? %>it { should validate_presence_of(:username) }
    <% end %>it { should validate_presence_of(:password) }
    it { should validate_confirmation_of(:password) }

  end

  describe "token expiry" do
    it "should expire reset password tokens" do
      user = User.new
      expect(user.reset_password_token_expired?).to eq(true)
      user.reset_password_token_created_at = 10.minutes.ago
      expect(user.reset_password_token_expired?).to eq(false)
      user.reset_password_token_created_at = 1.day.ago
      expect(user.reset_password_token_expired?).to eq(true)
    end

    it "should expire confirmation tokens" do
      user = User.new
      expect(user.confirmation_token_expired?).to eq(true)
      user.confirmation_token_created_at = 2.days.ago
      expect(user.confirmation_token_expired?).to eq(false)
      user.confirmation_token_created_at = 3.days.ago
      expect(user.confirmation_token_expired?).to eq(true)
    end
  end

  describe "display name" do
    it "has a display name" do
      user = User.new(first_name: "Boss", last_name: "Hogg")
      expect(user.full_name).to eq("Boss Hogg")
      user.first_name = nil
      expect(user.full_name).to eq("Hogg")
    end
  end

  describe "tracking" do
    let(:user) do
      user = User.new
      expect(user).to receive(:save).and_return(true)
      user
    end

    it "tracks sign in count" do
      expect {
        user.track_sign_in(nil)
      }.to change(user, :sign_in_count).by(1)
    end

    it "tracks current sign in" do
      allow(Time).to receive(:now).and_return(time = Time.now)
      user.track_sign_in(nil)
      expect(user.current_sign_in_at).to eq(time)
    end

    it "tracks last sign in" do
      time = Time.now
      user.current_sign_in_at = time
      user.track_sign_in(nil)
      expect(user.last_sign_in_at).to eq(time)
    end

    it "tracks current and last ip" do
      user.track_sign_in(ip = "123.456.789.001")
      expect(user.current_sign_in_ip).to eq(ip)
    end

    it "tracks current and last ip" do
      ip = "123.456.789.001"
      user.current_sign_in_ip = ip
      user.track_sign_in(nil)
      expect(user.last_sign_in_ip).to eq(ip)
    end
  end

  describe "emails" do
    let(:user) { build(:user) }

    describe "with valid params" do
      it "confirms the email" do
        user = User.new
        expect(user).to receive(:save!).and_return(true)
        allow(Time).to receive(:now).and_return(time = Time.now)

        user.send_confirmation
        expect(user.confirmation_token_created_at).to eq(time.to_s)
        expect(user.confirmation_token).to_not be_blank
      end

      it "generates a token before it sends confirmation email instructions" do
        user = User.new
        expect(user).to receive(:save!).and_return(true)
        user.send_confirmation
        expect(user.confirmation_token).to_not be_blank
        expect(user.confirmation_token_created_at).to_not be_blank
      end

      it "sends confirmation email instructions" do
        user = User.new
        expect(user).to receive(:save!).and_return(true)
        user.send_confirmation
      end

      it "handles confirmed emails" do
        expect(user).to receive(:save).and_return(true)
        user.confirmation_email = "new@example.com"
        user.confirmation_token = "TOKEN"
        expect(user.email_confirmed).to eq(true)
        expect(user.confirmation_email).to eq(user.email)
        expect(user.confirmation_token).to be_nil
        expect(user.confirmation_token_created_at).to be_nil
        expect(user.email).to eq("new@example.com")
      end
    end

    it "does not confirm if there is no confirmation token" do
      user.confirmation_email = "new@example.com"
      user.confirmation_token = nil
      expect(user.email_confirmed).to eq(false)
    end

    it "does not confirm if there is no confirmation email" do
      user.confirmation_email = ""
      user.confirmation_token = "TOKEN"
      expect(user.email_confirmed).to eq(false)
    end

    it "does not confirm emails if they are already used" do
      create(:user, email: "new@example.com")
      user.confirmation_email = "new@example.com"
      user.confirmation_token = "TOKEN"
      expect(user.email_confirmed).to eq(false)
      expect(user.errors[:email].size).to eq(1)
    end

    it "is pending confirmation if there is a confirmation token" do
      user = build(:user, confirmation_token: "TOKEN")
      expect(user).to be_pending_confirmation
    end

    it "there is no pending confirmation if there is not a confirmation token" do
      user = build(:user, confirmation_token: nil)
      expect(user).to_not be_pending_confirmation
    end
  end

  describe "passwords" do
    it "changes the password if it matches" do
      user = build(:user)
      expect(user).to receive(:save).and_return(true)
      user.change_password("password", "password")
      expect(user.password_digest).to_not be_blank
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_token_created_at).to be_nil
    end

    it "doesn't change the password if it doesn't match" do
      user = User.new
      user.reset_password_token = "token"
      user.change_password("password", "typotypo")
      expect(user).to_not be_valid
      expect(user.reset_password_token).to eq("token")
    end

    it "resets the password" do
      user = User.new
      expect(user).to receive(:save!).and_return(true)
      allow(Time).to receive(:now).and_return(time = Time.now)

      user.send_reset_password
      expect(user.reset_password_token_created_at).to eq(time)
      expect(user.reset_password_token).to_not be_blank
    end

    it "generates a token before it sends reset password instructions" do
      user = User.new
      expect(user).to receive(:save!).and_return(true)
      user.send_reset_password
      expect(user.reset_password_token).to_not be_blank
      expect(user.reset_password_token_created_at).to_not be_blank
    end

    it "sends reset password instructions" do
      user = User.new
      expect(user).to receive(:save!).and_return(true)
      user.send_reset_password
    end
  end
end
