#!/usr/bin/env bash

DIR="talos/factory"
force=false

while getopts ":v:h:f" opt; do
  case ${opt} in
    v ) version="$OPTARG" ;;
    h ) hash="$OPTARG" ;;
    f ) force=true ;;
    \? ) echo "Usage: $0 [-v <version>] [-h <hash>] [-f]" >&2
         exit 1 ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$version" ]; then
  echo "Version is required. Please specify a version using the -v flag."
  exit 1
fi

if [ -z "$hash" ]; then
  echo "Hash is required. Please specify a hash using the -h flag."
  exit 1
fi

DIR="$DIR/$(echo $hash | cut -c -10)/$version"

function get() {
  local file_name="$1"
  local url="$2"

  mkdir -p "$DIR"
  curl --fail -# -Lo "$file_name" "$url"
  if [ $? -ne 0 ]; then
    echo "Error downloading $url. Exiting."
    rm -rf $DIR
    exit 1
  fi
}

function set_ownership_recursively() {
  local directory="$1"
  chown -R $USER:$USER "$directory"
}

function download() {

  # Check if force flag is set or files do not exist
  if $force || [ ! -f "$DIR/initramfs-amd64.xz" ] || [ ! -f "$DIR/kernel-amd64" ]; then
    get "$DIR/initramfs-amd64.xz" "https://factory.talos.dev/image/$hash/$version/initramfs-amd64.xz"
    echo "initramfs-amd64.xz download complete."

    get "$DIR/kernel-amd64" "https://factory.talos.dev/image/$hash/$version/kernel-amd64"
    echo "kernel-amd64 download complete."

    echo "Download complete."

    # Set ownership recursively for all files and directories in $DIR
    set_ownership_recursively "$DIR"
  else
    echo "Files already exist. Skipping download."
  fi
}

download