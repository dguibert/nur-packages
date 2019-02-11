self: super:
{
  boehmgc = super.boehmgc.overrideAttrs (attrs: {
    doCheck = false;
  });
  jemalloc = super.jemalloc.overrideAttrs (attrs: {
    doCheck = false;
  });
  jemalloc450 = super.jemalloc450.overrideAttrs (attrs: {
    doCheck = false;
  });
  libjpeg_turbo = super.libjpeg_turbo.overrideAttrs (attrs: {
    doCheck = false;
  });
  libuv = super.libuv.overrideAttrs (attrs: {
    doCheck = false;
  });
}
