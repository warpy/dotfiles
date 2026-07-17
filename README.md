# dotfiles

Personal Mac and Ubuntu Server setup managed with Nix (nix-darwin and home-manager).

## macOS Setup

From a clean shell:

```sh
# Clone repo
git clone git@github.com:warpy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Bootstrap (Installs Nix, symlinks config, and runs darwin-rebuild)
./bootstrap.sh
```

## Ubuntu Server Setup

From a clean shell:

```sh
# 1. Install Nix
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# 2. Clone repo
git clone git@github.com:warpy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Apply Home-Manager standalone
nix run github:nix-community/home-manager/release-26.05 -- switch --flake ~/.dotfiles#ubuntu
```

## Daily Use

Make your configuration changes inside `~/.dotfiles`, then apply them with:

```sh
./rebuild.sh
```

## Structure

- [flake.nix](file:///Users/warp/dotfiles/flake.nix) — Entry point mapping `mac` and `ubuntu` targets.
- [configuration.nix](file:///Users/warp/dotfiles/configuration.nix) — System-level configurations (macOS defaults, homebrew casks).
- [home.nix](file:///Users/warp/dotfiles/home.nix) — User-level configurations (Zsh, Git, packages).
- [home/](file:///Users/warp/dotfiles/home) — Symlinked raw configurations (WezTerm, agent instructions, herdr keys).

## License

MIT No Attribution (MIT-0). See `LICENSE`.
