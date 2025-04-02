#!/usr/bin/env just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a script, with `./justfile test`, for example.

set quiet
set ignore-comments

_default:
  just --list

bootstrap cluster recipe="all":
  echo "Bootstrapping cluster: {{cluster}}..."
  just ./clusters/{{cluster}}/{{recipe}}
