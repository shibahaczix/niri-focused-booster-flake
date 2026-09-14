{
  description = "niri-focused-booster: boosts dmem cgroup memory protection for the currently focused window on Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "niri-focused-booster";
            version = "0.3.0";

            src = pkgs.fetchFromGitHub {
              owner = "1Naim";
              repo = "niri-focused-booster";
              rev = "753d981bbfaed0727214109ed8e3ca82240af5a3"; # master @ 2026-09-14, matches Cargo.toml version 0.3.0
              hash = "sha256-gOb+VugBrXeaHreq5fIoXgczYKtSkMws3v2glW4L9Gg=";
            };

            # Vendored via the upstream Cargo.lock shipped next to this flake,
            # so builds are fully reproducible and offline (no IFD needed).
            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            nativeBuildInputs = [ pkgs.pkg-config ];

            # `xcb` (built with the "res" feature) links against libxcb / xcb-res
            # to resolve the X11 client PID of Xwayland windows via XRes.
            buildInputs = [ pkgs.libxcb ];

            meta = {
              description = "Boosts dmem cgroup memory protection for the focused window on Niri";
              longDescription = ''
                niri-focused-booster listens to Niri focus events, resolves the
                focused window's PID to its cgroup, and raises that cgroup's
                dmem memory protection limit while lowering everyone else's to 0.
                For Xwayland windows under xwayland-satellite it resolves the
                focused X11 client PID via XRes so the boost lands on the real
                app process.

                At runtime this needs:
                  - dmemcg-booster (https://gitlab.steamos.cloud/holo/dmemcg-booster/)
                  - systemd
                  - a kernel with dmem cgroup "aggressive protect" support
                    (linux-cachyos, or linux + the dmemcg patch series)

                Add `spawn-at-startup "niri-focused-booster"` to your Niri
                config (~/.config/niri/config.kdl) to run it.
              '';
              homepage = "https://github.com/1Naim/niri-focused-booster";
              license = pkgs.lib.licenses.gpl3Plus;
              platforms = pkgs.lib.platforms.linux;
              mainProgram = "niri-focused-booster";
            };
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/niri-focused-booster";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            packages = [ pkgs.cargo pkgs.rustc pkgs.rust-analyzer pkgs.clippy ];
          };
        });
    };
}
