{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.isekai.deploy;
in
{
  options.isekai.deploy = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable remote deployment for this host";
    };

    ip = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Overwrite the IP to use for connecting via SSH";
    };

    port = mkOption {
      type = types.port;
      default = 22;
      description = "Change the ssh port";
    };

    sshUser = mkOption {
      type = types.str;
      default = "root";
      description = "the ssh user";
    };
  };

  config = { };
}
