FROM ruby:2.4.0

# Install NodeJS (6.X, LTS)
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \ 
    && apt-get update \
    && apt-get install -y nodejs

# Copy degust into the container
ADD . /opt/degust
WORKDIR /opt/degust

# Run setup tasks
RUN bundle install
RUN rake degust:deps
RUN rake degust:build RAILS_ENV=production
RUN rake db:migrate

# Run server
CMD rails s -p 3000 -b '0.0.0.0'
