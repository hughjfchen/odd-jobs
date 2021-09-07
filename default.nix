let
  sources = import ./nix/sources.nix;
  # Fetch the latest haskell.nix and import its default.nix
  haskellNix = import sources."haskell.nix" {};
  # haskell.nix provides access to the nixpkgs pins which are used by our CI, hence
  # you will be more likely to get cache hits when using these.
  # But you can also just use your own, e.g. '<nixpkgs>'
  nixpkgsSrc = if haskellNix.pkgs.lib.strings.hasSuffix builtins.currentSystem "darwin" then sources.nixpkgs-darwin else haskellNix.sources.nixpkgs-2105;
  # haskell.nix provides some arguments to be passed to nixpkgs, including some patches
  # and also the haskell.nix functionality itself as an overlay.
  nixpkgsArgs = haskellNix.nixpkgsArgs;
in
{ nativePkgs ? import nixpkgsSrc (nixpkgsArgs // { overlays = nixpkgsArgs.overlays ++ [(import ./nix/overlay)]; })
, haskellCompiler ? "ghc884"
}:
let pkgs = nativePkgs;
in
# 'cabalProject' generates a package set based on a cabal.project (and the corresponding .cabal files)
rec {
  # inherit the pkgs package set so that others importing this function can use it
  inherit pkgs;

  # nativePkgs.lib.recurseIntoAttrs, just a bit more explicilty.
  recurseForDerivations = true;

  odd-jobs = (pkgs.haskell-nix.project {
      src = pkgs.haskell-nix.haskellLib.cleanGit {
        name = "odd-jobs";
        src = ./.;
      };
      index-state = "2021-07-18T00:00:00Z";
      compiler-nix-name = haskellCompiler;
      modules = [
        { packages.odd-jobs.dontStrip = false; }
      ];
  });

  odd-jobs-exe = odd-jobs.odd-jobs.components.exes.odd-jobs-cli-example;
  #odd-jobs-test = odd-jobs.odd-jobs.components.tests.jobrunner;

}

