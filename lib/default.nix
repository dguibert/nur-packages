{ pkgs }:

with pkgs.lib; pkgs.lib // rec {
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
  compose = list: fix (builtins.foldl' (flip extends) (self: pkgs) list);

  composeOverlays = foldl' composeExtensions (self: super: {});

  makeExtensible' = pkgs: list: builtins.foldl' /*op nul list*/
    (o: f: o.extend f) (makeExtensible (self: pkgs)) list;

  upgradeOverride = package: overrides:
  let
    upgraded = package.overrideAttrs overrides;
  in (upgradeReplace package upgraded);

  upgradeReplace = package: upgraded:
  let
    upgradedVersion = (builtins.parseDrvName upgraded.name).version;
    originalVersion =(builtins.parseDrvName package.name).version;

    isDowngrade = (builtins.compareVersions upgradedVersion originalVersion) == -1;

    warn = builtins.trace
      "Warning: ${package.name} downgraded by overlay with ${upgraded.name}.";
    pass = x: x;
  in (if isDowngrade then warn else pass) upgraded;
}

