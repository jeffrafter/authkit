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

  # Whenever the password is set, validate (not only on create)
  validates :password, presence: true, confirmation: true, length: {minimum: 6}, if: :password_set?
  validates :unconfirmed_email, presence: true, uniqueness: true, email_format: true
  validates :username, presence: true, uniqueness: {case_sensitive: false}

  def self.user_from_token(token)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.config.secret_token)
    id = verifier.verify(token)
    User.find_by_id(id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # TODO, save and catch unique index exception
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

  def confirm_email
    send_email_confirmation_instructions if set_token(:confirm_token)
  end

  def email_confirmed
    self.email = self.unconfirmed_email
    self.unconfirmed_email = nil
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
    # TODO, check if the email address is unconfirmed and send
    # NOTE, when sending emails, you may want to delegate to a queue instead of sending inline
    true
  end

  def password_set?
    self.password.present?
  end

  def downcase_email
    self.email = self.email.downcase if self.email
  end
end
