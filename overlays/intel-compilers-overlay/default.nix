final: prev:
let
    # Intel compiler
    intelPackages =
      { version
      , comp_url, comp_sha256 ? ""
      , mpi_url, mpi_sha256 ? "", mpi_version ? version
      , redist_url, redist_sha256 ? ""
      , gcc ? pkgs.gcc7
      , pkgs ? final
      }:
      let
      wrapCCWith = { cc
        , # This should be the only bintools runtime dep with this sort of logic. The
          # Others should instead delegate to the next stage's choice with
          # `targetPackages.stdenv.cc.bintools`. This one is different just to
          # provide the default choice, avoiding infinite recursion.
          bintools ? if pkgs.targetPlatform.isDarwin then pkgs.darwin.binutils else pkgs.binutils
        , libc ? bintools.libc or pkgs.stdenv.cc.libc
        , ...
        } @ extraArgs:
          pkgs.callPackage ./build-support/cc-wrapper (let self = {
        nativeTools = pkgs.targetPlatform == pkgs.hostPlatform && pkgs.stdenv.cc.nativeTools or false;
        nativeLibc = pkgs.targetPlatform == pkgs.hostPlatform && pkgs.stdenv.cc.nativeLibc or false;
        nativePrefix = pkgs.stdenv.cc.nativePrefix or "";
        noLibc = !self.nativeLibc && (self.libc == null);

        isGNU = cc.isGNU or false;
        isClang = cc.isClang or false;
        isIntel = true;

        inherit cc bintools libc;
      } // extraArgs; in self);

      self = with self; (if (comp_url != null) then {
        redist = pkgs.callPackage ./redist.nix { inherit version; url=redist_url; sha256=redist_sha256; };
        unwrapped = pkgs.callPackage ./compiler.nix { inherit version gcc; url=comp_url; sha256=comp_sha256; };

        mkl = pkgs.callPackage ./mkl.nix { inherit version gcc redist mpi; url=comp_url; sha256=comp_sha256; };

        compilers = wrapCCWith {
          cc = unwrapped;
          extraPackages = [ redist pkgs.which pkgs.binutils unwrapped ];
        };

        /* Return a modified stdenv that uses Intel compilers */
        stdenv = let stdenv_=pkgs.overrideCC pkgs.stdenv compilers; in stdenv_ // {
          mkDerivation = args: stdenv_.mkDerivation (args // {
            CC="icc";
            CXX="icpc";
            FC="ifort";
            F77="ifort";
            F90="ifort";
            postFixup = "${args.postFixup or ""}" + ''
            set -x
            storeId=$(echo "${compilers}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
            find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
            storeId=$(echo "${unwrapped}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
            find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
            set +x
            '';
          });
        };
      } else {}) // {
        mpi = if (mpi_url!=null) then pkgs.callPackage ./mpi.nix { version = mpi_version; url=mpi_url; sha256=mpi_sha256; } else null;
      };
    in self;

in {
    # https://registrationcenter.intel.com/en/products/list/
    # https://software.intel.com/en-us/articles/intel-compiler-and-composer-update-version-numbers-to-compiler-version-number-mapping

    intelPackages_2017_5_239 = intelPackages {
      version = "2017.5.239";
      comp_url = null;
      redist_url = null;
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12209/l_mpi_2017.4.239.tgz";
      mpi_sha256 = "02si091w8gvq7nsclngiz1ckqjy9hcf4g2apnisvrs6whk94h42s";
    };
    intelPackages_2017_7_259 = intelPackages {
      version = "2017.7.259";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12856/parallel_studio_xe_2017_update7.tgz";
      comp_sha256 = "0q331y0vlr4lrl8bwczhh8m4arqljw7sjf4r2i4gx921k2lklg0k";
      redist_url = "https://software.intel.com/sites/default/files/managed/e1/e4/l_comp_lib_2017.7.259_comp.for_redist.tgz";
      redist_sha256 = "06wq03l257ywklywrs6qnx7zqmx0m8f3xfqa5l8a10w9axbh8s39";
      mpi_version = "2017.5.239";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12209/l_mpi_2017.4.239.tgz";
      mpi_sha256 = "02si091w8gvq7nsclngiz1ckqjy9hcf4g2apnisvrs6whk94h42s";
    };
    intelPackages_2017 = final.intelPackages_2017_7_259;

    #intelPackages_2018_0_128 = intelPackages "2018.0.128";
    # "2018.0.128"http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12062/parallel_studio_xe_2018_professional_edition.tgz
    #602c9ceb6934a3eadce5a834b066bf326ab12b9d7b448ae405c7bca09be485f0  software.intel.com_sites_default_files_managed_96_59_l_comp_lib_2018.0.128_comp.for_redist.tgz
    #  mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12120/l_mpi_2018.0.128.tgz";
    #  mpi_sha256 = "1q6qbnfzqkxc378mj803a2g6238m0ankrf34i482z70lnhz4n4d5";
    #intelPackages_2018_1_163 = intelPackages "2018.1.163";
    # "2018.1.163"http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12375/parallel_studio_xe_2018_update1_professional_edition.tgz
    #fe36b4de91666fdd6e8236f121105792f5f39b41e2bedf378f298e22c7e1fb8d  software.intel.com_sites_default_files_managed_aa_dc_l_comp_lib_2018.1.163_comp.for_redist.tgz
    #  mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12414/l_mpi_2018.1.163.tgz";
    #  mpi_sha256 = "1q6qbnfzqkxc378mj803a2g6238m0ankrf34i482z70lnhz4n4d4";

    intelPackages_2018_2_199 = intelPackages {
      version = "2018.2.199";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12718/parallel_studio_xe_2018_update2_professional_edition.tgz";
      comp_sha256 = "00lf287g8nffzb5pidzwg3y2k9bdzfk19spssi0p8s1czclpnmzw";
      redist_url = "l_comp_lib_2018.2.199_comp.for_redist.tgz";
      redist_sha256 = "6d9e5383f81296edf702351826f1bc618cd8ca0cc7a692d272a922516e997604";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12748/l_mpi_2018.2.199.tgz";
      mpi_sha256 = "1q6qbnfzqkxc378mj803a2g6238m0ankrf34i482z70lnhz4n4d3";
    };

    intelPackages_2018_3_222 = intelPackages {
      version = "2018.3.222";
      comp_url ="http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12999/parallel_studio_xe_2018_update3_professional_edition.tgz";
      comp_sha256 = "";
      redist_url = "l_comp_lib_2018.3.222_comp.for_redist.tgz";
      redist_sha256 = "b9eaf0ed8b8dac01b4d169165624aafc86776c4ae5ed73f564b04090a94a1be6";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13112/l_mpi_2018.3.222.tgz";
      mpi_sha256 = "16c94p7w12hyd9x5v28hhq2dg101sx9lsvhlkzl99isg6i5x28ah";
    };

    intelPackages_2018_5_274 = intelPackages {
      version = "2018.5.274";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13718/parallel_studio_xe_2018_update4_professional_edition.tgz";
      comp_sha256 = "08ykfwmka5lgma21a3by8rl10x91m8s7myln41h0i4c4v8h47asl";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13741/l_mpi_2018.4.274.tgz";
      mpi_sha256 = "1q6qbnfzqkxc378mj803a2g6238m0ankrf34i482z70lnhz4n4d1";
      redist_url="https://software.intel.com/sites/default/files/managed/7a/1e/l_comp_lib_2018.5.274_comp.for_redist.tgz";
      redist_sha256="0i1h2dc7w3bhk5m7hkqvz1ffhrhgkx294b3r73hzs32hnjgbvqrg";
      gcc = prev.gcc7;
    };
    intelPackages_2018 = final.intelPackages_2018_5_274;

    #https://software.intel.com/en-us/articles/redistributable-libraries-for-intel-c-and-fortran-2019-compilers-for-linux
    intelPackages_2019_0_117 = intelPackages {
      version = "2019.0.117";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13578/parallel_studio_xe_2019_professional_edition.tgz";
      comp_sha256 = "1qhicj98x60csr4a2hjb3krvw74iz3i3dclcsdc4yp1y6m773fcl";
      redist_url = "https://software.intel.com/sites/default/files/managed/05/23/l_comp_lib_2019.0.117_comp.for_redist.tgz";
      redist_sha256 = "6218ea4176373cd21c41465a1f406d133c28a2c1301590aa1661243dd68c28fc";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13584/l_mpi_2019.0.117.tgz";
      mpi_sha256 = "025ww7qa03mbbs35fb63g4x8qm67i49bflm9g8ripxhskks07d6z";
      gcc = prev.gcc7;
    };

    intelPackages_2019_1_144 = intelPackages {
      version = "2019.1.144";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/14854/parallel_studio_xe_2019_update1_professional_edition.tgz";
      comp_sha256 = "1rhcfbig0qvkh622cvf8xjk758i3jh2vbr5ajdgms7jnwq99mii8";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/14879/l_mpi_2019.1.144.tgz";
      mpi_sha256 = "1kf3av1bzaa98p5h6wagc1ajjhvahlspbca26wqh6rdqnrfnmj6s";
      redist_url="https://software.intel.com/sites/default/files/managed/79/cd/l_comp_lib_2019.1.144_comp.for_redist.tgz";
      redist_sha256="05kd2lc2iyq3rgnbcalri86nf615n0c1ii21152yrfyxyhk60dxm";
      gcc = prev.gcc7;
    };

    intelPackages_2019_2_187 = intelPackages {
      version = "2019.2.187";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15089/parallel_studio_xe_2019_update2_professional_edition.tgz";
      comp_sha256 = "1sk4dsq3n8p155m394nsikv1vqw1l3k687vz3753bl8j8vbjkdnd";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15040/l_mpi_2019.2.187.tgz";
      mpi_sha256 = "084bfw29swvpjm1lynl1pfj3y3v2j563k7lnvvvy7yay7f9hacva";
      redist_url="https://software.intel.com/sites/default/files/managed/95/e7/l_comp_lib_2019.2.187_comp.for_redist.tgz";
      redist_sha256="0sj0plax2bnid1qm1jqvijiflzfvs37vkfmg93mb7202g9fp7q77";
      gcc = prev.gcc7;
    };

    intelPackages_2019_3_199 = intelPackages {
      version = "2019.3.199";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15269/parallel_studio_xe_2019_update3_professional_edition.tgz";
      comp_sha256 = "1y97gam3798nqpr89x5x2f5xfrywpizxj337ykng3gfh0s8qga4j";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15260/l_mpi_2019.3.199.tgz";
      mpi_sha256 = "143951k7c3pj4jqi627j5whwiky5a57v3vjhf9wxwr1zhrn3812k";
      redist_url="https://software.intel.com/sites/default/files/managed/7f/23/l_comp_lib_2019.3.199_comp.for_redist.tgz";
      redist_sha256="06c3w65ir481bqnwbmd9nqigrhcb3qyxbmx2ympckygjiparwh05";
      gcc = prev.gcc7;
    };

    intelPackages_2019_4_227 = intelPackages {
      version = "2019.4.227";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15466/parallel_studio_xe_2019_update4_composer_edition.tgz";
      comp_sha256 = "0n7wjq789v7z0rqmymb4ly54yiixshjlyrz80x0pjpz2zn6zlmpw";
      mpi_version="2019.4.243";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15553/l_mpi_2019.4.243.tgz";
      mpi_sha256 = "233a8660b92ecffd89fedd09f408da6ee140f97338c293146c9c080a154c5fcd";
      redist_url="http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15466/l_comp_lib_2019.4.227_comp.for_redist.tgz";
      redist_sha256="0f3lz0carshqi4nfpmdmi4kmndgml6prh9frf820sdg31w7khcbl";
      gcc = prev.gcc7;
    };

    intelPackages_2019_5_281 = intelPackages {
      version = "2019.5.281";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15810/parallel_studio_xe_2019_update5_professional_edition.tgz";
      comp_sha256 = "0lj46mnxhhrpx479ik1x05w5lniqkxsj0bk3z1hr6lql08rkiihf";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15838/l_mpi_2019.5.281.tgz";
      mpi_sha256 = "1x0id0q8jyg177x6jc0lkw0mvs2jj5l8nkdwwlhv498k3w2xlncw";
      redist_url="http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15810/l_comp_lib_2019.5.281_comp.for_redist.tgz";
      redist_sha256="1jxyw8qvrvz66xvf7ng6maw5q13kbzhdynr2yrdqw5iqhiw8wsl3";
      gcc = prev.gcc7;
    };

    intelPackages_2019 = final.intelPackages_2019_4_227;

    stdenvIntel = final.intelPackages_2019.stdenv;

    intelPackages_2020_0_166 = intelPackages {
      version = "2020.0.166";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16226/parallel_studio_xe_2020_professional_edition.tgz";
      comp_sha256 = "1b0mdxn3108454rxqca7z4dxkvqkrzf2mcc7rgchx9cds8cav378";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15838/l_mpi_2019.6.166.tgz";
      mpi_sha256="0vnd32pws5kxyxkrbbbqbajx4mcfj51ld2wvbsg3mj8p26gyd6qi";
      redist_url="https://software.intel.com/sites/default/files/managed/8a/61/l_comp_lib_2020.0.166_comp.for_redist.tgz";
      redist_sha256="0l7k1hs9f0fwwf8r8syva7ysq7744r85v5sld708bkp0kwwdswah";
      gcc = prev.gcc7;
    };

    intelPackages_2020_1_217 = intelPackages {
      version = "2020.1.217";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16530/parallel_studio_xe_2020_update1_composer_edition.tgz";
      comp_sha256 = "07mhd520zw8v9hv3gn5yd9rrggkjv1aa7ch8skgkma5qhzdfgir6";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16546/l_mpi_2019.7.217.tgz";
      mpi_sha256="01wwmiqff5lad7cdi8i57bs3kiphpjfv52sxll1w0jpq4c03nf4h";
      redist_url="http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16526/l_comp_lib_2020.1.217_comp.for_redist.tgz";
      redist_sha256="13jdyakn09d923a8562jh0cjbnk3wxj8h8ph7926pz7kfcrk93l8";
      gcc = prev.gcc7;
    };

    intelPackages_2020_2_254 = intelPackages {
      version = "2020.2.254";
      comp_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16756/parallel_studio_xe_2020_update2_professional_edition.tgz";
      comp_sha256 = "96f9bca551a43e09d9648e8cba357739a759423adb671d1aa5973b7a930370c5";
      mpi_url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16814/l_mpi_2019.8.254.tgz";
      mpi_sha256="fa163b4b79bd1b7509980c3e7ad81b354fc281a92f9cf2469bf4d323899567c0";
      redist_url="http://registrationcenter-download.intel.com/akdlm/irc_nas/16744/l_comp_lib_2020.2.254_comp.for_redist.tgz";
      redist_sha256="1cnsnzkd5izqjjcgh3nsnsw10ccdqdybh1v0xbjyd58vzg7hzlsp";
      gcc = prev.gcc7;
    };

    intelPackages_2020_4_304 = intelPackages {
      version = "2020.4.304";
      comp_url = "https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17114/parallel_studio_xe_2020_update4_professional_edition.tgz";
      comp_sha256 = "1rn9kk5bjj0jfv853b09dxrx7kzvv8dlyzw3hl9ijx9mqr09lrzr";
      mpi_url = "https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17263/l_mpi_2019.9.304.tgz";
      mpi_sha256="1rxj1gcy1yfhsz5gngd8nl8lpdb7savmx322wr2ncc2lvv15v2k1";
      redist_url="https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17113/l_comp_lib_2020.4.304_comp.for_redist.tgz";
      redist_sha256="1qy0b0ngv0annmrplmv0kinffpqd9vhi3bnyvlf6h5z5p4g8j6n6";
      gcc = prev.gcc7;
    };

    # https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17818/l_mpi_2019.11.319.tgz
    # https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17836/l_mpi_2019.12.320.tgz

    intelPackages_2020 = final.intelPackages_2020_0_166;

    helloIntel = prev.hello.override { stdenv = final.stdenvIntel; };
    miniapp-ping-pongIntel = prev.miniapp-ping-pong.override { stdenv = final.stdenvIntel;
      caliper = prev.caliper.override { stdenv = final.stdenvIntel;
        mpi = final.intelPackages_2019.mpi;
      };
      mpi = final.intelPackages_2019.mpi;
    };

    hemocellIntel = prev.hemocell.override {
      stdenv = final.stdenvIntel;
      hdf5 = (prev.hdf5-mpi.override {
        stdenv = final.stdenvIntel;
        mpi = final.intelPackages_2019.mpi;
      }).overrideAttrs (oldAttrs: {
        configureFlags = oldAttrs.configureFlags ++ [
          "CC=${final.intelPackages_2019.mpi}/bin/mpiicc"
        ];
      });
    };
}
