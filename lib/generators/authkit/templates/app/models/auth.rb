class Auth < ActiveRecord::Base
  belongs_to :user

  def display_name
    if google?
      self.parsed_env["info"]["name"] rescue "Youtube"
    elsif soundcloud?
      self.parsed_env["info"]["name"] rescue "SoundCloud"
    end
  end

  def display_image_url
    if google? || soundcloud?
      self.parsed_env["info"]["image"] rescue nil
    end
  end

  def display_url
    if google? || soundcloud?
      self.parsed_env["info"]["image"] rescue nil
    end
  end

  def expired?
    self.token_expires_at && self.token_expires_at < Time.now
  end

  def twitter?
    provider == "twitter"
  end

  def facebook?
    provider == "facebook"
  end

  def tumblr?
    provider == "tumblr"
  end

  def google?
    provider == "google_oauth2"
  end

  def soundcloud?
    provider == "soundcloud"
  end

  def refresh!
    return if refresh_token.blank?
    refresh_google if google?
    save!
  end

  protected

  # https://github.com/intridea/omniauth-oauth2/issues/40#issuecomment-21275075
  def refresh_google
    conn = Faraday.new('https://accounts.google.com') do |faraday|
      faraday.request  :url_encoded
      faraday.response :json
      faraday.response :raise_error
      faraday.response :logger unless Rails.env.production?
      faraday.adapter  Faraday.default_adapter
    end
    response = conn.post('/o/oauth2/token', {
      grant_type:    'refresh_token',
      refresh_token: refresh_token,
      client_id:     ENV['google_api_client_id'],
      client_secret: ENV['google_api_client_secret']
    })

    body = response.body

    self.token = body['access_token'] if body['access_token']
    self.token_expires_at = Time.now.utc + body['expires_in'].to_i.seconds
  end

  def parsed_env
    @parsed_env ||= JSON.parse(self.env) rescue {}
  end
end

