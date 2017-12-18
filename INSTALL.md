# Install
Degust can be installed natively or using Docker.

## Native

### Install Ruby using rbenv (optional)

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

### Install Degust

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

## Docker
Ensure Docker is installed, clone this repository, and then from inside the cloned
repository, run:

    docker build . --tag degust

Once the build process has completed, you will have a docker image tagged as "degust" on your system.
To run this container, run:

    docker run -p 8001:3000 --volume /tmp/degust:/opt/degust/uploads degust 

This will start Degust in the Docker container, and allow access to the container via port 8001 on your machine.
The container directory `/opt/degust/uploads` is mapped to `/tmp/degust` on the host.
To access the website, go to `http://localhost:8001/` on your web browser. 
You can change `8001` to any port you wish  to have Degust listening on 
(eg, `-p 80:3000` for a public production service).
