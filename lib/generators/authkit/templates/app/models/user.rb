require 'email_format_validator'

class User < ActiveRecord::Base
  has_secure_password
  has_one_time_password

  # Uncomment if you are not using strong params (note, that email is only permitted on
  # signup and confirmation_email is only permitted on update):
  #
  # attr_accessible :username,
  #  :email,
  #  :confirmation_email,
  #  :password,
  #  :password_confirmation,
  #  :time_zone,
  #  :first_name,
  #  :last_name,
  #  :bio,
  #  :website,
  #  :phone_number

  before_validation :downcase_email
  before_validation :set_confirmation_email

  # Whenever the password is set, validate (not only on create)
  validates :password, presence: true, confirmation: true, length: {minimum: 6}, if: :password_set?
  validates :username, presence: true, uniqueness: {case_sensitive: false}
  validates :email, email_format: true, presence: true, uniqueness: true
  validates :confirmation_email, email_format: true, presence: true

  # Confirm emails check for existing emails for uniqueness as a convenience
  validate  :confirmation_email_uniqueness, if: :confirmation_email_set?

  def self.user_from_token(token)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_key_base)
    id = verifier.verify(token)
    User.where(id: id).first
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # The tokens created by this method have unique indexes but they are digests of the
  # id which is unique. Because of this we shouldn't see a conflict. If we do, however
  # we want the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # to bubble up.
  def set_token(field)
    return unless self.persisted?
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_key_base)
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

  def self.user_from_confirmation_token(token)
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

  def send_reset_password
    return false unless set_token(:reset_password_token)

    # TODO: insert your mailer logic here
    true
  end

  def send_confirmation
    return false unless set_token(:confirmation_token)

    # TODO: insert your mailer logic here
    true
  end

  def email_confirmed
    return false if self.confirmation_token.blank? || self.confirmation_email.blank?

    self.email = self.confirmation_email

    # Don't nil out the token unless the changes are valid as it may be
    # needed again (when re-rendering the form, for instance)
    if valid?
      self.confirmation_token = nil
      self.confirmation_token_created_at = nil
    end

    self.save
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

  def password_set?
    self.password.present?
  end

  def downcase_email
    self.email = self.email.downcase if self.email
  end

  def set_confirmation_email
    self.confirmation_email = self.email if self.confirmation_email.blank?
  end

  def confirmation_email_set?
    confirmation_email.present? && confirmation_email_changed? && confirmation_email != email
  end

  # It is possible that a user will change their email, not confirm, and then
  # sign up for the service again using the same email. If they later go to confirm
  # the email change on the first account it will fail because the email will be
  # used by the new signup. Though this is problematic it avoids the larger problem of
  # users blocking new user signups by changing their email address to something they
  # don't control. This check is just for convenience and does not need to
  # guarantee uniqueness.
  def confirmation_email_uniqueness
    errors.add(:confirmation_email, :taken, value: email) if User.where('email = ?', confirmation_email).count > 0
  end
end
