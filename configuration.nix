# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      <nixos-hardware/lenovo/thinkpad/x280>
      ./hardware-configuration.nix
    ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
    ];
  };

  services.hardware.bolt.enable = true;

  # services.sshd.enable = true;

  #
  # Backup
  # Reference: https://www.codyhiar.com/blog/repeated-tasks-with-systemd-service-timers-on-nixos/
  # To make it run at the user level, need to do this: https://nixos.org/manual/nixos/stable/index.html#sect-nixos-systemd-nixos
  # I just copied all my ssh stuff into the root dir for now.

  systemd.services.duplicity_backup= {
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ bash duplicity nawk jq ];
    script = ''
      /home/jevin/code/github/duplicity-backup.sh/duplicity-backup.sh -c /home/jevin/.config/duplicity-backup.conf -b
    '';
  };
  systemd.timers.duplicity_backup = {
    wantedBy = [ "timers.target" ];
    partOf = [ "duplicity_backup.service" ];
    timerConfig = {
      OnUnitActiveSec = "24h"; # 24 hours since it was run last
      Unit = "duplicity_backup.service";
    };
  };


  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  #
  # https://discourse.nixos.org/t/system-with-nixos-how-to-add-another-extra-distribution/5767/7
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # boot.loader.grub.extraEntries = ''
# 	menuentry "Windows Boot Manager (on /dev/nvme0n1p4)" --class windows --class os {
# 		insmod part_gpt
# 		insmod fat
# 		search --no-floppy --fs-uuid --set=root 40E2-A3BF
# 		chainloader /EFI/Microsoft/Boot/bootmgfw.efi
# 	}
#
#
#	menuentry "Arch" --class arch --class os {
		# insmod part_gpt
		# insmod ext2
		# insmod fat
		# search --no-floppy --fs-uuid --set=root 40E2-A3BF
		# chainloader /EFI/fedora/grubx64.efi
	# }
# '';

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  # Jevin - To add the printer; 1. `nix-shell -p hplip` 2. hp-makeuri <IP> 3. Add that URL to cups

  services.chrony.enable = true;
  services.timesyncd.enable = false;

  # Enable sound.
  # sound.enable = false;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = false;
  programs.noisetorch.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.sane.enable = true;
  hardware.sane.drivers.scanSnap.enable = true;
  hardware.enableAllFirmware = true;

  # Amateur radio stuff

  services.sdrplayApi.enable = true;
  nixpkgs.overlays = [
    (
      self: super:
      {
        soapysdr-with-plugins = self.soapysdr.override { extraPackages = [ self.soapysdrplay ]; };
        sdrpp-with-sdrplay = self.sdrpp.override { sdrplay_source= true; };
      }
    )
    # Zoom screen sharing
    (
      self: super:
      {
       zoomUsFixed = pkgs.zoom-us.overrideAttrs (old: {
        postFixup = old.postFixup + ''
        wrapProgram $out/bin/zoom-us --unset XDG_SESSION_TYPE
      '';});
         zoom = pkgs.zoom-us.overrideAttrs (old: {
      postFixup = old.postFixup + ''
        wrapProgram $out/bin/zoom --unset XDG_SESSION_TYPE
      '';});
      }
      )
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jevin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "dialout" "audio"]; # Dialout if for usb/serial access for arduino
  };

  # users.users.tyler = {
  #   shell = pkgs.zsh;
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" "networkmanager" "docker" "dialout" "audio"]; # Dialout if for usb/serial access for arduino
  # };

  # Add unstable packages: https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  # Be sure to change the added channel to match the actually channel below
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
    };


    permittedInsecurePackages = [
      "electron"
      "todoist-electron"
      #"adobe-reader"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    firefox
    neofetch
    ranger
    spotify
    unstable.obsidian
    git
    unstable.zoom-us
    speedtest-cli
    pavucontrol
    unstable.synology-drive
    kitty
    unstable._1password-gui
    unstable.slack
    unstable.k9s
    kubectl
    docker
    ripgrep
    file
    ffmpeg
    imagemagickBig
    google-chrome
    killall
    ruby
    gnumake
    gcc
    bundix
    python-qt
    dig
    ldns # drill
    kubernetes-helm
    zathura
    xournalpp
    dropbox
    libreoffice
    unzip
    todoist-electron
    findutils # For ranger
    mlocate # For ranger
    fzf # For ranger
    unstable.yt-dlp
    arduino
    kicad
    tmux
    mutt-wizard
    neomutt # mutt-wizard
    curl # mutt-wizard
    isync # mutt-wizard
    msmtp # mutt-wizard
    pass # mutt-wizard
    gnupg # mutt-wizard
    pinentry # mutt-wizard
    notmuch # mutt-wizard
    lieer # mutt-wizard
    lynx # mutt-wizard
    w3m # mutt-wizard
    abook # mutt-wizard
    urlscan # mutt-wizard
    python38Packages.goobook # mutt
    awscli2
    python38Full
    python38Packages.wxPython_4_0
    hugo
    nodejs-16_x
    networkmanager-l2tp
    qbittorrent
    pywal
    steam
    wally-cli
    discord
    vlc
    cubicsdr
    sdrangel
    gqrx
    sdrpp-with-sdrplay
    hamlib_4
    wsjtx
    unstable.element-desktop-wayland
    blueberry
    helvum
    esphome
    duplicity
    etcher
    signal-desktop
    ansible_2_10
    gcalcli
    unstable.nix-template
    termdown
    httpie
    kubectx
    todoist
    peco # For todoist
    qalculate-gtk
  ];

  programs.gnupg.agent.enable = true;

  programs.zsh.enable = true;
  programs.vim = {
    defaultEditor = true ;
    package = pkgs.vimHugeX;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      swayidle
      waybar
      wl-clipboard
      mako # notification daemon
      rofi
      rofi-calc
      #wofi
      wlsunset
      pamixer
      grim
      swappy
      slurp
      clipman
      brightnessctl
      autotiling
      wdisplays
      copyq
      kooha
      wf-recorder
      jq # For waybar weather
    ];
  };

  environment.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1"; # For Arduino & Wayland
    WLR_DRM_NO_MODIFIERS = "1"; # For external monitor issues in sway
  };


  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "jevin" ];
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # ----- USER STUFF ------
  #
  #
  fonts = {
    fonts = [
              pkgs.meslo-lgs-nf
              pkgs.weather-icons
            ];
            fontconfig.defaultFonts.emoji = [
              "MesloLGS NF"
              "Weather Icons"
            ];
  };

  virtualisation.docker.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  services.fwupd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  boot.kernelPackages = pkgs.linuxPackages_5_15;

}

