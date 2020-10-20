# to run these tests:
# nix-instantiate --eval --strict nixpkgs/lib/tests/misc.nix
# if the resulting list is empty, all tests passed
pkgs:

let
in with pkgs.lib;
runTests {
  testToExtendedINIEmptySection = {
    expr = toExtendedINI {} { foo = {}; bar = {}; };
    expected = ''
      [bar]

      [foo]
    '';
  };
  testToExtendedINIEmptySubSection = {
    expr = toExtendedINI {} { foo = {}; bar = { a=1; baz = {}; }; };
    expected = ''
      [bar]
        a=1
        [[baz]]

      [foo]
    '';
    };
  testToExtendedINIBasic = {
    expr = toExtendedINI {} { foo = { a=1; }; };
    expected = ''
      [foo]
        a=1
    '';
    };
}
