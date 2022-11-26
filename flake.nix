{
  description = "Shared modules / pkgs for my NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs }@inputs:
  with builtins; {
    nixosModules = listToAttrs (map
    (x: {
      name = x;
      value = import (./modules + "/${x}");
    })
    (attrNames (readDir ./modules)));
  };
}
