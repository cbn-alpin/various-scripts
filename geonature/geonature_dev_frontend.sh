#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature in development mode.

readonly front_dir="/home/${USER}/workspace/geonature/web/geonature/frontend"

# Go to GeoNature frontend directory
cd ${front_dir}

# Enable Nvm
. ~/.nvm/nvm.sh;
nvm use;

# Run GeoNature Angular server in Dev mode
./node_modules/.bin/ng serve \
	--port=4200 \
	--poll=2000 \
	--aot=false \
	--optimization=false \
	--progress=true \
	--sourceMap=false
