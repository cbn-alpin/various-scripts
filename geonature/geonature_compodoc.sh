#!/usr/bin/env bash
# Encoding : UTF-8
# Script to run Compodoc on GeoNature frontend.

readonly front_dir="/home/${USER}/workspace/geonature/web/geonature/frontend"

# Go to GeoNature frontend directory
cd ${front_dir}

# Enable Nvm
. ~/.nvm/nvm.sh;
nvm use;

# Run Compodoc
npx compodoc \
    --tsconfig=src/tsconfig.app.json \
    --toggleMenuItems=all \
    --disableLifeCycleHooks \
    --output=../docs/build/html/frontend/