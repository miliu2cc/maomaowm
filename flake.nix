{
  description = "MaomaoWM - A dwl-based Wayland compositor with Hyprland-like features";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    wlroots-0_17 = {
      url = "gitlab:freedesktop/wlroots?rev=0.17.4";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, wlroots-0_17 }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in {
      overlays.default = final: prev: {
        wlroots_0_17 = prev.wlroots.overrideAttrs (old: {
          version = "0.17.4";
          src = wlroots-0_17;
          patches = [];
        });

        maomaowm = final.stdenv.mkDerivation rec {
          pname = "maomaowm";
          version = "git-${builtins.substring 0 7 self.rev or "dirty"}";
          
          src = self;

          nativeBuildInputs = with final; [
            meson
            ninja
            pkg-config
            scdoc
          ];

          buildInputs = with final; [
            wlroots_0_17
            wayland
            wayland-protocols
            libinput
            pixman
            xwayland
            libxkbcommon
          ];

          preConfigure = ''
            mkdir -p $out/share/maomao
          '';

          mesonFlags = [
            "-Dprefix=${placeholder "out"}"
            "-Dxwayland=enabled"
          ];

          meta = with final.lib; {
            description = "Hyprland-like Wayland compositor based on dwl";
            homepage = "https://github.com/DreamMaoMao/maomaowm";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
            maintainers = with maintainers; [ ];
          };
        };
      };

      packages.${system}.default = pkgs.maomaowm;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          meson
          ninja
          pkg-config
          wlroots_0_17
          wayland
          wayland-protocols
        ];
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let cfg = config.programs.maomaowm;
        in {
          options.programs.maomaowm = {
            enable = mkEnableOption "MaomaoWM Wayland compositor";
            configFile = mkOption {
              type = types.path;
              default = null;
              description = "Path to maomao config file";
            };
            autostartScript = mkOption {
              type = types.path;
              default = null;
              description = "Path to autostart.sh script";
            };
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [ pkgs.maomaowm ];
            
            xdg.configFile."maomao/config.conf" = mkIf (cfg.configFile != null) {
              source = cfg.configFile;
            };

            xdg.configFile."maomao/autostart.sh" = mkIf (cfg.autostartScript != null) {
              source = cfg.autostartScript;
              executable = true;
            };
          };
        };
    };
}
