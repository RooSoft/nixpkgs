let
  callPackage = path: overrides:
    let f = import path;
    in f
    ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);

  nixpkgs = import <nixpkgs> { };
  allPkgs = nixpkgs // pkgs;

  pkgs = { 
    fetchNodeModules = callPackage ./fetch-node-modules.nix { };
    mempool = callPackage ./mempool.nix { }; 
  };
in pkgs.mempool
