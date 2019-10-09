#!/usr/bin/env bash

heroku pg:backups:capture &&
heroku pg:backups:download &&
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d ci_metrics_dev latest.dump &&
rm latest.dump
