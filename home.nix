{ config, pkgs, user ? "warp", ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = pkgs.lib.mkDefault user;
  home.homeDirectory = pkgs.lib.mkDefault "/Users/${user}";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    # the font everything renders in
    nerd-fonts.hack

    # shared CLI packages
    bun
    ollama
    sqlite
    gh
    proto
  ] ++ (lib.optionals stdenv.isLinux [
    # custom Linux packages
    docker
    docker-compose
    (writeShellScriptBin "opencode" ''
      export PATH="${nodejs}/bin:$PATH"
      exec ${nodejs}/bin/npx -y opencode-ai "$@"
    '')
    (stdenv.mkDerivation {
      pname = "antigravity";
      version = "1.1.4";
      src = fetchurl {
        url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/linux-x64/cli_linux_x64.tar.gz";
        sha256 = "sha256-qqtC45XLTjv+WuiJlKNAhl2Un3qefwYE/6Kj8eiq2/o=";
      };
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src -C $out/bin antigravity
        chmod +x $out/bin/antigravity
      '';
    })
  ]);

  # Automatically install Docker Engine on Linux if not present
  home.activation.installDocker = pkgs.lib.mkIf pkgs.stdenv.isLinux (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v dockerd &>/dev/null; then
        echo "Docker Engine not found. Installing..."
        export PATH="${pkgs.curl}/bin:${pkgs.gnupg}/bin:/usr/bin:/bin:$PATH"
        sudo apt-get update -qq
        sudo apt-get install -y -qq ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        echo ""
        echo ">>> Docker Engine installed. Run this to activate group membership in current shell:"
        echo "    newgrp docker"
        echo "    (or reboot / re-login for a permanent fix)"
      else
        echo "Docker Engine is already installed."
      fi
    ''
  );

  # Automatically install and run Tailscale on Linux if not present
  home.activation.installTailscale = pkgs.lib.mkIf pkgs.stdenv.isLinux (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v tailscale &>/dev/null; then
        echo "Tailscale not found. Installing system-level Tailscale..."
        export PATH="${pkgs.curl}/bin:/usr/bin:/bin:$PATH"
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo tailscale up
      else
        echo "Tailscale is already installed."
      fi
    ''
  );

  # Automatically install chrome-headless-shell on Linux if not present
  home.activation.installChromeHeadlessShell = pkgs.lib.mkIf pkgs.stdenv.isLinux (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v chrome-headless-shell &>/dev/null; then
        echo "chrome-headless-shell not found. Installing..."
        export PATH="${pkgs.curl}/bin:${pkgs.unzip}/bin:/usr/bin:/bin:$PATH"
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
          libasound2 libatk-bridge2.0-0 libatspi2.0-0 libcups2 \
          libdrm2 libgbm1 libnspr4 libnss3 libpango-1.0-0 \
          libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2
        curl -fsSL https://storage.googleapis.com/chrome-for-testing-public/151.0.7922.34/linux64/chrome-headless-shell-linux64.zip \
          -o /tmp/chrome-headless-shell.zip
        sudo unzip -o /tmp/chrome-headless-shell.zip -d /usr/local/lib/
        sudo ln -sf /usr/local/lib/chrome-headless-shell-linux64/chrome-headless-shell \
          /usr/local/bin/chrome-headless-shell
        rm -f /tmp/chrome-headless-shell.zip
        echo "chrome-headless-shell installed."
      else
        echo "chrome-headless-shell is already installed."
      fi
    ''
  );

  # Automatically clone the monorepo workspace if not present
  home.activation.cloneMonorepo = pkgs.lib.mkIf pkgs.stdenv.isLinux (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "/home/warp/monorepo" ]; then
        echo "Cloning monorepo workspace..."
        export PATH="${pkgs.git}/bin:/usr/bin:/bin:$PATH"
        git clone git@github.com:warpy/monorepo.git /home/warp/monorepo
      else
        echo "monorepo workspace is already cloned."
      fi
    ''
  );

  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    EDITOR = "vim";
    BASH_ENV = "${config.home.homeDirectory}/.bashrc";
  } // lib.optionalAttrs stdenv.isLinux {
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "/usr/local/bin/chrome-headless-shell";
    PUPPETEER_EXECUTABLE_PATH = "/usr/local/bin/chrome-headless-shell";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
    envExtra = ''
      # PATH setup for *all* zsh invocations, including non-interactive ones.
      # ~/.zshenv is sourced by zsh unconditionally, unlike ~/.zshrc which is
      # interactive-only. This ensures opencode agents and other tools that
      # spawn non-interactive shells can find Nix-installed binaries.
      # Order: system Nix daemon (lowest) < user Nix profile < proto (highest).
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null
      export PATH="$HOME/.nix-profile/bin:$PATH"
      export PROTO_HOME="$HOME/.proto"
      export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
      # Non-interactive bash (e.g. bash -c "...") sources $BASH_ENV for PATH.
      # Set it here in .zshenv so it's inherited by bash subprocesses from zsh.
      export BASH_ENV="$HOME/.bashrc"
    '';
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      gs = "git branch && git status -s";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.nix-profile/bin:$PATH"
      if [ -t 1 ] && [ -x "$(command -v zsh)" ]; then
        exec zsh
      fi
    '';
  };

  systemd.user.services.opencode-serve = pkgs.lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "OpenCode Serve Daemon";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "/home/warp/monorepo";
      ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/opencode serve --port 4096 --hostname 0.0.0.0";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Sanket Parab";
      email = "sanketsp@gmail.com";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/skills/browser/SKILL.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/skills/browser/SKILL.md";
}
