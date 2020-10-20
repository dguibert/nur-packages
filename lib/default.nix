{ pkgs ? null, lib ? pkgs.lib }:

let
  fix = f: let fixpoint = f fixpoint; in fixpoint;
  withOverride = overrides: f: self: f self //
      (if builtins.isFunction overrides then overrides self else overrides);

  libStr = lib.strings;
  libAttr = lib.attrsets;
in with lib; lib // rec {

  # http://r6.ca/blog/20140422T142911Z.html
  virtual = f: fix f // { _override = overrides: virtual (withOverride overrides f); };  #
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

  toExtendedINI = {
    # apply transformations (e.g. escapes) to section names
    mkSectionName ? (name: libStr.escape [ "[" "]" ] name),
    # format a setting line from key and value
    mkKeyValue    ? generators.mkKeyValueDefault {} "=",
    # allow lists as values for duplicate keys
    listsAsDuplicateKeys ? false
  }: attrsOfAttrs:
    let
      # map function to string for each key val
      mapAttrsToStringsSep = sep: mapFn: attrs:
        libStr.concatStringsSep sep
          (libAttr.mapAttrsToList mapFn attrs);

       mkLine = {
         intentChar ? "",
         openChar ? "[",
         closeChar ? "]",
       }: name: values:
          if isAttrs values then
            ''
              ${intentChar}${openChar}${mkSectionName name}${closeChar}
            ''
            + (mapAttrsToStringsSep "" (name: val: (mkLine {
              intentChar = "${intentChar}  ";
              openChar = "[${openChar}";
              closeChar = "${closeChar}]";
            } name) val) values)
          else
            intentChar + (generators.toKeyValue { inherit mkKeyValue listsAsDuplicateKeys; } { "${name}"=values; })
          ;
    in
      # map input to ini sections
      mapAttrsToStringsSep "\n" (mkLine {}) attrsOfAttrs;

}

