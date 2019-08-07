{ nixpkgs, declInput }: let pkgs = import nixpkgs {}; in {
  jobsets = pkgs.runCommand "spec.json" {} ''
    cat <<EOF
    ${builtins.toXML declInput}
    EOF
    cat > $out <<EOF
    {
        "master": {
            "enabled": 1,
            "hidden": false,
            "description": "master",
            "nixexprinput": "src",
            "nixexprpath": "release.nix",
            "checkinterval": 300,
            "schedulingshares": 100,
            "enableemail": false,
            "emailoverride": "",
            "keepnr": 3,
            "inputs": {
                "src": { "type": "git", "value": "git://github.com/dguibert/nur-packages.git dg/hydra", "emailresponsible": false },
                "nixpkgs": { "type": "git", "value": "git://github.com/dguibert/nixpkgs.git pu", "emailresponsible": false }
            }
        }
    }
    EOF
  '';
}
