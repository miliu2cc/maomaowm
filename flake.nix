{
  description = "Maomao Wayland Compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
  in {
    overlays.default = final: prev: {
      # 直接复用nixpkgs中的wlroots_0_17
      maomaowm = prev.callPackage ({ mkDerivation, meson, ninja, pkg-config
        , wayland, wayland-protocols, wlroots_0_17, libinput, libxkbcommon
        , pixman, json-c, scdoc
      }: mkDerivation {
        pname = "maomaowm";
        version = "git";
        src = ./.;
        nativeBuildInputs = [ meson ninja pkg-config scdoc ];
        buildInputs = [
          wayland 
          wayland-protocols 
          wlroots_0_17 
          libinput
          libxkbcommon 
          pixman 
          json-c
        ];
        mesonFlags = [ "--prefix=${placeholder "out"}" ];
      }) {};
    };

    nixosModules.default = { config, lib, pkgs, ... }:
    with lib;
    let cfg = config.services.maomaowm;
    in {
      options.services.maomaowm.enable = mkEnableOption "maomaowm compositor" // {
        default = true;
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [ pkgs.maomaowm ];
        
        systemd.user.services.maomaowm = {
          description = "Maomao Wayland Compositor";
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.maomaowm}/bin/maomao";
            Restart = "on-failure";
          };
        };

        # 提供空配置文件模板到/etc
        environment.etc."maomao/config.conf.example".text = "";
        environment.etc."maomao/autostart.sh.example".text = "";
      };
    };

    packages.${system}.default = pkgs.maomaowm;
  };
}
