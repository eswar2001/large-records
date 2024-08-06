{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/75a52265bda7fd25e06e3a67dee3f0354e73243c";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    ghc-hasfield-plugin.url = "github:eswar2001/ghc-hasfield-plugin/c932ebc0d7e824129bb70c8a078f3c68feed85c9";
    beam.url = "github:well-typed/beam/57a12e68727c027f0f1c25752f8c5704ddbe1516";
    beam.flake = false;
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { self', pkgs, ... }: {

        # Typically, you just want a single project named "default". But
        # multiple projects are also possible, each using different GHC version.
        haskellProjects.default = {
          # The base package set representing a specific GHC version.
          # By default, this is pkgs.haskellPackages.
          # You may also create your own. See https://community.flake.parts/haskell-flake/package-set
          # basePackages = pkgs.haskellPackages;

          # Extra package information. See https://community.flake.parts/haskell-flake/dependency
          #
          # Note that local packages are automatically included in `packages`
          # (defined by `defaults.packages` option).
          #
          # defaults.enable = false;
          # devShell.tools = hp: with hp; {
          #   inherit cabal-install;
          #   inherit hp;
          # };
          projectFlakeName = "large-records";
          # basePackages = pkgs.haskell.packages.ghc8107;
          basePackages = pkgs.haskell.packages.ghc92;
          imports = [
            # inputs.references.haskellFlakeProjectModules.output
            # inputs.classyplate.haskellFlakeProjectModules.output
          ];
          packages = {
            ghc-hasfield-plugin.source = inputs.ghc-hasfield-plugin;
            beam-core.source = inputs.beam + /beam-core;
            beam-migrate.source = inputs.beam + /beam-migrate;
            beam-sqlite.source = inputs.beam + /beam-sqlite;
          };
          settings = {
            #  aeson = {
            #    check = false;
            #  };
            #  relude = {
            #    haddock = false;
            #    broken = false;
            #  };
            # primitive-checked = {
            #     broken = false;
            #     jailbreak = true;
            # };
          };

          devShell = {
            # Enabled by default
            # enable = true;

            hlsCheck.enable = pkgs.stdenv.isDarwin; # On darwin, sandbox is disabled, so HLS can use the network.
          };
        };

        # haskell-flake doesn't set the default package, but you can do it here.
        packages.default = self'.packages.large-records;
      };
    };
}
