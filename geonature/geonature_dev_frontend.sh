#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run GeoNature in development mode.

readonly front_dir=$(realpath ${1:-"/home/${USER}/workspace/geonature/web/geonature/frontend"})
echo "Path used: ${front_dir}"

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
