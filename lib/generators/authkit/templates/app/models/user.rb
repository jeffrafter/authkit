require 'email_format_validator'
require 'full_name_splitter'
<% if username? %>require 'username_format_validator'
<% end %>
class User < ActiveRecord::Base
  has_many :sessions, class_name: 'UserSession'
  <% if oauth? %>
  has_many :auths
  <% end %>

  has_secure_password validations: false
  has_one_time_password

  before_validation :downcase_email
  before_validation :set_confirmation_email

  validates :password, confirmation: true, length: { minimum: 6 }, if: :has_password?
  validates :email, email_format: true, uniqueness: { allow_nil: true }
  validates :confirmation_email, email_format: true
  <% if username? %>validates :username, username_format: true, uniqueness: { case_sensitive: false, allow_nil: true }
  <% end %>
  validates :password, presence: true, unless: :has_auth_or_skip_password_validation?
  validates :email, presence: true, unless: :has_auth?
  validates :confirmation_email, presence: true, unless: :has_auth?
  <% if username? %>validates :username, presence: true, unless: :has_auth?
  <% end %>
  # Confirm emails check for existing emails for uniqueness as a convenience
  validate  :confirmation_email_uniqueness, if: :confirmation_email_set?

  def suspended?
    self.suspended_at.present?
  end

  def incomplete?
    <% if username? %>username.blank? || <% end %>email.blank? || password_digest.blank?
  end

  def full_name=(value)
    return if value.blank?

    splitter = FullNameSplitter.new(value)
    self.first_name = splitter.first_name
    self.last_name = splitter.last_name
    self.full_name
  end

  def full_name
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

  def reset_password_token_expired?
    # TODO reset password tokens expire in 1 day by default
    self.reset_password_token_created_at.blank? || self.reset_password_token_created_at <= 1.day.ago
  end

  def confirmation_token_expired?
    # TODO confirmation tokens expire in 3 days by default
    self.confirmation_token_created_at.blank? || self.confirmation_token_created_at <= 3.days.ago
  end

  def send_welcome
    # TODO insert your mailer logic here
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

  def pending_confirmation?
    self.confirmation_token.present?
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

  def has_auth?
    <% if oauth? %>
    self.auths.first.present?
    <% else %>
    false
    <% end %>
  end

  def has_auth_or_skip_password_validation?
    has_auth? || skip_password_validation?
  end

  def skip_password_validation?
    self.password.blank? && self.password_digest.present?
  end

  def has_password?
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
