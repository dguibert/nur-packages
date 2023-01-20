{ lib, inputs, outputs, system, pkgs, ... }@args:

with lib;

mapAttrs'
  (name: type: {
    name = removeSuffix ".nix" name;
    value = let file = ./. + "/${name}"; in
            lib.recurseIntoAttrs (import file args)
      ;
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix"))
    )
    (builtins.readDir ./.))
