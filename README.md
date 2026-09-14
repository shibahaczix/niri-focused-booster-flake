dmemcg-booster usage:

```nix
{
  imports = [
    inputs.niri-focused-booster.nixosModules.default
  ];

  services.dmemcg-booster.enable = true;
  

}
```
for whatever niri wrapper you use:
```nix
  settings.spawn-at-startup = [
    (lib.getExe inputs.niri-focused-booster.packages.${stdenv.hostPlatform.system}.default)
  ];
```
