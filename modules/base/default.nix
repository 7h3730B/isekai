{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.isekai.base;
in
{
  options.isekai.base = {
    enable = mkEnableOption "base configs";

    zramSwap = mkOption {
      type = types.bool;
      default = false;
    };

    DNSOverTLS = mkOption {
      type = types.bool;
      default = false;
    };

    networkTweaks = mkOption {
      type = types.bool;
      default = false;
    };

    node-exporter = mkOption {
      type = types.bool;
      default = false;
    };

    zfs = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable (mkMerge
    [{
      zramSwap.enable = cfg.zramSwap;
    }
      (mkIf cfg.zfs {
        services.zfs = {
          autoScrub.enable = true;
          autoSnapshot.enable = lib.mkDefault false;
          trim.enable = lib.mkDefault false;
        };
        # Only run than plugged in
        systemd.services = {
          zfs-scrub.unitConfig.ConditionACPower = true;
          zpool-trim.unitConfig.ConditionACPower = true;
        };
      })
      (mkIf cfg.DNSOverTLS {
        services = {
          resolved = {
            enable = true;
            dnssec = "true";
            fallbackDns = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
            extraConfig = ''
              DNSOverTLS=yes
            '';
          };
        };
      })
      (mkIf cfg.node-exporter {
        services.prometheus.exporters = {
          node = {
            enable = true;
            enabledCollectors = [
              "systemd"
            ];
            port = 9002;
          };
        };
      })
      (mkIf cfg.networkTweaks {
        boot.kernelModules = [ "tcp_bbr" ];

        boot.kernel.sysctl = {
          # Disable magic SysRq key
          "kernel.sysrq" = mkDefault 0;
          # Disable bpf() JIT
          "net.core.bpf_jit_enable" = mkDefault false;
          # Disable ftrace debugging
          "kernel.ftrace_enabled" = mkDefault false;
          # Ignore ICMP broadcasts to avoid participating in Smurf attacks
          "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault 1;
          # Ignore bad ICMP errors
          "net.ipv4.icmp_ignore_bogus_error_responses" = mkDefault 1;
          # Reverse-path filter for spoof protection
          "net.ipv4.conf.default.rp_filter" = mkDefault 1;
          "net.ipv4.conf.all.rp_filter" = mkDefault 1;
          # SYN flood protection
          "net.ipv4.tcp_syncookies" = mkDefault 1;
          # Do not accept ICMP redirects (prevent MITM attacks)
          "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
          "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
          "net.ipv4.conf.all.secure_redirects" = mkDefault 0;
          "net.ipv4.conf.default.secure_redirects" = mkDefault 0;
          "net.ipv6.conf.all.accept_redirects" = mkDefault 0;
          "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
          # Do not send ICMP redirects (we are not a router)
          "net.ipv4.conf.all.send_redirects" = mkDefault 0;
          "net.ipv4.conf.default.send_redirects" = mkDefault 0;
          # Do not accept IP source route packets (we are not a router)
          "net.ipv4.conf.all.accept_source_route" = mkDefault 0;
          "net.ipv6.conf.all.accept_source_route" = mkDefault 0;
          # Protect against tcp time-wait assassination hazards
          "net.ipv4.tcp_rfc1337" = mkDefault 1;
          # TCP Fast Open (TFO)
          "net.ipv4.tcp_fastopen" = mkDefault 3;
          ## Bufferbloat mitigations
          # Requires >= 4.9 & kernel module
          "net.ipv4.tcp_congestion_control" = mkDefault "bbr";
          # Requires >= 4.19
          "net.core.default_qdisc" = mkDefault "cake";
        };
      })]);
}
