{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.isekai.xrdp;
in
  {
    options.isekai.xrdp = {
      enable = mkEnableOption "xrdp service";

      port = mkOption {
        type = types.port;
        default = 3389;
        description = ''
          port xrdp listens on
        '';'
      };

      openFirewall = mkOption {
        default = false;
        type = types.bool;
      };
    };

    config = mkIf cfg.enable {
      services.xrdp = {
        inherit (cfg) enable port openFirewall;
      };
    };
  }
