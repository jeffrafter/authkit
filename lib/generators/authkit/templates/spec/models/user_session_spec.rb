require 'rails_helper'

describe UserSession do

  let(:user_session) { create(:user_session) }
  let(:user) { user_session.user }

  it { should belong_to(:user) }

  describe "validations" do
    it { should validate_presence_of(:user) }
  end

  describe "scopes" do
    it "finds active sessions" do
      user_session
      revoked_session = create(:user_session, revoked_at: 1.year.ago)
      logged_out_session = create(:user_session, logged_out_at: 1.year.ago)

      all = UserSession.active.all
      expect(all).to include(user_session)
      expect(all.length).to eq(1)
    end
  end

  describe "tokens" do
    it "sets the remember token" do
      user_session.remember_token = nil
      user_session.save
      expect(user_session.remember_token).to_not be_blank
    end
  end

  it "is active" do
    user_session = UserSession.new
    expect(user_session).to be_active
    user_session.revoked_at = Time.now
    expect(user_session).to_not be_active
  end

  it "is logged out" do
    user_session = UserSession.new
    expect(user_session).to_not be_logged_out
    user_session.logged_out_at = Time.now
    expect(user_session).to be_logged_out
  end

  it "is revoked" do
    user_session = UserSession.new
    expect(user_session).to_not be_revoked
    user_session.revoked_at = Time.now
    expect(user_session).to be_revoked
  end

  it "is super user" do
    user_session = UserSession.new
    expect(user_session).to_not be_sudo
    user_session.sudo_enabled_at = Time.now
    expect(user_session).to be_sudo
    user_session.sudo_enabled_at = 2.hours.ago
    expect(user_session).to_not be_sudo
  end

  it "logs out" do
    token = user_session.remember_token
    expect(user_session).to_not be_logged_out
    user_session.logout
    expect(user_session).to be_logged_out
    expect(user_session.logged_out_at).to be_present
  end

  it "records the access" do
    now = Time.now
    allow(Time).to receive(:now).and_return(now)
    request = double
    expect(request).to receive(:remote_ip).and_return('1.1.1.1')
    expect(request).to receive(:user_agent).and_return('webkit')
    user_session.access(request)
    expect(user_session.accessed_at).to eq(now)
  end
end
