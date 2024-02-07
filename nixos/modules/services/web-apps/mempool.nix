{ config, lib, pkgs, ... }:

let

  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.mempool;

  user = "mempool";
  group = config.services.httpd.group;

  databaseName = "mempool";

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

    services.nginx = {
      enable = true;
      virtualHosts = {
        "mempool" = {
          forceSSL = false;
          root = "${pkgs.mempool.frontend}/en-US";
        };
      };
    };

    users.groups.wwwrun = {};
    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };
  };
}
