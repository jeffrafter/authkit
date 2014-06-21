OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  <% if provider?(:facebook) %>
  # https://github.com/mkdynamic/omniauth-facebook
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'], {
    setup: lambda{ |env|
      default_scope = 'email'
      env['omniauth.strategy'].options[:scope] = env['rack.session']['facebook_oauth_scope'] || default_scope
    },
    display: 'popup',
    image_size: 'square', # 50x50
    reauthenticate: true
  }
  <% end %>

  <% if provider?(:google) %>
  # https://github.com/zquestz/omniauth-google-oauth2
  provider :google_oauth2, ENV['GOOGLE_API_CLIENT_ID'], ENV['GOOGLE_API_CLIENT_SECRET'], {
    setup: lambda{ |env|
      default_scope = 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile'
      env['omniauth.strategy'].options[:scope] = env['rack.session']['google_oauth_scope'] ||  default_scope
    },
    access_type: 'offline',
    prompt: 'consent', # To get an offline access token you must specify 'consent'
    image_aspect_ratio: 'square',
    scope: 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile',
    redirect_uri:"#{ENV['DOMAIN']}/auth/google_oauth2/callback"
  }
  <% end %>

  <% if provider?(:soundcloud) %>
  # https://github.com/soundcloud/omniauth-soundcloud
  provider "soundcloud", ENV['SOUNDCLOUD_CLIENT_ID'], ENV['SOUNDCLOUD_SECRET']
  <% end %>

  <% if provider?(:tumblr) %>
  # https://github.com/jamiew/omniauth-tumblr
  provider :tumblr, ENV['TUMBLR_KEY'], ENV['TUMBLR_SECRET']
  <% end %>

  <% if provider?(:twitter) %>
  # https://github.com/arunagw/omniauth-twitter
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], {
    image_size: 'bigger', # 73x73
    authorize_params: {
      force_login: true
    }
  }
  <% end %>
end
