{ lib
, inputs
, outputs
, system
, ...
}:

with lib;

mapAttrs'
  (name: type:
  let
    name' = removeSuffix ".nix" name;
  in
  {
    name = name';
    value =
      let
        file = ./. + "/${name}";
      in
      builtins.trace "evaluating devShell for ${name'} (${system})"
        import
        file
        {
          pkgs = inputs.self.legacyPackages.${system};
          inherit inputs outputs;
        };
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (hasSuffix "@.nix" name) && ! (name == "default.nix") && ! (name == "overlays.nix")) ||
    (type == "symlink" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix") && ! (name == "common.nix"))
    )
    (builtins.readDir ./.))
