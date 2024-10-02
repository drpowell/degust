
# Development with docker

Create a docker container for development

    docker build -f Dockerfile-dev . --tag degust-dev


Run a development environment using the current directory.  This will watch js files and rebuild.

    docker run --env SECRET_KEY_BASE=test -p 8001:3000 \
       --volume $(pwd):/opt/degust \
       degust-dev
