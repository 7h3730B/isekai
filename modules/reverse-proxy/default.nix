{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.isekai.reverse-proxy;
in
{
  options.isekai.reverse-proxy = {
    enable = mkEnableOption "NGINX reverse proxy standard config";

    openFirewall = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      defaults.email = "teo.sb@proton.me";
      acceptTerms = true;
    };

    services.nginx = {
      inherit (cfg) enable;

      recommendedGzipSettings = mkDefault true;
      recommendedTlsSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;
    };
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 443 ];
  };
}
