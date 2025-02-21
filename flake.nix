{
  description = "Maomao Wayland Compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wlroots-0_17 = {
      url = "gitlab:freedesktop/wlroots?ref=0.17.4";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, wlroots-0_17, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
  in {
    overlays.default = final: prev: {
      wlroots-0_17 = prev.callPackage ({ mkDerivation, meson, ninja, pkg-config
        , wayland, wayland-protocols, libinput, libxkbcommon, pixman
        , libdrm, xorg, vulkan-headers, vulkan-loader
      }: mkDerivation {
        pname = "wlroots";
        version = "0.17.4";
        src = inputs.wlroots-0_17;
        nativeBuildInputs = [ meson ninja pkg-config ];
        buildInputs = [
          wayland wayland-protocols libinput libxkbcommon pixman
          libdrm xorg.libX11 vulkan-headers vulkan-loader
        ];
        mesonFlags = [ "-Dexamples=false" ];
      }) {};

      maomaowm = prev.callPackage ({ mkDerivation, meson, ninja, pkg-config
        , wayland, wayland-protocols, wlroots-0_17, libinput, libxkbcommon
        , pixman, json-c, scdoc
      }: mkDerivation {
        pname = "maomaowm";
        version = "git";
        src = ./.;
        nativeBuildInputs = [ meson ninja pkg-config scdoc ];
        buildInputs = [
          wayland wayland-protocols wlroots-0_17 libinput
          libxkbcommon pixman json-c
        ];
        mesonFlags = [ "--prefix=${placeholder "out"}" ];
      }) {};
    };

    nixosModules.default = { config, lib, pkgs, ... }:
    with lib;
    let cfg = config.services.maomaowm;
    in {
      options.services.maomaowm = {
        enable = mkEnableOption "maomaowm wayland compositor";
        package = mkOption {
          type = types.package;
          default = pkgs.maomaowm;
          defaultText = "pkgs.maomaowm";
          description = "maomaowm package to use";
        };
        configFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to configuration file";
        };
        autostartScript = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to autostart script";
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];
        
        systemd.user.services.maomaowm = {
          description = "Maomao Wayland Compositor";
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${cfg.package}/bin/maomao";
            Restart = "on-failure";
            Environment = [
              "XDG_CONFIG_HOME=${if cfg.configFile != null then dirOf cfg.configFile else "$HOME/.config"}"
              "PATH=${pkgs.rofi}/bin:${pkgs.foot}/bin:${pkgs.waybar}/bin"
            ];
          };
        };

        environment.etc = mkMerge [
          (mkIf (cfg.configFile != null) {
            "maomao/config.conf".source = cfg.configFile;
          })
          (mkIf (cfg.autostartScript != null) {
            "maomao/autostart.sh".source = cfg.autostartScript;
          })
        ];
      };
    };

    packages.${system}.default = pkgs.maomaowm;
  };
}
