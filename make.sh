#!/usr/bin/env bash

set -eo pipefail

fatal() {
  echo ${@:2}
  return $1
}

build() {
  # find all roles
  local roles="$(findRoles)"

  # build packages
  local role; for role in $roles; do
    echo processing $role ...
    local version="$(awk '$1=="version:" {print $2}' $role/meta.yml)"
    tar czf $role-${version:?missing}.tar.gz -C $role .
  done

  # switch to gh-pages branch
  git fetch
  git checkout -t origin/gh-pages

  # ensure existing versions are unchanged
  local changedPackages="$(git diff --name-only | grep ".tar.gz$")"
  [ -z "$changedPackages" ] || fatal 1 "Changed roles should have versions updated together: $changedPackages."

  # ensure new role versions are provided
  local role; for role in $(findRoles); do
    egrep -q "^version: [0-9]+\.[0-9]+\.[0-9]+" $role/meta/main.yml
  done
}

deploy() {
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add *.tar.gz
  git diff --quiet || git commit -m "update"
  git push
}

findRoles() {
   find . -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n"
}

main() {
  build
  if [ "$GITHUB_EVENT_NAME" == "push" ];then
    deploy
  fi
}

main
