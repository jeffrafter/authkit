require 'rails_helper'

describe Signup do
  let(:signup) { Signup.new }

  it "should not be persisted" do
    expect(signup).to_not be_persisted
  end

  describe "validation" do
    it "should validate terms of service acceptance" do
      signup.terms_of_service = "1"
      signup.valid?
      expect(signup.errors[:terms_of_service].size).to eq(0)
    end

    it "should validate models" do
      signup.user = User.new
      expect(signup.user).to receive(:valid?).and_return(true)
      signup.valid?
    end

    it "should copy errors from the user to the signup" do
      signup.user = User.new
      signup.valid?
      expect(signup.errors[:password].size).to eq(1)
    end
  end

  describe "saving" do
    it "should validate" do
      expect(signup).to receive(:valid?)
      signup.save
    end

    describe "when valid" do
      it "should persist" do
        signup.user = build(:user)
        expect(signup).to receive(:valid?).and_return(true)
        expect(signup.user).to receive(:save!)
        signup.save
      end

      it "should send the welcome" do
        signup.user = build(:user)
        signup.email = signup.user.email
        expect(signup).to receive(:valid?).and_return(true)
        allow(signup).to receive(:persist!)
        expect(signup.user).to receive(:send_welcome)
        signup.save
      end

      it "should send the confirmation" do
        signup.user = build(:user)
        signup.email = signup.user.email
        expect(signup).to receive(:valid?).and_return(true)
        allow(signup).to receive(:persist!)
        expect(signup.user).to receive(:send_confirmation)
        signup.save
      end
    end

    describe "when invalid" do
      it "should not persist" do
        expect(signup).to receive(:valid?).and_return(false)
        expect(signup).to_not receive(:persist!)
        signup.save
      end

      it "should not send the welcome" do
        expect(signup).to receive(:valid?).and_return(false)
        expect(signup).to_not receive(:send_welcome!)
        signup.save
      end

      it "should not send the confirmation" do
        expect(signup).to receive(:valid?).and_return(false)
        expect(signup).to_not receive(:send_confirmation!)
        signup.save
      end
    end
  end

  it "should create a new user" do
    user = build(:user)
    expect(User).to receive(:new).and_return(user)
    allow(user).to receive(:valid?).and_return(true)
    expect(user).to receive(:save!)
    expect(user).to receive(:send_confirmation)
    allow(signup).to receive(:valid?).and_return(true)
    signup.email = "new@example.com"
    signup.save
  end

end
