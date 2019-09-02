
{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri = "github:dguibert/nixpkgs/pu";
  };

  outputs = { self, nixpkgs }: rec {

    packages.hello = nixpkgs.provides.packages.hello;

  };
}
