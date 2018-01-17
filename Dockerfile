FROM ruby:2.4.0

# Install NodeJS (6.X, LTS)
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \ 
    && apt-get update \
    && apt-get install -y nodejs

# Install R
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
RUN echo 'deb http://cran.rstudio.org/bin/linux/debian jessie-cran34/'
RUN apt-get update && apt-get install -y r-base

# Install R libs
RUN Rscript -e "install.packages(c('seriation', 'jsonlite'), repos='http://cran.rstudio.org')"
RUN Rscript -e "source('http://bioconductor.org/biocLite.R'); biocLite('limma'); biocLite('edgeR')"

# Copy degust into the container
ADD . /opt/degust
WORKDIR /opt/degust

# Run setup tasks
RUN mkdir -p uploads log tmp/pids tmp/cache tmp/sockets tmp/R-cache
RUN bundle install
RUN rake degust:deps
RUN rake degust:build RAILS_ENV=production
RUN rake db:migrate

# Run server
CMD rails s -p 3000 -b '0.0.0.0'
