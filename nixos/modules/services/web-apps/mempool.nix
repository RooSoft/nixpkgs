{ config, lib, pkgs, ... }:

let

  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.mempool;

  user = "mempool";
  dbUser = "mempool";
  group = config.services.httpd.group;

  databaseName = "mempool";

  mempoolConfig = {
    CORE_RPC = {
      HOST = cfg.bitcoinCore.ip;
      PORT = cfg.bitcoinCore.port;
      USERNAME = "mempool";
      PASSWORD = cfg.bitcoinCore.rpc.password;
      TIMEOUT = 60000;
      COOKIE = false;
    };
    ELECTRUM = {
      HOST = cfg.electrum.ip;
      PORT = cfg.electrum.port;
      TLS_ENABLED = false;
    };
    DATABASE = {
      ENABLED = true;
      HOST = "localhost";
      PORT = 3306;
      SOCKET = "/var/run/mysqld/mysqld.sock";
      DATABASE = "mempool";
      USERNAME = dbUser;
      PASSWORD = "mempool";
    };
  };

  mempoolJsonConfig = builtins.toJSON mempoolConfig;

  mempoolConfigFile = pkgs.writeText "config.json" mempoolJsonConfig;

in
{
  # interface

  options = {
    services.mempool = {
      enable = mkEnableOption (lib.mdDoc "Mempool: explore the full Bitcoin ecosystem");

      backend.url = mkOption {
        type = types.str;
        default = "http://127.0.0.1";
        description = ''
          Mempool's backend URL
        '';
      };

      bitcoinCore.ip = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = lib.mdDoc ''
          Bitcoin Core node's IP
        '';
      };

      bitcoinCore.port = mkOption {
        type = types.int;
        default = "8332";
        description = lib.mdDoc ''
          Bitcoin core node's port
        '';
      };

      bitcoinCore.rpc.password = mkOption {
        type = types.str;
        default = "some_hard_to_guess_password";
        description = ''
          Bitcoin Core RPC password
        '';
      };

      electrum.ip = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = lib.mdDoc ''
          Electrum server's IP
        '';
      };

      electrum.port = mkOption {
        type = types.int;
        default = "50001";
        description = lib.mdDoc ''
          Electrum server's port
        '';
      };

    };
  };

  # implementation

  config = mkIf cfg.enable {
    systemd.services.mempool-backend = {
      description = "Mempool's backend";

      environment = {
        MEMPOOL_CONFIG_FILE = "${mempoolConfigFile}";
      };

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        User = user;
        Group = group;

        Type = "simple";
        Restart = "on-failure";
        ExecStart = "${pkgs.mempool.backend}/bin/mempool-backend";

        StateDirectory = "mempool";
      };

    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ databaseName ];
      ensureUsers = [
        {
          name = dbUser;
          ensurePermissions."${databaseName}.*" = "ALL PRIVILEGES";
        }
      ];
    };

    services.nginx = {
      enable = true;

      # httpConfig = ''
      #   include ${pkgs.mempool.nginx-conf}/mempool/http-language.conf;
      # '';

      virtualHosts = {
        "mempool" = {
          forceSSL = false;
          root = "${pkgs.mempool.frontend}/en-US";
          locations = let
            backend = cfg.backend.url;
          in {
            "/api" = {
              proxyPass = "${backend}/api/v1";
            };

            "/api/v1" = {
              proxyPass = "${backend}";
            };

            "/api/v1/ws" = {
              proxyPass = backend;
              proxyWebsockets = true;
            };

            # "/resources" = {
            #   proxyPass = "${pkgs.mempool.frontend}/resources";
            # };
          };
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
