class UserSession < ActiveRecord::Base
  belongs_to :user

  scope :active, -> { where(revoked_at: nil, logged_out_at: nil) }

  validates :user, presence: true

  validates :remember_token, presence: true

  before_validation :set_remember_token

  def active?
    !logged_out? && !revoked?
  end

  def logged_out?
    logged_out_at.present?
  end

  def revoked?
    revoked_at.present?
  end

  def sudo?
    sudo_enabled_at.present? && sudo_enabled_at > 1.hour.ago
  end

  def sudo
    self.sudo_enabled_at = Time.now
    save!
  end

  def logout
    self.logged_out_at = Time.now
    save!
  end

  def access(request, tracking=true)
    self.accessed_at = Time.now
    self.ip = request.remote_ip if tracking
    self.user_agent = request.user_agent if tracking
    save!
  end

  private

  # The tokens created by this method have unique indexes but collisions are very
  # unlikely (1/64^32). Because of this there shouldn't be a conflict. If one occurs
  # the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # should bubble up.
  def set_remember_token
    self.remember_token = SecureRandom.urlsafe_base64(32) if self.remember_token.blank?
  end
end

