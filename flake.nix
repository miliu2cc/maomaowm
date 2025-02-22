{
  description = "Maomao Wayland Compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils,lib, ... }@inputs:
    flake-utils.lib.eachDefaultSystem ( system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        maomaowm = pkgs.stdenv.stdenv.mkDerivation rec {
          pname = "maomaowm";
          version = "0.1.4";
        
          src = "./.";
        
          nativeBuildInputs = with pkgs; [
            meson
            unzip
            ninja
            pkg-config
            wayland-scanner
          ];
          buildInputs = with pkgs; [
            wayland
            wayland-protocols
            wlroots_0_17
            libxkbcommon
            pixman
            udev
            libinput
            libGL
            mesa
            xorg.xcbutilwm
            xorg.libX11
            xorg.libXcursor
            xwayland          
          ];
        
          meta = with lib; {
            description = "maomaowm a wayland window manager";
            homepage = "https://github.com/DreamMaoMao/maomaowm";
            license = licenses.mit;
            maintainers = [  ];
          };
        };
      }
    );
}
