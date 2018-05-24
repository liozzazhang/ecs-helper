#!/usr/bin/env bash

function try () {
    echo -n "Trying to $*... "
}

function ok () {
    echo "ok"
}

function info () {
    echo "$*"
}

function fail () {
    echo "failed"
}

function skip () {
    echo "skipped"
}

function die () {
  echo "ERROR: $*.. exiting..."
  exit 1
}