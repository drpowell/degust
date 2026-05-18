Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV["TWITTER_PROVIDER_KEY"], ENV["TWITTER_PROVIDER_SECRET"]
  provider :google_oauth2, ENV["GOOGLE_PROVIDER_KEY"], ENV["GOOGLE_PROVIDER_SECRET"]
  provider :github, ENV["GITHUB_PROVIDER_KEY"], ENV["GITHUB_PROVIDER_SECRET"], scope: ""
end
