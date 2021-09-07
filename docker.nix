{ nativePkgs ? (import ./default.nix {}).pkgs,
crossBuildProject ? import ./cross-build.nix {} }:
nativePkgs.lib.mapAttrs (_: prj:
with prj.java-analyzer-runner;
let
  executable = java-analyzer-runner.components.exes.java-analyzer-runner;
  binOnly = pkgs.runCommand "java-analyzer-runner-bin" { } ''
    mkdir -p $out/bin
    cp ${executable}/bin/java-analyzer-runner $out/bin
    ${nativePkgs.nukeReferences}/bin/nuke-refs $out/bin/java-analyzer-runner
  '';
in pkgs.dockerTools.buildImage {
  name = "java-analyzer-runner";
  contents = [ binOnly pkgs.cacert pkgs.iana-etc ];
  config.Entrypoint = "java-analyzer-runner";
}) crossBuildProject
