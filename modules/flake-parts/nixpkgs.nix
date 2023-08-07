{ inputs, perSystem, ...}: let
     nixpkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        overlays =  [
          (final: prev: import ../../overlays/default final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/extra-builtins final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/updated-from-flake.nix final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/emacs.nix final (prev // { inherit inputs; }))
          inputs.nix.overlays.default
          inputs.emacs-overlay.overlay
        ];
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
    };
in
{
  perSystem = {config, self', inputs', pkgs, system, ...}: {
    _module.args.pkgs = nixpkgsFor system;

    legacyPackages = nixpkgsFor system;
  };
}
