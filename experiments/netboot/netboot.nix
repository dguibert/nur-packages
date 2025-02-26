# https://nixos.wiki/wiki/Netboot
## Usage example:
##
## # Build pixiecore runner
## nix build -f netboot.nix -o /tmp/run-pixiecore
##
## # Build dnsmasq + pxelinux runner
## nix build -f netboot.nix --arg legacy true -o /tmp/run-dnsmasq
##
## # Build for some ancient system with a serial console
## nix build -f netboot.nix --arg name '"ancient-netboot"' -o /tmp/run-netboot \
##   --arg configuration 'import ./ancient-config.nix' \
##   --arg legacy true --arg proxynets '["10.2.1.0"]' \
##   --arg serialconsole true --arg serialport 3 --arg serialspeed 115200
{
  name ? "netboot",
  arch ? "x86_64-linux",
  configuration ? _: {}, # --arg configuration 'import ./netboot-config.nix'
  legacy ? true, # variation with pxelinux and dnsmasq for older systems
  cmdline ? [],
  loglevel ? 4,
  pixiecoreport ? 64172,
  proxynets ? ["192.168.0.0"],
  serialconsole ? false,
  serialport ? 0,
  serialspeed ? 9600,
  nixpkgs ? import <nixpkgs> {},
  ...
}:
with nixpkgs;
with lib; let
  example-configuration = {
    pkgs,
    config,
    ...
  }:
    with pkgs; {
      config = {
        environment.systemPackages = [
          mtr
          bridge-utils
          vlan
          ethtool
          jwhois
          sipcalc
          netcat-openbsd
          tsocks
          psmisc
          pciutils
          usbutils
          lm_sensors
          dmidecode
          microcom
          unar
          mkpasswd
          ripgrep
          wget
          rsync
          sshfs-fuse
          iperf3
          mc
          mutt
          borgbackup
          rxvt-unicode-unwrapped.terminfo
        ];
        # users.users.nixos.openssh.authorizedKeys.keys = [ … ];
        # services.openssh = { ports = [2]; settings.PasswordAuthentication = false; };
        # virtualisation.lxc.enable = true;
      };
    };

  config = import <nixpkgs/nixos/lib/eval-config.nix> {
    # see <nixpkgs/nixos/release.nix>
    system = arch;
    modules = [
      <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
      version-module
      example-configuration
      configuration
    ];
  };

  version-module = {config, ...}: {
    #system.stateVersion = config.system.nixos.version; # be quiet
    system.nixos.tags = [name];
  };

  run-pixiecore = writeShellScript "${name}-run-pixiecore" ''
    exec ${pixiecore}/bin/pixiecore \
      boot ${kernel} ${initrd} \
      --cmdline "${cmd-line}" \
      --debug --dhcp-no-bind --log-timestamps \
      --port ${toString pixiecoreport} \
      --status-port ${toString pixiecoreport} "$@"
  '';

  run-dnsmasq = writeShellScript "${name}-run-dnsmasq" ''
    exec ${dnsmasq}/bin/dnsmasq \
      -d -k --no-daemon -C "${dnsmasq-conf}" "$@"
  '';

  tftp-root =
    linkFarm "${name}-tftp-root"
    (mapAttrsToList (name: path: {inherit name path;}) {
      "pxelinux.cfg/default" = pxelinux-cfg;
      "pxelinux.0" = "syslinux/pxelinux.0";
      "syslinux" = "${syslinux}/share/syslinux";
      "bzImage" = kernel;
      "initrd" = initrd;
    });

  dnsmasq-conf = writeText "${name}-dnsmasq-conf" ''
    pxe-prompt="Booting NixOS..",1
    local-service=net
    dhcp-boot=pxelinux.0
    ${flip concatMapStrings proxynets (net: ''
      dhcp-range=${net},proxy
    '')}
    dhcp-no-override
    dhcp-leasefile=/dev/null
    log-dhcp
    enable-tftp
    tftp-port-range=6900,6999
    tftp-root=${tftp-root}
  '';

  cmd-line =
    concatStringsSep " "
    (["init=${build.toplevel}/init" "loglevel=${toString loglevel}"]
      ++ optional serialconsole
      "console=ttyS${toString serialport},${toString serialspeed}"
      ++ cmdline);

  pxelinux-cfg = writeText "${name}-pxelinux.cfg" ''
    ${optionalString serialconsole
      "serial ${toString serialport} ${toString serialspeed}"}
    console 1
    prompt 1
    timeout 37
    default NixOS
    label NixOS
      kernel bzImage
      append initrd=initrd ${cmd-line}
  '';

  build = config.config.system.build;
  kernel = "${build.kernel}/${kernel-target}";
  kernel-target = config.pkgs.stdenv.hostPlatform.linux-kernel.target;
  initrd = "${build.netbootRamdisk}/initrd";
in
  if legacy
  then run-dnsmasq
  else run-pixiecore
