self: super:
let
  overlay = (super.lib.composeOverlays [
   (import ./local-genji.nix)
   (import ./default.nix).nix-home-nfs-bguibertd
   (self: super: {
     slurm = super.slurm_17_02_11;

     python = super.python.override {
       packageOverrides = python-self: python-super: {
         pyslurm = python-super.pyslurm.overrideAttrs (oldAttrs: rec {
           name = "${oldAttrs.pname}-${version}";
           version = "17.02.0";

           patches = [];

           preConfigure = ''
             sed -i -e 's@__max_slurm_hex_version__ = "0x11020a"@__max_slurm_hex_version__ = "0x11020b"@' setup.py
           '';

           src = super.fetchFromGitHub {
             repo = "pyslurm";
             owner = "PySlurm";
             # The release tags use - instead of .
             rev = "refs/heads/17.02.0";
             sha256 = "sha256:1b5xaq0w4rkax8y7rnw35fapxwn739i21dgb9609hg01z9b6n1ka";
           };

         });
       };
     };
   })
  ]);
in overlay self super
