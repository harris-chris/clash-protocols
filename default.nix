{ pkgs
, gitignore }:

with pkgs;
with gitignore;

haskellPackages.callCabal2nix "clash-protocols" (gitignoreSource ./clash-protocols) {}
