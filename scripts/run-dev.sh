#!/bin/sh

rake db:migrate

(cd degust-frontend ; ./node_modules/.bin/webpack --watch) &

rails s
