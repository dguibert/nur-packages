{ stdenv, fetchFromGitHub, pkgconfig, libtool, curl
, python, munge, perl, pam, openssl, zlib
, ncurses, libmysqlclient, gtk2, lua, hwloc, numactl
, readline, freeipmi, libssh2, xorg, lz4
# enable internal X11 support via libssh2
, enableX11 ? true
, pmix

, lib
, slurm
}@args:

let
  args_ = builtins.removeAttrs args ["lib" "slurm" ];
  slurm' = slurm.override args_;
in rec {
  slurm_17_02_11 = slurm'.overrideAttrs (oldAttrs: {
    version = "17.02.11";

    # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
    # because the latter does not keep older releases.
    src = fetchFromGitHub {
      owner = "SchedMD";
      repo = "slurm";
      rev = "refs/heads/slurm-17.02";
      sha256 = "sha256:1l2ph5p093kn8prjrwpd0fv3n8ha02xvbl6cczfkq051hz51wyxm";
    };

    prePatch= null;
    configureFlags = with stdenv.lib;
      [ "--with-freeipmi=${freeipmi}"
        #"--with-hwloc=${hwloc.dev}"
        "--with-lz4=${lz4.dev}"
        "--with-munge=${munge}"
        "--with-ssl=${openssl.dev}"
        "--with-zlib=${zlib}"
        "--sysconfdir=/etc/slurm"
        "--with-pmix"
      ] ++ (optional (gtk2 == null)  "--disable-gtktest")
        ++ (optional enableX11 "--with-libssh2=${libssh2.dev}");
  });

  slurm_17_11_9_1 = slurm'.overrideAttrs (oldAttrs: rec {
    version = "17.11.9.1";

    # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
    # because the latter does not keep older releases.
    src = fetchFromGitHub {
      owner = "SchedMD";
      repo = "slurm";
      # The release tags use - instead of .
      rev = "slurm-${builtins.replaceStrings ["."] ["-"] version}";
      sha256 = "04fcrk08f6akbjbkaf60j900bl7vh4xfj54bwp1308r0znkpdpv6";
    };

  });

  slurm_18_08_5 = slurm'.overrideAttrs (oldAttrs: rec {
    version = "18.08.5.2";

    # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
    # because the latter does not keep older releases.
    src = fetchFromGitHub {
      owner = "SchedMD";
      repo = "slurm";
      # The release tags use - instead of .
      rev = "slurm-${builtins.replaceStrings ["."] ["-"] version}";
      sha256 = "sha256-k1gAhf8jOgT5JWLgVxA9VEK4v2cURMWQqMA1jQpuN3Q=";
    };

  });


  slurm_19_05_3_2 = lib.upgradeOverride slurm' (oldAttrs: {
    version = "19.05.3.2";
  });

  slurm = slurm_19_05_3_2;
}
