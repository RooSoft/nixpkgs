{ config, lib, pkgs, ... }:

let

  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.mempool;

  user = "mempool";
  group = config.services.httpd.group;

  databaseName = "mempool";

  pkg = pkgs.mempool;
  frontendDocumentRoot = pkg.mempool-frontend;

in
{
  # interface

  options = {
    services.mempool = {
      enable = mkEnableOption (lib.mdDoc "Mempool: explore the full Bitcoin ecosystem");

      bitcoinCore.ip = mkOption {
        type = types.str;
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

    # services.mempool.config = mapAttrs (name: mkDefault) {
    # };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ databaseName ];
      ensureUsers = [
        {
          name = user;
          ensurePermissions."${databaseName}.*" = "ALL PRIVILEGES";
        }
      ];
    };

    services.httpd = {
      enable = true;
      virtualHosts."mempool" = {
        # serverName = "_";
        listen = [{
          ip = "*";
          port = 80;
          ssl = false;
        }];
        documentRoot = "/nix/store/i4kr22jxf338dd51qfx40wy201chissk-mempool-frontend-v2.5.0/en-US/"; #frontendDocumentRoot;
      };
    };

    users.groups.wwwrun = {};
    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };
  };
}
