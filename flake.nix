{
  description = "Shared modules / pkgs for my NixOS configs";

  inputs = {};

  outputs = { self, ... }@inputs:
  with builtins; {
    # allows to import just modules needed or all modules if wanted
    nixosModules =
      let modules = listToAttrs (map
        (x: {
          name = x;
          value = import (./modules + "/${x}");
        })
        (attrNames (readDir ./modules)));
      in modules // {
        default = { imports = attrValues modules; };
      };
  };
}
