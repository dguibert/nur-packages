{ inputs, perSystem, ...}: let
     nixpkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        overlays =  [
          inputs.nix.overlays.default
          (final: prev: import ../../overlays/default final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/extra-builtins final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/updated-from-flake.nix final (prev // { inherit inputs; }))
          (final: prev: import ../../overlays/emacs.nix final (prev // { inherit inputs; }))
          (import ../../overlays/store-spartan.nix)
          inputs.emacs-overlay.overlay
          (final: prev: {
            libuv = prev.libuv.overrideAttrs (o: {
              doCheck = false;
              doInstallCheck = false;
            });

            patchelf = prev.patchelf.overrideAttrs (o: {
              doCheck = false; # ./replace-add-needed.sh: line 14: ldd: not found
              doInstallCheck = false;
            });

            glibcLocales = prev.glibcLocales.overrideAttrs (o: {
              LOCALEDEF_FLAGS = o.LOCALEDEF_FLAGS ++ [
                "-c" # https://sourceware.org/bugzilla/show_bug.cgi?id=28845 quiet to generate C.UTF-8
              ];
            });
          })
        ];
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
        config.replaceStdenv = import ../../stdenv.nix;
    };
in
{
  perSystem = {config, self', inputs', pkgs, system, ...}: {
    _module.args.pkgs = nixpkgsFor system;

    legacyPackages = nixpkgsFor system;
  };
}
