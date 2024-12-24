{
  description = "clash-protocols";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    gitignore =  {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };  
    clash-compiler.url = "github:clash-lang/clash-compiler";
  };

  outputs = {
    self
    , nixpkgs
    , gitignore
    , clash-compiler
  }:
    let
      system = "x86_64-linux";
      clashCompilerVersion = "ghc962";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ 
          clash-compiler.overlays.default 
        ];
      };

      clashProtocolsOverlay = self: super:
        let
          clashPkgs = super."clashPackages-${clashCompilerVersion}";

          clashGetBuildInputsFrom = [ 
            clashPkgs.clash-benchmark
            clashPkgs.clash-cores
            clashPkgs.clash-cosim
            clashPkgs.clash-ffi
            clashPkgs.clash-ghc
            clashPkgs.clash-lib
            clashPkgs.clash-lib-hedgehog
            clashPkgs.clash-prelude
            clashPkgs.clash-prelude-hedgehog
            clashPkgs.clash-profiling
            clashPkgs.clash-profiling-prepare
            clashPkgs.clash-term
            clashPkgs.clash-testsuite
          ];
      
          clashBuildInputs = [
            clashPkgs.cabal-install
            clashPkgs.haskell-language-server
          ] ++ builtins.concatMap (pkg: pkg.env.nativeBuildInputs) clashGetBuildInputsFrom;

          clash-protocols-base = super.haskellPackages.callCabal2nix 
            "clash-protocols-base" 
            (gitignore.lib.gitignoreSource ./clash-protocols-base) {};

          clash-protocols = self.haskellPackages.callCabal2nix
            "clash-protocols"
            (gitignore.lib.gitignoreSource ./clash-protocols) { inherit clash-protocols-base; };
        in {
          inherit clash-protocols clash-protocols-base;
        }; 
      in {
        packages.${system} = clashProtocolsOverlay pkgs pkgs;
        overlays.default = clashProtocolsOverlay;
      };
}
