OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # https://github.com/mkdynamic/omniauth-facebook
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'], {
    scope: 'email',
    display: 'popup',
    image_size: 'square', # 50x50
    reauthenticate: true
  }

  # https://github.com/arunagw/omniauth-twitter
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], {
    image_size: 'bigger', # 73x73
    authorize_params: {
      force_login: true
    }
  }

  # https://github.com/zquestz/omniauth-google-oauth2
  provider :google_oauth2, ENV['GOOGLE_API_CLIENT_ID'], ENV['GOOGLE_API_CLIENT_SECRET'], {
    access_type: 'offline',
    prompt: 'consent', # To get an offline access token you must specify 'consent'
    image_aspect_ratio: 'square',
    scope: 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile',
    redirect_uri:"#{ENV['DOMAIN']}/auth/google_oauth2/callback"
  }

  # https://github.com/jamiew/omniauth-tumblr
  provider :tumblr, ENV['TUMBLR_KEY'], ENV['TUMBLR_SECRET']

  # https://github.com/soundcloud/omniauth-soundcloud
  provider "soundcloud", ENV['SOUNDCLOUD_CLIENT_ID'], ENV['SOUNDCLOUD_SECRET']
end
