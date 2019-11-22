# vim: set ts=2 :
{ pkgs }:
{
  permittedInsecurePackages = [
    "oraclejdk-10.0.2"
    "webkitgtk-2.4.11"
  ];
  #psxe.licenseFile = <secrets/pxse2019.1019.lic>;
  psxe.licenseFile = <secrets/COM_L___CTNG-THFWW764-2020.lic>;

  # Package ‘oraclejre-8u191’ in /home/dguibert/code/nixpkgs/pkgs/development/compilers/oraclejdk/jdk-linux-base.nix:71 has an unfree license (‘unfree’), refusing to evaluate.
  oraclejdk.accept_license = true;
  allowUnfree = true;

  allowBroken = true; # xpra-2.3.4
  pulseaudio = true;
  # trace: warning: 'nixpkgs.virtualbox.enableExtensionPack' has no effect, please use 'virtualisation.virtualbox.host.enableExtensionPack'
  virtualbox.host.enableExtensionPack = true;

  firefox.enableBrowserpass = true;
}
