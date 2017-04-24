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
