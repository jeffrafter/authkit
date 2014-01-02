require 'spec_helper'

describe Signup do
  let(:signup) { Signup.new }

  it "should not be persisted" do
    signup.should_not be_persisted
  end

  describe "validation" do
    it "should validate terms of service acceptance" do
      signup.terms_of_service = "1"
      signup.valid?
      puts signup.errors.full_messages.to_sentence
      signup.should_not have(1).errors_on(:terms_of_service)
    end

    it "should validate models" do
      signup.user = User.new
      signup.user.should_receive(:valid?).and_return(true)
      signup.valid?
    end

    it "should copy errors from the user to the signup" do
      signup.user = User.new
      signup.valid?
      signup.should have(1).errors_on(:password)
    end
  end

  describe "saving" do
    it "should validate" do
      signup.should_receive(:valid?)
      signup.save
    end

    describe "when valid" do
      it "should persist" do
        signup.user = User.new
        signup.should_receive(:valid?).and_return(true)
        signup.user.should_receive(:save!)
        signup.save
      end

      it "should send the welcome" do
        signup.user = User.new
        signup.should_receive(:valid?).and_return(true)
        signup.stub(:persist!)
        signup.user.should_receive(:send_welcome)
        signup.save
      end

      it "should send the confirmation" do
        signup.user = User.new
        signup.should_receive(:valid?).and_return(true)
        signup.stub(:persist!)
        signup.user.should_receive(:send_confirmation)
        signup.save
      end
    end

    describe "when invalid" do
      it "should not persist" do
        signup.should_receive(:valid?).and_return(false)
        signup.should_not_receive(:persist!)
        signup.save
      end

      it "should not send the welcome" do
        signup.should_receive(:valid?).and_return(false)
        signup.should_not_receive(:send_welcome)
        signup.save
      end

      it "should not send the confirmation" do
        signup.should_receive(:valid?).and_return(false)
        signup.should_not_receive(:send_confirmation)
        signup.save
      end
    end
  end

  it "should create a new user" do
    user = User.new
    User.should_receive(:new).and_return(user)
    user.stub(:valid?).and_return(true)
    user.should_receive(:save!)
    signup.stub(:valid?).and_return(true)
    signup.save
  end

end
