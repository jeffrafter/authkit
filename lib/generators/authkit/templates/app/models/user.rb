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

  # The tokens created by this method have unique indexes but collisions are very
  # unlikely (1/64^32). Because of this there shouldn't be a conflict. If one occurs
  # the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # should bubble up.
  def set_remember_token
    self.remember_token = SecureRandom.urlsafe_base64(32)
    self.remember_token_created_at = Time.now
    self.save!
  end

  def clear_remember_token
    self.remember_token = nil
    self.remember_token_created_at = nil
    self.save!
  end

  def send_welcome
    # TODO: insert your mailer logic here
    true
  end

  # The tokens created by this method have unique indexes but collisions are very
  # unlikely (1/64^32). Because of this there shouldn't be a conflict. If one occurs
  # the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # should bubble up.
  def send_reset_password
    self.reset_password_token = SecureRandom.urlsafe_base64(32)
    self.reset_password_token_created_at = Time.now
    self.save!

    # TODO: insert your mailer logic here
    true
  end

  # The tokens created by this method have unique indexes but collisions are very
  # unlikely (1/64^32). Because of this there shouldn't be a conflict. If one occurs
  # the ActiveRecord::StatementInvalid or ActiveRecord::RecordNotUnique exeception
  # should bubble up.
  def send_confirmation
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
    self.confirmation_token_created_at = Time.now
    self.save!

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
