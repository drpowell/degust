
# Install

Degust can be installed natively or using Docker.

## Native Installation

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

And run it

    rbenv global 2.4.0

Install bundler

    gem install bundler

### External Dependencies

Install R

    https://www.r-project.org/

Install R package dependencies

    Rscript -e "install.packages(c('seriation', 'jsonlite'), repos='http://cran.rstudio.org')"
    Rscript -e "source('http://bioconductor.org/biocLite.R'); biocLite('limma'); biocLite('edgeR')"

### Installing Degust

Ensure rails 5.0 is installed.  Install the necessary gems:

    bundle install

Build the js frontend

    rake degust:deps
    rake degust:build

Make various temporary directories

    mkdir -p uploads log tmp/pids tmp/cache tmp/sockets tmp/R-cache

For production build (minifies js, and no source-maps)

    rake degust:build RAILS_ENV=production

For development:

    (cd degust-frontend ; ./node_modules/.bin/webpack build)
    (cd degust-frontend ; ./node_modules/.bin/webpack --watch)
    rails s

For production deploy, use ansible and docker.  See `deploy/README.md`

## Docker
Ensure Docker is installed, clone this repository, and then from inside the cloned
repository, run:

    docker build . --tag degust

Once the build process has completed, you will have a docker image tagged as "degust" on your system.
To run this container, run:

    docker run -p 8001:3000 --volume /tmp/degust/uploads:/opt/degust/uploads --volume /tmp/degust/db:/opt/degust/db-file degust

This will start Degust in the Docker container, and allow access to the container via port 8001 on your machine.
The container directory `/opt/degust/uploads` is mapped to `/tmp/degust/uploads` on the host.  And the sqlite database
is mapped to `/tmp/degust/db`.  To allow logins, you'll need provied secret keys - see `scripts/example-run-prod.sh`
and include keys from https://console.developers.google.com/apis/credentials

To access the website, go to `http://localhost:8001/` on your web browser.
You can change `8001` to any port you wish  to have Degust listening on
(eg, `-p 80:3000` for a public production service).
