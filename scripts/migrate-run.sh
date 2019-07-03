#!/bin/sh

rake db:migrate

exec rails s -p 3000 -b 0.0.0.0
