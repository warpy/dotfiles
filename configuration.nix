{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };

  # macOS path_helper picks up /etc/paths and /etc/paths.d/* for ALL shells,
  # including non-interactive ones. This ensures Nix-installed binaries are
  # on PATH regardless of how a shell is invoked (login, interactive, or
  # non-interactive subprocess from tools like opencode agents).
  environment.etc."paths.d/nix".text = ''
    /nix/var/nix/profiles/default/bin
  '';

  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "opencode"
      "guywaldman/tap/glue"
    ];
    casks = [
      "wezterm"
      "claude-code"
      "antigravity"
      "antigravity-ide"
      "docker-desktop"
      "bruno"
      "tailscale"
    ];
  };
}
