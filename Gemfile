source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
ruby '2.4.6'
gem 'rails', '~> 5.0.7'
gem 'sqlite3'
gem 'puma', '~> 3.12'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

gem "bootstrap-sass", ">= 3.4.1"
gem "nokogiri", ">= 1.8.5"
gem "rack", ">= 2.0.6"
gem "loofah", ">= 2.2.3"
gem "actionview", ">= 5.0.7.2"

gem "font-awesome-rails"
gem 'bootstrap-social-rails'

gem 'haml-rails'
gem 'high_voltage'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
gem 'simple_form'

gem 'browser-timezone-rails'
#gem 'rails-backup-migrate'

gem 'jquery-tablesorter'


group :development, :test do
  gem 'byebug', platform: :mri
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development do
  gem 'better_errors'
  gem 'html2haml'
  gem 'rails_layout'
  gem 'binding_of_caller'

end
