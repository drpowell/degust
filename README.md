Install
---------------

Ensure rails 4.2 is installed

    bundle install

Build the js frontend

    rake degust:deps
    rake degust:build

For production build (minifies js, and no source-maps)

    rake degust:build RAILS_ENV=production


For frontend development:
  
   
    (cd degust-frontend ; ./node_modules/.bin/grunt build)
    (cd degust-frontend ; ./node_modules/.bin/grunt watch)


For production deploy

    cap production deploy
