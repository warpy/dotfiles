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
    (stdenv.mkDerivation {
      pname = "opencode";
      version = "1.0.0";
      src = fetchurl {
        url = "https://github.com/opencode-ai/opencode/releases/download/v1.0.0/opencode-linux-x64";
        sha256 = "0000000000000000000000000000000000000000000000000000";
      };
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/opencode
        chmod +x $out/bin/opencode
      '';
    })
    (stdenv.mkDerivation {
      pname = "antigravity";
      version = "1.0.0";
      src = fetchurl {
        url = "https://antigravity.google/cli/downloads/antigravity-linux-x64";
        sha256 = "0000000000000000000000000000000000000000000000000000";
      };
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/antigravity
        chmod +x $out/bin/antigravity
      '';
    })
  ]);

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
