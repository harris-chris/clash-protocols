{ pkgs
, gitignore }:

with pkgs;
with gitignore.lib;

haskellPackages.callCabal2nix "clash-protocols" (gitignoreSource ./clash-protocols) {}
