{
  description = "Maomao Wayland Compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: let
    systems = ["x86_64-linux"
    "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forEachSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {

          
          packages.default = pkgs.stdenv.mkDerivation rec {
            pname = "maomaowm";
            version = "0.1.4";
        
            src = ./.;

            # 修改配置目录
            postPatch = ''
            substituteInPlace meson.build \
              --replace "run_command('sh', '-c', 'echo \$HOME', check: true).stdout().strip()" \
                "meson.current_build_dir()" \
                --replace ".config/maomao" \
                "config"
            '';

            # 添加安装后的处理
            postInstall = ''
            mkdir -p $out/etc/maomao
            cp -r $TMPDIR/build/config/* $out/etc/maomao/ || true
            '';
        
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
        };
        # 导出覆盖层
        overlays.default = final: prev: {
          maomaowm = self.packages.${system}.default;
        };

      }
    ) // {
        # 导出NixOS配置
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ inputs.self.overlays.default ];
          })
          ];
    };
  };
}
