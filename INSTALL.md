Install
---------------

Ensure rails 4.2 is installed.  Install the necessary gems:

    bundle install

Build the js frontend

    rake degust:deps
    rake degust:build

For production build (minifies js, and no source-maps)

    rake degust:build RAILS_ENV=production


For development:

    (cd degust-frontend ; ./node_modules/.bin/grunt build)
    (cd degust-frontend ; ./node_modules/.bin/grunt watch)
    rails s


For production deploy.  Configure `config/deploy/production.rb`

    cap production deploy







Using rbenv
----------

As the install user:
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv

Add to .bashrc
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
  export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

Install ruby-build
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

Install ruby 2.4.0
  rbenv install 2.4.0

And use it
  rbenv global 2.4.0

Install bundler
  gem install bundler



