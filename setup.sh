#!/usr/bin/env bash

mix deps.get &&
mix ecto.setup &&
cp -n example.env .env &&
(cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development)
