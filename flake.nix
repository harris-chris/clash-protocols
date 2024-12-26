{
  description = "clash-protocols";

  inputs = {
    ghc962-nixpkgs.url = "github:NixOS/nixpkgs/5148520bfab61f99fd25fb9ff7bfbb50dad3c9db";
    nixpkgs.url = "github:NixOS/nixpkgs";
    gitignore =  {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };  
    clash-compiler.url = "github:clash-lang/clash-compiler";
  };

  outputs = {
    self
    , ghc962-nixpkgs
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
          ghc962Overlay
          clash-compiler.overlays.default 
        ];
      };

      ghc962Overlay = let
        ghc962Pkgs = import ghc962-nixpkgs { 
          inherit system;
        };
      in self: super: {
        haskell = super.lib.recursiveUpdate super.haskell 
          {
            compiler = { ghc962 = ghc962Pkgs.haskell.compiler.ghc962; };
            packages = { ghc962 = ghc962Pkgs.haskell.packages.ghc962; };
          };
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

          haskellOverridesFromClashPkgs =
            let  
              getBuildInputsFromPkg = pkg: 
                let 
                  allDeps = pkg.buildInputs ++ pkg.propagatedBuildInputs;
                  depsFromPkg = builtins.filter 
                    (x: x != null) 
                    allDeps;
                in builtins.listToAttrs (map 
                  (dep: { 
                    name = dep.name; 
                    value = dep; 
                  }) 
                  depsFromPkg);
            in builtins.foldl' 
              (acc: x: acc // getBuildInputsFromPkg x)
              {}
              clashGetBuildInputsFrom;              

          haskellPkgs = pkgs.haskell.packages.ghc962.override {
            overrides = self: super: 
              haskellOverridesFromClashPkgs // {
              doctest = pkgs.haskell.lib.dontCheck 
                (self.callHackage "doctest" "0.21.1" {});
              clash-prelude = pkgs.haskell.lib.dontCheck (self.callHackageDirect {
                pkg = "clash-prelude";
                ver = "1.8.1";
                sha256 = "sha256-HUt8Aw5vMFWThp26e/FdVkcjGQK8rvUV/ZMlv/KvHgg=";
              } {});
              clash-prelude-hedgehog = pkgs.haskell.lib.dontCheck (self.callHackageDirect {
                pkg = "clash-prelude-hedgehog";
                ver = "1.8.1";
                sha256 = "sha256-RWjqzTlgp5oWpBROZ+hp4Mc3nwh1Xro18oQjNtJnGvY=";
              } {});
              kan-extensions = pkgs.haskell.lib.dontCheck 
                (self.callHackage "kan-extensions" "5.2.5" {});
              circuit-notation = pkgs.haskell.lib.dontCheck (self.callHackageDirect {
                pkg = "circuit-notation";
                ver = "0.1.0.0";
                sha256 = "sha256-D3A51HiTtWJTx2A8BgHpelBl9df62DA2QYYjFkSsGM8=";
              } {});
              clash-protocols-base = self.callCabal2nix 
                  "clash-protocols-base" 
                  (gitignore.lib.gitignoreSource ./clash-protocols-base) {};
              clash-protocols = self.callCabal2nix 
                  "clash-protocols" 
                  (gitignore.lib.gitignoreSource ./clash-protocols) {};
              };
            };
        in {
          inherit (haskellPkgs) clash-protocols-base clash-protocols;
          inherit (clashPkgs) clash-prelude;
        }; 
      in {
        packages.${system} = (clashProtocolsOverlay pkgs pkgs);
        overlays.default = clashProtocolsOverlay;
      };
}
