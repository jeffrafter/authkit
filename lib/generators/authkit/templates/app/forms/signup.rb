# Multi-model form support object for signup and user creation
class Signup
  include ActiveModel::Model

  attr_accessor :user

  # User
  attr_accessor(
    :email,
    :username,
    :password,
    :password_confirmation,
    :first_name,
    :last_name,
    :bio,
    :website,
    :phone_number,
    :time_zone)

  attr_accessor(
    :terms_of_service)

  validates :terms_of_service, acceptance: true
  validate :validate_models

  def persisted?
    false
  end

  def save
    if valid?
      persist!
      send_confirmation!
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

  private

  def validate_models
    self.user.errors.each { |k, v| errors[k] = v } unless self.user.valid?
  end

  def persist!
    ActiveRecord::Base.transaction do
      self.user.save!
    end
  end

  def send_confirmation!
    self.user.send_confirmation
  end

  def send_welcome!
    self.user.send_welcome
  end

  def user_params
    {
      email: self.email,
      username: self.username,
      password: self.password,
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

