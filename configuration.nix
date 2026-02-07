{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
  imports = [ 
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # Network
  networking.hostName = "nixprise";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  # Locatlization and fonts
  time.timeZone = "Asia/Tashkent";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    enable = true;
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = "ter-v24n";
    keyMap = "us";
  };

  # Audio and bluetooth
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Software
  security.polkit.enable = true;
  programs.sway.enable = true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    wget
    flutter
    polkit_gnome
    btop
    unzip
    git
    go
    vim-full
    wl-clipboard 
    steam-run
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  
  # User
  users.users.bob = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "storage" "power" "networkmanager" ];
    shell = pkgs.fish;
    home = "/home/bob";
  };

  # Home Manager
  xdg.portal = {
    enable = true;
    wlr.enable = true; # Специфично для Sway
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*"; # Для версий NixOS 23.11+
  };
  home-manager.users.bob = { pkgs, lib, ... }: {
    home.stateVersion = "25.11";
    nixpkgs.config.allowUnfree = true;
     
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 32;
    };

    # Dark theme for gtk applications
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
    };

    # Dark theme for qt applications
    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style.name = "adwaita-dark";
    };

    home.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      MOZ_ENABLE_WAYLAND = "1";
      GTK_THEME = "Adwaita-dark"; # Dark theme
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = "Mod4";
        terminal = "alacritty";
        startup = [
          { command = "gammastep -O 2750"; always = true; }
          { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway"; }
 	  { command = "brightnessctl set 100%"; }
          { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        ];
        output."*" = {
          mode = "1920x1080@144Hz";
          scale = "1.5";
        };
        input."*" = {
          xkb_layout = "us,ru";
          xkb_options = "grp:win_space_toggle";
        };
        keybindings = let 
          mod = "Mod4";
          run = "nvidia-offload"; 
        in lib.mkOptionDefault {
          "${mod}+Return" = "exec ${run} alacritty";
          "${mod}+b" = "exec ${run} firefox";
          "${mod}+m" = "exec ${run} spotify --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
          "${mod}+d" = "exec ${run} wofi --show drun";
          "${mod}+t" = "exec ${run} AyuGram";
          "${mod}+s" = "exec CHROME_EXECUTABLE=$(which google-chrome-stable) ${run} code";
          "${mod}+Shift+s" = "exec ${run} steam";
          "Print" = "exec grim - | wl-copy";
          "${mod}+Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
          
          # Navigation
          "${mod}+Left" = "focus left";
          "${mod}+Right" = "focus right";
          "${mod}+Up" = "focus up";
          "${mod}+Down" = "focus down";
        };
      };
    };

    programs.vscode = {
      enable = true;

      package = pkgs.vscode.override {
        commandLineArgs = [
          "--ozone-platform-hint=auto"
          "--enable-features=WaylandWindowDecorations"
        ];
      }; 

      profiles.default.extensions = with pkgs.vscode-extensions; [
        dart-code.dart-code
        dart-code.flutter
	vscodevim.vim
      ];

      profiles.default.userSettings = {
        "workbench.colorTheme" = "Default Dark Modern";
        "dart.openDevTools" = "flutter";
        "window.zoomLevel" = 1.5;
      };

      profiles.default.keybindings = [
        {
          key = "alt+t";
          command = "workbench.action.terminal.toggleTerminal";
        }
      ];
    };

    programs.firefox = {
      enable = true;
      profiles.bob = {
        isDefault = true;
        settings = {
          # "layout.css.devPixelsPerPx" = "1.2";
          "browser.startup.page" = 3; 
          "browser.search.defaultenginename" = "DuckDuckGo";
          "browser.search.region" = "US";
          "browser.search.isUS" = true;
	  "extensions.autoDisableScopes" = 0;

          # Dark theme
          "ui.systemUsesDarkTheme" = 1;
          "browser.theme.contenttheme" = 0; # 0 - Dark

          # Disable data collection
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "telemetry.enabled" = false;
          "browser.ping-centre.telemetry" = false;
          "toolkit.telemetry.unified" = false;
          "app.normandy.enabled" = false;

          # Disable animations
          "toolkit.cosmeticAnimations.enabled" = false;
          "browser.tabs.animate" = false;
          "browser.download.animateNotifications" = false;
          "browser.fullscreen.animate" = false;
          "browser.stopReloadAnimation" = true;
          "fp.force_no_unfocused_animations" = true;

          # Rendering optiomizations
          "gfx.webrender.all" = true;
          "layers.acceleration.force-enabled" = true;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DontCheckDefaultBrowser = true;
        DisplayBookmarksBar = "never";

        ExtensionSettings = {
          # uBlock Origin
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          # Dark Reader
          "addon@darkreader.org" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          };
          # Vimium-C
          "vimium-c@gdh1995.cn" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
            installation_mode = "force_installed";
          };
          # Decentraleyes
          "jid1-BoFifL9Vbdl2zQ@jetpack" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
          };
          # Privacy badger
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4638816/privacy_badger17-2025.12.9.xpi";
          };
	  # I Still Don't Care About Cookies
          "idcac-pub@guus.ninja" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi";
          };
        };
      };
    };
    home.packages = with pkgs; [
      # Utility cli
      grim slurp gammastep brightnessctl tree fastfetch
      # Utility gui
      wofi alacritty xfce.thunar pwvucontrol
      # Own software
      ayugram-desktop obsidian google-chrome spotify bitwarden-desktop
    ];
  };

  # System
  services.openssh.enable = true;
  services.dbus.enable = true;
  services.udisks2.enable = true;
  zramSwap.enable = true;
  system.stateVersion = "25.11";

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "bob" ]; 
    };
  };

  # Bootloader
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      device = "nodev";
      useOSProber = true;
      efiSupport = true;
    }; 
  };

  # Конфигурация зависящаяя от железа (в данном случае laptop)
  # Graphical drivers
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; 
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:0:2";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Power optimization
  boot.kernelParams = [ "intel_pstate=no_turbo" ];
  services.power-profiles-daemon.enable = false;
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      # Полное отключение Turbo Boost
      CPU_BOOST_ON_AC = 0;
      CPU_BOOST_ON_BAT = 0;

      # Отключение аппаратного буста Intel (HWP)
      CPU_HWP_DYN_BOOST_ON_AC = 0;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Энергопотребление (EPP)
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Твои пороги заряда (для ASUS TUF работают через tlp)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      USB_AUTOSUSPEND = 0;
    };
  };
}
