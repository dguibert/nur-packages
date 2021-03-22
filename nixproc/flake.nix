{
  description = "A flake for building my envs";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  #inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nix-ccache.url       = "github:dguibert/nix-ccache/pu";
  #inputs.nix-ccache.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-utils.url      = "github:numtide/flake-utils";

  #inputs.nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
  inputs.nur_dguibert_envs.url= "git+file:///home/dguibert/nur-packages?dir=envs";
  inputs.nur_dguibert_envs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert_envs.inputs.nix.follows = "nix";
  inputs.nur_dguibert_envs.inputs.nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-processmgmt.url = "github:svanderburg/nix-processmgmt";
  inputs.nix-processmgmt.flake = false;
  inputs.nix-processmgmt-services.url = "github:svanderburg/nix-processmgmt-services";
  inputs.nix-processmgmt-services.flake = false;

  outputs = { self, nixpkgs
            , nix
            #, nix-ccache
            , nur_dguibert_envs
            , flake-utils
            , nix-processmgmt
            , nix-processmgmt-services
            , ...
            }@flakes: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          nix.overlay
          nur_dguibert_envs.overlay
          nur_dguibert_envs.overlays.extra-builtins
          self.overlay
        ];
        config.allowUnfree = true;
    };

  in (flake-utils.lib.eachDefaultSystem (system:
       let pkgs = nixpkgsFor system; in
       rec {

    legacyPackages = pkgs;

    devShell = pkgs.mkEnv {
      name = "nixproc";
      buildInputs = with pkgs; [ pkgs.nix jq
        nixproc.common
        nixproc.systemd
      ];
    };
  })) // rec {
    overlay = final: prev: let
      nixproc = import "${nix-processmgmt}/tools" {
        pkgs = prev;
        system = prev.pkgs.localSystem.system;
      };
    in {
      inherit nixproc;
    };
  };
}

