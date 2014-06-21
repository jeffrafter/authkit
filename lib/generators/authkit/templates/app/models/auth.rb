class Auth < ActiveRecord::Base
  belongs_to :user

  def full_name
    self.parsed_env["info"]["name"] rescue formatted_provider
  end

  def first_name
    self.parsed_env["info"]["first_name"] rescue nil
  end

  def last_name
    self.parsed_env["info"]["last_name"] rescue nil
  end

  def image_url
    if <%= (providers - [:tumblr]).map{|p| "#{p}?"}.join(" || ") %>
      self.parsed_env["info"]["image"] rescue nil
    <% if provider?(:tumblr) %>elsif tumblr?
      self.parsed_env["info"]["avatar"] rescue nil<% end %>
    end
  end

  def username
    <% if provider?(:google) %># Google does not provide a username<% end %>
    self.parsed_env["info"]["nickname"] rescue nil
  end

  def expired?
    self.token_expires_at && self.token_expires_at < Time.now
  end

  <% providers.each do |provider| %>
  def <%= provider %>?
    provider == "<%= provider %>"
  end
  <% end %>

  def refresh!
    return if refresh_token.blank?
    <% if provider?(:google) %>refresh_google if google?<% end%>
    save!
  end

  protected

  <% if provider?(:google) %>
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
  <% end %>

  def formatted_provider
    <% providers.each do |provider| %>
    return <%= formatted_providers[provider] %> if <%= provider %>?
    <% end %>
  end

  def parsed_env
    @parsed_env ||= JSON.parse(self.env) rescue {}
  end
end

