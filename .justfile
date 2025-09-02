#!/usr/bin/env just --justfile

set quiet
set ignore-comments

_default:
  just --list

bootstrap cluster recipe="all":
  echo "Bootstrapping cluster: {{cluster}}..."
  just ./clusters/{{cluster}}/{{recipe}}
