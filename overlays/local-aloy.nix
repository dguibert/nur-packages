self: super:
let
  overlay = (super.lib.composeOverlays [
   (import ./local-genji.nix)
   (import ./default.nix).nix-home-nfs-bguibertd
   (self: super: {
     slurm = super.slurm_17_02_11;

     pythonOverrides = super.lib.composeOverlays [
       (super.pythonOverrides or (_:_: {}))
       (python-self: python-super: {
         pyslurm = python-super.pyslurm_17_11_12.override { slurm=self.slurm; };
       })
     ];


   })
  ]);
in overlay self super
