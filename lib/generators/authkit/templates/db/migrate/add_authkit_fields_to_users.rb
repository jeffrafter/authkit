# Generated by Authkit.
#
# Add fields to the users table for managing authentication.
#
class AddAuthkitFieldsToUsers < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :email, :string, :default => "", :null => false
    add_column :users, :password_digest, :string, :default => "", :null => false
    <% if username? %>add_column :users, :username, :string, :limit => 64
    <% end %>
    add_column :users, :time_zone, :string, :default => "Eastern Time (US & Canada)"
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :bio, :text
    add_column :users, :website, :string
    add_column :users, :phone_number, :string

    # One time password key for two-factor auth
    add_column :users, :otp_secret_key, :string

    # Tracking
    add_column :users, :sign_in_count, :integer, :default => 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Analytics
    add_column :users, :original_source, :string
    add_column :users, :session_source, :string
    add_column :users, :first_visit_at, :datetime
    add_column :users, :last_visit_at, :datetime

    # Forgot password / Password reset
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_token_created_at, :datetime

    # Confirmation
    add_column :users, :confirmation_email, :string
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmation_token_created_at, :string

    # Lockout
    add_column :users, :failed_attempts, :integer, :default => 0
    add_column :users, :locked_at, :datetime
    add_column :users, :unlock_token, :string
    add_column :users, :unlock_token_created_at, :datetime

    add_column :users, :suspended_at, :datetime

    # Make sure the validations are enforced
    add_index :users, :email, :unique => true
    <% if username? %>add_index :users, :username, :unique => true
    <% end %>add_index :users, :reset_password_token, :unique => true
    add_index :users, :confirmation_token, :unique => true
    add_index :users, :unlock_token, :unique => true

  end

  def self.down
    drop_column :users, :email
    drop_column :users, :password_digest
    <% if username? %>drop_column :users, :username
    <% end %>
    drop_column :users, :time_zone
    drop_column :users, :first_name
    drop_column :users, :last_name
    drop_column :users, :bio
    drop_column :users, :website
    drop_column :users, :phone_number

    drop_column :users, :otp_secret_key

    # Tracking
    drop_column :users, :sign_in_count
    drop_column :users, :current_sign_in_at
    drop_column :users, :last_sign_in_at
    drop_column :users, :current_sign_in_ip
    drop_column :users, :last_sign_in_ip

    # Analytics
    drop_column :users, :original_source
    drop_column :users, :session_source
    drop_column :users, :first_visit_at
    drop_column :users, :last_visit_at

    # Forgot password / Password reset
    drop_column :users, :reset_password_token
    drop_column :users, :reset_password_created_at

    # Confirmation
    drop_column :users, :confirmation_email
    drop_column :users, :confirmation_token
    drop_column :users, :confirmation_token_created_at

    # Lockout
    drop_column :users, :failed_attempts
    drop_column :users, :locked_at
    drop_column :users, :unlock_token
    drop_column :users, :unlock_token_created_at
  end
end

