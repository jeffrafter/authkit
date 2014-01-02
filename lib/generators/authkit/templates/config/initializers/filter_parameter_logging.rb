
# Authkit specific parameters should be filtered from logs and errors. This
# prevents them from unintentionally appearing in reports or leaking when
# doing reviews.
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :otp_secret_key,
  :token,
  :remember_token,
  :confirmation_token,
  :reset_password_token,
  :unlock_token,
  :first_name,
  :last_name,
  :phone_number,
  :username,
  :email,
  :confirmation_email,
  :current_sign_in_ip,
  :last_sign_in_ip
]
