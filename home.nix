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
    (writeShellScriptBin "opencode" ''
      export PATH="${nodejs}/bin:$PATH"
      exec ${nodejs}/bin/npx -y opencode-ai "$@"
    '')
    (stdenv.mkDerivation {
      pname = "antigravity";
      version = "1.0.0";
      src = fetchurl {
        url = "https://antigravity.google/cli/downloads/antigravity-linux-x64";
        sha256 = "sha256-S8nNdNjyOLvF5TPVTPUdrQSXFjBZ1FGEppaYadn44N8=";
      };
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/antigravity
        chmod +x $out/bin/antigravity
      '';
    })
  ]);

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

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "vim";

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
    initContent = ''
      bindkey '^f' autosuggest-accept
      export PROTO_HOME="$HOME/.proto"
      export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
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
      if [ -t 1 ] && [ -x "$(command -v zsh)" ]; then
        exec zsh
      fi
    '';
  };

  systemd.user.services.opencode-web = pkgs.lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "OpenCode Web Server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h";
      ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/opencode web --port 4096 --hostname 0.0.0.0";
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
}
