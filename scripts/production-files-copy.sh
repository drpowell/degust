#!/bin/bash

dest="$1"

if [ -z "$dest" ]; then
  echo "Missing destination"
  exit 1
fi

mkdir -p "$dest"

cp config.ru Gemfile* Rakefile VERSION "$dest"
cp -r app lib bin config public scripts "$dest"

mkdir "$dest/db"
cp -r db/{migrate,schema.rb,seeds.rb} "$dest/db"

mkdir "$dest/degust-frontend"
cp -r degust-frontend/kegg degust-frontend/degust-dist* "$dest/degust-frontend"

for d in db-file uploads log tmp tmp/pids tmp/cache tmp/sockets tmp/R-cache; do
  mkdir "$dest/$d"
done

