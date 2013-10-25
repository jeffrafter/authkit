require 'email_format_validator'

class User < ActiveRecord::Base
  has_secure_password
  has_one_time_password

  # Uncomment if you are not using strong params:
  #
  # attr_accessible :unconfirmed_email,
  #  :password,
  #  :password_confirmation,
  #  :username,
  #  :time_zone,
  #  :first_name,
  #  :last_name,
  #  :bio,
  #  :website,
  #  :phone_number

  before_validation :downcase_email
  before_validation :copy_email

  # Whenever the password is set, validate (not only on create)
  validates :password, presence: true, confirmation: true, length: {minimum: 6}, if: :password_set?
  validates :username, presence: true, uniqueness: {case_sensitive: false}
  validates :email, email_format: true, presence: true, uniqueness: true
  validates :unconfirmed_email, email_format: true, presence: true

  # Unconfirmed emails only check for existing emails for uniqueness
  validate  :unconfirmed_email_uniqueness, if: :unconfirmed_email_set?

  def self.user_from_token(token)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_token)
    id = verifier.verify(token)
    User.find_by_id(id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # The tokens created by this method have unique indexes but they are digests of the
  # id which is unique. Because of this we shouldn't see a conflict. If we do, however
  # we want the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # to bubble up.
  def set_token(field)
    return unless self.persisted?
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_token)
    self.send("#{field}_created_at=", Time.now)
    self.send("#{field}=", verifier.generate(self.id))
    self.save
  end

  # These methods are a little redundant, but give you the opportunity to
  # insert expiry for any of these token based authentication strategies.
  # For example:
  #
  #    def self.user_from_remember_token(token)
  #      user = user_from_token(token)
  #      user = nil if user && user.remember_token_created_at < 30.days.ago
  #      user
  #    end
  #
  def self.user_from_remember_token(token)
    user_from_token(token)
  end

  def self.user_from_reset_password_token(token)
    user_from_token(token)
  end

  def self.user_from_confirm_token(token)
    user_from_token(token)
  end

  def self.user_from_unlock_token(token)
    user_from_token(token)
  end

  def display_name
    [first_name, last_name].compact.join(" ")
  end

  def track_sign_in(ip)
    self.sign_in_count += 1
    self.last_sign_in_at = self.current_sign_in_at
    self.last_sign_in_ip = self.current_sign_in_ip
    self.current_sign_in_at = Time.now
    self.current_sign_in_ip = ip
    self.save
  end

  def clear_remember_token
    self.remember_token = nil
    self.remember_token_created_at = nil
    self.save
  end

  # When checking the unconfirmed email use the email if empty for display
  def unconfirmed_email
    super || self.email
  end

  def confirm_email
    send_email_confirmation_instructions if set_token(:confirm_token)
  end

  def email_confirmed
    self.email = self.unconfirmed_email
    self.unconfirmed_email = nil

    # Don't nil out the token unless the changes are valid as it may be
    # needed again (when re-rendering the form, for instance)
    if valid?
      self.confirm_token = nil
      self.confirm_token_created_at = nil
    end

    self.save
  end

  def reset_password
    send_reset_password_instructions if set_token(:reset_password_token)
  end

  def change_password(password, password_confirmation)
    self.password = password
    self.password_confirmation = password_confirmation

    # Don't nil out the token unless the changes are valid as it may be
    # needed again (when re-rendering the form, for instance)
    if valid?
      self.reset_password_token = nil
      self.reset_password_token_created_at = nil
    end

    self.save
  end

  protected

  def send_reset_password_instructions
    # TODO, check if the email address is confirmed and send
    # NOTE, when sending emails, you may want to delegate to a queue instead of sending inline
    true
  end

  def send_email_confirmation_instructions
    # TODO, check if the email address is unconfirmed and not equal to the email and send
    # NOTE, when sending emails, you may want to delegate to a queue instead of sending inline
    true
  end

  def downcase_email
    self.email = self.email.downcase if self.email
  end

  def copy_email
    self.unconfirmed_email = self.email if self.unconfirmed_email.blank?
  end

  def password_set?
    self.password.present?
  end

  def unconfirmed_email_set?
    unconfirmed_email.present? && unconfirmed_email_changed? && unconfirmed_email != email
  end

  # It is possible that a user will change their email, not confirm, and then
  # sign up for the service. If they later go to confirm the change it will
  # fail because the email will be used by the new signup. Though this is problematic
  # it avoids the larger problem of users blocking new user signups by changing their
  # email address to something they don't control. The database has a unique index on both
  # email and unconfirmed email.
  def unconfirmed_email_uniqueness
    errors.add(:unconfirmed_email, :taken, value: email) if User.where('email = ?', unconfirmed_email).count > 0
  end
end
