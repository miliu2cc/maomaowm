{
  description = "Maomao Wayland Compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # 包定义
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

          # 安装后处理
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
        overlays.maomao = final: prev: {
          maomaowm = self.packages.${system}.default;
        };
      }
    ) // {
      # 全局覆盖层导出（确保可直接访问）
      overlays = {
        default = self.overlays.maomao;
      };
    };
}
