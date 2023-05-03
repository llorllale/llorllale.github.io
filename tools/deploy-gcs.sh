#!/usr/bin/env bash

set -e

SITE_DIR="_site"
BUCKET="gs://george-aristy-my-site/"

function doCmd() {
  echo ""
  echo "$1"
  eval "$1"
  echo ""
}

doCmd "rm -rf $SITE_DIR"

doCmd "bundle exec jekyll b -d $SITE_DIR"

doCmd "tree $SITE_DIR"

doCmd "gsutil -m rm -r $BUCKET/*"

doCmd "gsutil -m cp -r $SITE_DIR/* $BUCKET"