{config, lib, ...}: let

  mapShells = p: lib.mapAttrs' (fn: _:
    lib.nameValuePair
    (lib.removeSuffix ".nix" fn)
      (p + "/${fn}"))
      (builtins.readDir p);

  filterFn = name: type:
    (name != "all-modules") ||
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && lib.hasSuffix ".nix" name && ! (lib.hasSuffix "@.nix" name) && ! (name == "default.nix") && ! (name == "overlays.nix")) ||
    (type == "symlink" && lib.hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix") && ! (name == "common.nix"));
  
  shells = lib.attrValues (
    lib.filterAttrs
      filterFn
      (mapShells ./.)
  );
in {
  imports = shells;
}
