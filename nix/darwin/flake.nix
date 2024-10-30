{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.mkalias
	  # text editors
	  pkgs.vim
	  pkgs.nano
	  pkgs.neovim
	  #pkgs.sublime4
	  # terminal
	  pkgs.alacritty
	  # cli-tools
	  pkgs.git
	  pkgs.zoxide
	  pkgs.eza
	  pkgs.mas
	  pkgs.neofetch
	  pkgs.python311
	  # wm
	  pkgs.aerospace
	  # apps
	  pkgs.obsidian
	  pkgs.aldente
	  pkgs.remmina
	  # ide
	  pkgs.vscode
	  # browsers
	  # trading
	  # pkgs.tradingview
        ];

      homebrew = {
	enable = true;
	brews = [
	  "borders"
	  "powerlevel10k"
	  "zsh-autosuggestions"
	  "zsh-syntax-highlighting"
	];
	casks = [
	  "iina"
	  "the-unarchiver"
	  "google-chrome"
	  "firefox"
	  "sublime-text"
	  "discord"
	  "wezterm"
	  "font-meslo-lg-nerd-font"
	  "spotify"
	  "notion"
	  "anydesk"
	  "tradingview"
	];
	taps = [
	  "FelixKratz/formulae"
	];
	masApps = {
	  "Prime" = 545519333;
	  "MSWord" = 462054704;
	  "MSExcel" = 462058435;
	  "MSPowerPoint" = 462062816;
	  "MSOutlook" = 985367838;
	  "OneDrive" = 823766827;
	  "ColorPicker" = 1545870783;
	  "WhatsApp" = 310633997;
	  "MTJ" = 1557277865;
	};
	onActivation.cleanup = "zap";
	onActivation.autoUpdate = true;
	onActivation.upgrade = true;
      };

      fonts.packages = [
	(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) 
      ];

      system.activationScripts.applications.text = let
  	env = pkgs.buildEnv {
	  name = "system-applications";
    	  paths = config.environment.systemPackages;
    	  pathsToLink = "/Applications";
  	};
      in
	pkgs.lib.mkForce ''
  	# Set up applications.
  	echo "setting up /Applications..." >&2
  	rm -rf /Applications/Nix\ Apps
  	mkdir -p /Applications/Nix\ Apps
  	find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
  	while read src; do
    	  app_name=$(basename "$src")
    	  echo "copying $src" >&2
    	  ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
  	done
      	    '';

      system.defaults = {
	dock.autohide = true;
        dock.persistent-apps = [
	  #"${wezterm}/Applications/WezTerm.app"
	  "/System/Applications/Launchpad.app"
	  "/Applications/Google Chrome.app"
	  "/Applications/WezTerm.app"
	  "/Applications/Discord.app"
	  "/Applications/Spotify.app"
	  "/Applications/Prime Video.app"
	  "/Applications/OneDrive.app"
	  "/Applications/Microsoft Excel.app"
	  "/Applications/Microsoft Word.app"
	  "/Applications/Sublime Text.app"
	  "/System/Applications/TextEdit.app"
	  "/System/Applications/Calculator.app"
	  "/System/Applications/Calendar.app"
	  "/System/Applications/Home.app"
	  "/System/Applications/Time Machine.app"
	  "/System/Applications/App Store.app"
	  "/System/Applications/System Settings.app"
	  "/System/Applications/Utilities/Screenshot.app"
	];
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      modules = [ 
	configuration
	nix-homebrew.darwinModules.nix-homebrew
	{
	  nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;
	    # Apple Silicon Only
            enableRosetta = true;
	    # User owning the Homebrew prefix
            user = "ruben";

	    autoMigrate = true;
	  };
	} 
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."air".pkgs;
  };
}
