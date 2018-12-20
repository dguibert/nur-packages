self: super:
{
  flangPackages_5 = super.callPackage ./llvm/5 { };
  flangPackages_6 = super.callPackage ./llvm/6 { };
}
