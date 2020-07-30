Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Rails.application.secrets.twitter_provider_key, Rails.application.secrets.twitter_provider_secret
  provider :google_oauth2, Rails.application.secrets.google_provider_key, Rails.application.secrets.google_provider_secret
  provider :github, Rails.application.secrets.github_provider_key, Rails.application.secrets.github_provider_secret, scope: ""
end
