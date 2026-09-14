{ inputs, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem = { pkgs, ... }:
    let
      dmemcg-booster = pkgs.rustPlatform.buildRustPackage {
        pname = "dmemcg-booster";
        version = "0.1.3";

        src = pkgs.fetchFromGitLab {
          domain = "gitlab.steamos.cloud";
          owner = "holo";
          repo = "dmemcg-booster";
          tag = "0.1.3";
          hash = "sha256-JDT+JKxgaETinIHiP0Pqb7fPNrvcI6AQu90nmoA/YuI=";
        };

        postPatch = ''
          substituteInPlace *.service \
            --replace-fail /usr/bin/dmemcg-booster $out/bin/dmemcg-booster
        '';

        cargoHash =
          "sha256-NHK4734Jvi4RJieGn0RjYU0PzQFqaE4exHG77dmukig=";

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
      };

      niri-focused-booster = pkgs.rustPlatform.buildRustPackage {
        pname = "niri-focused-booster";
        version = "0.3.0";

        src = pkgs.fetchFromGitHub {
          owner = "1Naim";
          repo = "niri-focused-booster";
          rev = "753d981bbfaed0727214109ed8e3ca82240af5a3";
          hash = "sha256-gOb+VugBrXeaHreq5fIoXgczYKtSkMws3v2glW4L9Gg=";
        };

        cargoHash =
          "sha256-YJoudoTRl0eStUlepHgUKaD0pEcRaAvlmqJQcTsu6ao=";

        nativeBuildInputs = [
          pkgs.pkg-config
        ];

        buildInputs = [
          pkgs.libxcb
        ];

        meta = {
          description =
            "Boosts dmem cgroup memory protection for the focused window on Niri";
          homepage = "https://github.com/1Naim/niri-focused-booster";
          license = pkgs.lib.licenses.gpl3Plus;
          platforms = pkgs.lib.platforms.linux;
          mainProgram = "niri-focused-booster";
        };
      };
    in
    {
      packages = {
        inherit dmemcg-booster niri-focused-booster;
        default = niri-focused-booster;
      };

      apps.default = {
        type = "app";
        program = "${niri-focused-booster}/bin/niri-focused-booster";

        meta = {
          description =
            "Boosts dmem cgroup memory protection for the focused window on Niri";
          mainProgram = "niri-focused-booster";
        };
      };

      devShells.default = pkgs.mkShell {
        inputsFrom = [
          niri-focused-booster
        ];

        packages = with pkgs; [
          cargo
          rustc
          rust-analyzer
          clippy
        ];
      };
    };

  flake.nixosModules.default =
    { config, lib, pkgs, self, ... }:
    {
      options.services.dmemcg-booster.enable =
        lib.mkEnableOption "dmemcg-booster system service";

      config = lib.mkIf config.services.dmemcg-booster.enable {
        systemd.packages = [
          self.packages.${pkgs.system}.dmemcg-booster
        ];

        systemd.services.dmemcg-booster-system = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
}
