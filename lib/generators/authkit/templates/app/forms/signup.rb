# Multi-model form support object for signup and user creation
class Signup
  include ActiveModel::Model

  attr_accessor :user
  <% if oauth? %>
  attr_accessor :auth
  <% end %>

  # User
  attr_accessor(
    :email,
    <% if username? %>:username,
    <% end %>:password,
    :password_confirmation,
    :first_name,
    :last_name,
    :bio,
    :website,
    :phone_number,
    :time_zone)

  <% if oauth? %>
  # Auth
  attr_accessor(
    :auth_params)
  <% end %>

  attr_accessor(
    :skip_email_confirmation,
    :terms_of_service)

  validates :terms_of_service, acceptance: true
  validate :validate_models

  <% if oauth? %>
  def self.new_with_oauth(auth_params, signup_params)
    signup = Signup.new(signup_params)
    signup.set_auth_params(auth_params)
    signup
  end
  <% end %>

  def persisted?
    false
  end

  def save
    if valid?
      persist!
      send_confirmation! unless skip_email_confirmation
      send_welcome!
      true
    else
      false
    end
  end

  def user
    return @user if @user
    @user = User.new(user_params)
    @user
  end

  <% if oauth? %>
  def auth
    return nil if self.auth_params.blank?
    return @auth if @auth
    @auth = self.user.auths.build(auth_params)
  end

  def has_auth?(provider)
    self.auth.provider == provider.to_s if self.auth
  end

  def set_auth_params(auth_params)
    self.auth_params = auth_params

    self.email = self.auth.try(:email) if self.email.blank?
    self.first_name = self.auth.try(:first_name) if self.first_name.blank?
    self.last_name = self.auth.try(:last_name) if self.last_name.blank?
    <% if username? %>self.username = self.auth.try(:username) if self.username.blank?
    <% end %>self.skip_email_confirmation = true

    # We need to reassign the user fields if the user is already created
    self.user.attributes = user_params if self.user
    self.auth
  end
  <% end %>

  private

  def validate_models
    self.user.errors.each { |k, v| errors[k] = v } unless self.user.valid?

    <% if oauth? %>
    if self.auth.present?
      self.auth.errors.each { |k, v| errors[k] = v } unless self.auth.valid?
    end
    <% end %>
  end

  def persist!
    ActiveRecord::Base.transaction do
      self.user.save!
    end
  end

  def send_confirmation!
    self.user.send_confirmation if self.email
  end

  def send_welcome!
    self.user.send_welcome if self.email
  end

  def user_params
    {
      email: self.email,
      <% if username? %>username: self.username,
      <% end %>password: self.password,
      password_confirmation: self.password_confirmation,
      first_name: self.first_name,
      last_name: self.last_name,
      bio: self.bio,
      website: self.website,
      phone_number: self.phone_number,
      time_zone: self.time_zone
    }
  end
end

