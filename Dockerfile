# Build part 1
FROM ruby:2.4.6-stretch AS degust-builder

# Install node and R
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && echo 'deb http://cran.rstudio.org/bin/linux/debian stretch-cran35/' > '/etc/apt/sources.list.d/r-base.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' \
    && apt-get update \
    && apt-get install -y nodejs r-base \
    && rm -rf /var/lib/apt/lists/*

# Install R libs
RUN Rscript -e "install.packages(c('BiocManager','jsonlite')); BiocManager::install(version='3.9', ask=F); BiocManager::install(c('limma','edgeR','topconfects','RUVSeq'))"

ENV RAILS_ENV=production

# Grab Gemfile first so we can cache the docker layer from gems
WORKDIR /opt/degust-build
COPY Gemfile Gemfile.lock /opt/degust-build/
RUN gem install bundler \
    && bundle install

# Grab the rest of degust for building
COPY . /opt/degust-build

# Build the js front-end
RUN rake degust:deps \
    && rake degust:build \
    && rake assets:precompile

# Copy files into place for the final-image
RUN ./scripts/production-files-copy.sh /opt/degust

###############################################
# Build part 2
FROM ruby:2.4.6-stretch

# Install node and R
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && echo 'deb http://cran.rstudio.org/bin/linux/debian stretch-cran35/' > '/etc/apt/sources.list.d/r-base.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' \
    && apt-get update \
    && apt-get install -y nodejs r-base \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/degust

# Copy the built R libraries
COPY --from=0 /usr/local/lib/R/site-library /usr/local/lib/R/site-library/

# Copy ruby bundler libraries
COPY --from=0 /usr/local/bundle /usr/local/bundle/

# Copy just the staged degust files
COPY --from=0 /opt/degust .

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=1

ARG run_user=root
ARG run_group=root

USER ${run_user}:${run_group}

# Run server (this will also migrate the db if necessary)
CMD ["/opt/degust/scripts/migrate-run.sh"]
