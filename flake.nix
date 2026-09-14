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

          dmemcg-booster = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
            pname = "dmemcg-booster";
            version = "0.1.3";

            src = pkgs.fetchFromGitLab {
              domain = "gitlab.steamos.cloud";
              owner = "holo";
              repo = "dmemcg-booster";
              tag = finalAttrs.version;
              hash = "sha256-JDT+JKxgaETinIHiP0Pqb7fPNrvcI6AQu90nmoA/YuI=";
            };

            postPatch = ''
              substituteInPlace *.service \
                --replace-fail /usr/bin/dmemcg-booster $out/bin/dmemcg-booster
            '';

            cargoHash = "sha256-NHK4734Jvi4RJieGn0RjYU0PzQFqaE4exHG77dmukig=";

            nativeBuildInputs = [
              pkgs.pkg-config
            ];

            buildInputs = [
              pkgs.dbus
            ];

            postInstall = ''
              install -Dm644 dmemcg-booster-system.service \
                "$out/lib/systemd/system/dmemcg-booster-system.service"

              install -Dm644 dmemcg-booster-user.service \
                "$out/lib/systemd/user/dmemcg-booster-user.service"
            '';

            meta = {
              description = "Dynamic memory cgroup booster";
              homepage = "https://gitlab.steamos.cloud/holo/dmemcg-booster";
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.linux;
              mainProgram = "dmemcg-booster";
            };
          });

           niri-focused-booster = pkgs.rustPlatform.buildRustPackage {
            pname = "niri-focused-booster";
            version = "0.3.0";

            src = pkgs.fetchFromGitHub {
              owner = "1Naim";
              repo = "niri-focused-booster";
              rev = "753d981bbfaed0727214109ed8e3ca82240af5a3";
              hash = "sha256-gOb+VugBrXeaHreq5fIoXgczYKtSkMws3v2glW4L9Gg=";
            };

            cargoHash = "sha256-YJoudoTRl0eStUlepHgUKaD0pEcRaAvlmqJQcTsu6ao=";

            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [ pkgs.libxcb ];
          };
        in
        {
          inherit dmemcg-booster niri-focused-booster;

          default = niri-focused-booster;
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
            inputsFrom = [
              self.packages.${system}.default
            ];

            packages = [
              pkgs.cargo
              pkgs.rustc
              pkgs.rust-analyzer
              pkgs.clippy
            ];
          };
        });
    };
}
