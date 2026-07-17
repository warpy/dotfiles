#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
if [ "$(uname)" = "Darwin" ]; then
  exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
else
  exec nix run --extra-experimental-features "nix-command flakes" github:nix-community/home-manager/release-26.05 -- switch -b backup --flake ~/.dotfiles#ubuntu
fi
