{ haskellLib, nixpkgs, fetchFromGitHub, useReflexOptimizer, hackGet }:

with haskellLib;

self: super: {
  ghcWithPackages = selectFrom: self.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/with-packages-wrapper.nix") {
    inherit (self) llvmPackages;
#    haskellPackages = self;
    packages = selectFrom self;
    ${if useReflexOptimizer then "ghcLibdir" else null} = "${self.ghc.bootPackages.ghcWithPackages (p: [ p.reflex ])}/lib/${self.ghc.bootPackages.ghc.name}";
  };

  ghcjs-base = overrideCabal (self.callCabal2nix "ghcjs-base" (fetchFromGitHub {
    owner = "ghcjs";
    repo = "ghcjs-base";
    rev = "43804668a887903d27caada85693b16673283c57";
    sha256 = "1pqmgkan6xhpvsb64rh2zaxymxk4jg9c3hdxdb2cnn6jpx7jsl44";
  }) {}) (drv: {
    jailbreak = true;
    doCheck = false; #TODO: This should be unnecessary

    #TODO: This should be unnecessary
    preConfigure = (drv.preConfigure or "") + ''
      sed -i -e '/jsbits\/export.js/d' -e '/GHCJS\.Foreign\.Export/d' *.cabal
    '';
  });

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  diagrams-lib = dontCheck super.diagrams-lib;
  linear = dontCheck super.linear;
  bytes = dontCheck super.bytes;

  hlint = null;
  hscolour = null;
  cabal-macosx = null;

  #TODO: The following packages' tests fail due to this error:
  # installHandler: not available for GHCJS
  tasty-quickcheck = dontCheck super.tasty-quickcheck;
  scientific = dontCheck super.scientific;
  uuid-types = dontCheck super.uuid-types;
  these = dontCheck super.these;

  #TODO: These look like real test failures:
  aeson = dontCheck super.aeson;
  # Also, pureMD5 is failing

  #TODO: The following packages' tests fail with errors like this:
  # Error: Cannot find module '/tmp/nix-build-hspec-discover-2.4.4.drv-0/hspec-discover-2.4.4/var h$currentThread = null;'
  hspec-core = dontCheck super.hspec-core;
  hspec-discover = dontCheck super.hspec-discover;
  hspec = dontCheck super.hspec;
  bifunctors = dontCheck super.bifunctors;
  base-compat = dontCheck super.base-compat;
  generic-deriving = dontCheck super.generic-deriving;
  newtype-generics = dontCheck super.newtype-generics;
  lens = disableCabalFlag (dontCheck super.lens) "test-properties";

  #TODO: Do we need this patch? it doesn't seem to apply properly
  # hashable = appendPatch super.hashable ../hashable-1.2.6.1.patch;

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;

  # These packages require doctest
  http-types = dontCheck super.http-types;
}
