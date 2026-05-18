source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
ruby '3.4.9'
gem 'rails', '~> 8.1.1'
gem 'sqlite3', '~> 2.1'
gem 'puma', '~> 6.4'
gem 'sass-rails', '~> 6.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 5.0'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.12'
gem 'csv'

gem "bootstrap-sass", "~> 3.4"
gem "nokogiri", ">= 1.15"
gem "rack", ">= 3.0"
gem "loofah", ">= 2.21"
gem "actionview", ">= 8.1"

gem "font-awesome-rails"
gem 'bootstrap-social-rails'

gem 'haml-rails', '~> 2.1'
gem 'high_voltage'
gem 'omniauth', '~> 2.1'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'
gem 'simple_form', '~> 5.3'

gem 'browser-timezone-rails'
gem 'jstz-rails3-plus'

gem 'jquery-tablesorter'
gem 'lograge'


group :development, :test do
  gem 'byebug', platform: :mri
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.9'
  gem 'spring'
end

group :development do
  gem 'better_errors'
  gem 'html2haml'
  gem 'rails_layout'
  gem 'binding_of_caller'
end
