{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.isekai.persistence;
in
{
  options.isekai.persistence = {
    enable = mkEnableOption "settings for erase-your-darlings setup with encrypted zfs pool";

    dir = mkOption {
      type = types.path;
      default = "/persist";
    };

    initrd-remote-unlock = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      hostKeys = mkOption {
        type = types.listOf types.path;
        default = [ /boot/initrd-ssh-key ];
      };
      port = mkOption {
        type = types.port;
        default = 2222;
      };
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = config.isekai.ssh-server.rootKeys;
      };
      postCommands = mkOption {
        type = types.str;
        default = ''
          cat <<EOF > /root/.profile
          if pgrep -x zfs > /dev/null
          then
            zfs load-key -a
            killall zfs
          else
            echo zfs not running -- maybe the pool is taking some time to load for some unforseen reason.
          fi
          EOF
        '';
      };
    };

    ssh-host-keys.enable = mkOption {
      type = types.bool;
      default = true;
    };

    set-machine-id = mkOption {
      type = types.bool;
      default = true;
    };

    machine-id = mkOption {
      type = types.str;
      default = "";
    };

    dirs = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    files = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    postDeviceCommands = mkOption {
      type = types.str;
      default = ''zfs rollback -r zroot/local/root@blank'';
    };
  };

  config = mkIf cfg.enable (mkMerge
    [
      {
        boot.initrd.postDeviceCommands = mkAfter cfg.postDeviceCommands;
        environment.persistence."${cfg.dir}" = {
          directories = [
            "/var/log"
            "/var/db/sudo/lectured"
            "/var/lib/systemd/coredump"
          ] ++ cfg.dirs;
          files = [
            # "/etc/passwd"
            # "/etc/shadow"
          ] ++ cfg.files;
        };
      }
      (mkIf cfg.initrd-remote-unlock.enable {
        boot.initrd.network = {
          enable = true;
          ssh = {
            enable = true;
            port = cfg.initrd-remote-unlock.port;
            hostKeys = cfg.initrd-remote-unlock.hostKeys;
            authorizedKeys = cfg.initrd-remote-unlock.authorizedKeys;
          };
          postCommands = cfg.initrd-remote-unlock.postCommands;
        };
      })
      (mkIf cfg.ssh-host-keys.enable {
        services.openssh = {
          hostKeys = [
            {
              path = "${cfg.dir}/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
            {
              path = "${cfg.dir}/etc/ssh/ssh_host_rsa_key";
              type = "rsa";
              bits = 4096;
            }
          ];
        };
      })
      (mkIf cfg.set-machine-id {
        environment.etc.machine-id = {
          text = "${cfg.machine-id}\n";
          mode = "0444";
        };
      })
    ]);
}
