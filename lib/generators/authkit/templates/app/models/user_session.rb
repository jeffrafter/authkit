class UserSession < ActiveRecord::Base
  belongs_to :user

  scope :active, -> { where('(accessed_at IS NULL OR accessed_at >= ?)', 1.month.ago).where(revoked_at: nil, signed_out_at: nil) }

  validates :user, presence: true
  validates :remember_token, presence: true

  before_validation :set_remember_token

  def active?
    !expired? && !signed_out? && !revoked?
  end

  def expired?
    accessed_at.present? && accessed_at <= 1.day.ago
  end

  def signed_out?
    signed_out_at.present?
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

  def sign_out
    self.signed_out_at = Time.now
    save!
  end

  def access(request)
    self.accessed_at = Time.now
    self.ip = request.remote_ip
    self.user_agent = request.user_agent
    save!
  end

  private

  # The tokens created by this method have unique indexes but collisions are very
  # unlikely (1/64^32). Because of this there shouldn't be a conflict. If one occurs
  # the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # should bubble up.
  def set_remember_token
    self.remember_token = SecureRandom.urlsafe_base64(32)
  end
end

