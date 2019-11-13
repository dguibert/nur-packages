self: super:
let
  overlay = (super.lib.composeOverlays [
   (import ./local-genji.nix)
   (import ./default.nix).nix-home-nfs-bguibertd
   (self: super: {
     slurm = super.slurm_17_02_11;

     pythonOverrides = super.lib.composeOverlays (python-self: python-super: {
       pyslurm = python-super.pyslurm_17_02_0.override { slurm=self.slurm; };
     }) (super.pythonOverrides or (_:_: {}));

   })
  ]);
in overlay self super
