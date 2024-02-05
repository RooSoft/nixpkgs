{ config, lib, pkgs, ... }:

let

  inherit (lib) mkDefault mkEnableOption mkIf mkOption;
  inherit (lib) mapAttrs types;

  cfg = config.services.mempool;

  user = "mempool";
  group = config.services.httpd.group;

  # pkg = pkgs.mempool;

  databaseName = "mempool";

  # frontend.nginxConfig = {
  #   # This must be added to `services.nginx.commonHttpConfig` when
  #   # `mempool/location-static.conf` is used
  #   httpConfig = ''
  #     include ${pkg.mempool-nginx-conf}/mempool/http-language.conf;
  #   '';
  #
  #   # This should be added to `services.nginx.virtualHosts.<mempool server name>.extraConfig`
  #   staticContent = ''
  #     index index.html;
  #
  #     add_header Cache-Control "public, no-transform";
  #     add_header Vary Accept-Language;
  #     add_header Vary Cookie;
  #
  #     include ${pkg.mempool-backend}/mempool/location-static.conf;
  #
  #     # Redirect /api to /docs/api
  #     location = /api {
  #       return 308 https://$host/docs/api;
  #     }
  #     location = /api/ {
  #       return 308 https://$host/docs/api;
  #     }
  #   '';
  #
  #   # This should be added to `services.nginx.virtualHosts.<mempool server name>.extraConfig`
  #   proxyApi = let
  #     backend = "http://${pkg.addressWithPort cfg.address cfg.port}";
  #   in ''
  #     location /api/ {
  #         proxy_pass ${backend}/api/v1/;
  #     }
  #     location /api/v1 {
  #         proxy_pass ${backend};
  #     }
  #     # Websocket API
  #     location /api/v1/ws {
  #         proxy_pass ${backend};
  #
  #         # Websocket header settings
  #         proxy_set_header Upgrade $http_upgrade;
  #         proxy_set_header Connection "Upgrade";
  #
  #         # Relevant settings from `recommendedProxyConfig` (nixos/nginx/default.nix)
  #         # (In the above api locations, this are inherited from the parent scope)
  #         proxy_set_header Host $host;
  #         proxy_set_header X-Real-IP $remote_addr;
  #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #         proxy_set_header X-Forwarded-Proto $scheme;
  #
  # };

in
{
  # interface

  options = {
    services.mempool = {
      enable = mkEnableOption (lib.mdDoc "Mempool: explore the full Bitcoin ecosystem");

      bitcoinCore.ip = mkOption {
        type = types.string;
        default = "127.0.0.1";
        description = lib.mdDoc ''
          The IP of the Bitcoin Core node
        '';
      };

      bitcoinCore.port = mkOption {
        type = types.int;
        default = "8332";
        description = lib.mdDoc ''
          The port of the Bitcoin Core node
        '';
      };
    };
  };

  # implementation

  config = mkIf cfg.enable {

    services.mempool.config = mapAttrs (name: mkDefault) {
    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ databaseName ];
      ensureUsers = [
        {
          name = cfg.user;
          ensurePermissions."${databaseName}.*" = "ALL PRIVILEGES";
        }
      ];
    };

    # services.httpd = {
    #   enable = true;
    #   adminAddr = mkDefault cfg.virtualHost.adminAddr;
    #   extraModules = [ "proxy_fcgi" ];
    #   virtualHosts."mempool" = {
    #     serverName = "_";
    #     listen = [ { addr = cfg.frontend.address; port = cfg.frontend.port; } ];
    #     root = cfg.frontend.staticContentRoot;
    #     extraConfig =
    #       frontend.nginxConfig.staticContent +
    #       frontend.nginxConfig.proxyApi;
    #   };
    # };

    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };
  };
}
