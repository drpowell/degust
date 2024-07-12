# Build part 1
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

# Install node and R
RUN apt-get update \
    && apt-get install -y curl git libsqlite3-dev \
    && curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && echo "deb http://cran.rstudio.org/bin/linux/ubuntu noble-cran40/" > '/etc/apt/sources.list.d/r-base.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 51716619E084DAB9 \
    && apt-get update \
    && apt-get install -y nodejs r-base \
    && rm -rf /var/lib/apt/lists/*

# Install ruby
RUN git clone https://github.com/rbenv/ruby-build.git \
    && PREFIX=/usr/local ./ruby-build/install.sh \
    && ruby-build -v 2.4.6 /usr/local

# Install R libs
RUN Rscript -e "install.packages(c('BiocManager','jsonlite')); BiocManager::install(pkgs=c('limma','edgeR','topconfects','RUVSeq'),version='3.19', ask=F)"

ENV RAILS_ENV=production

# Grab Gemfile first so we can cache the docker layer from gems
WORKDIR /opt/degust

COPY Gemfile Gemfile.lock /opt/degust/
RUN gem install bundler -v 2.3.5 \
    && bundle install

# Grab the rest of degust
COPY . /opt/degust/

# Build the js front-end
RUN rake degust:deps \
    && rake degust:build \
    && rake assets:precompile

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=1

ARG run_user=root
ARG run_group=root

USER ${run_user}:${run_group}

# Run server (this will also migrate the db if necessary)
CMD ["/opt/degust/scripts/migrate-run.sh"]
