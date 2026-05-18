#!/bin/sh

# Remove a potentially pre-existing server.pid for Docker.
rm -f /opt/degust/tmp/pids/server.pid

rake db:migrate

(cd degust-frontend ; ./node_modules/.bin/webpack --watch) &

rails s -b 0.0.0.0
