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
      HOST = cfg.bitcoinCore.host;
      PORT = cfg.bitcoinCore.port;
      USERNAME = cfg.bitcoinCore.rpc.username;
      PASSWORD = cfg.bitcoinCore.rpc.password;
      TIMEOUT = 60000;
      COOKIE = false;
    };
    ELECTRUM = {
      HOST = cfg.electrum.host;
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
  options = {
    services.mempool = {
      enable = mkEnableOption (lib.mdDoc "Mempool: explore the full Bitcoin ecosystem");

      backend.url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:8999";
        description = ''
          Mempool's backend URL
        '';
      };

      bitcoinCore.host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = lib.mdDoc ''
          Bitcoin Core node RPC API host
        '';
      };

      bitcoinCore.port = mkOption {
        type = types.port;
        default = "8332";
        description = lib.mdDoc ''
          Bitcoin core node RPC API port
        '';
      };

      bitcoinCore.rpc.username = mkOption {
        type = types.str;
        default = "mempool";
        description = ''
          Bitcoin Core RPC RPC API user name
        '';
      };

      bitcoinCore.rpc.password = mkOption {
        type = types.str;
        default = "some_hard_to_guess_password";
        description = ''
          Bitcoin Core RPC RPC API password
        '';
      };

      electrum.host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = lib.mdDoc ''
          Electrum server's host
        '';
      };

      electrum.port = mkOption {
        type = types.port;
        default = "50001";
        description = lib.mdDoc ''
          Electrum server's port
        '';
      };
    };
  };

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

      recommendedGzipSettings = true;
      recommendedOptimisation = true;

      virtualHosts = {
        "mempool" = {
          forceSSL = false;
          root = "${pkgs.mempool.frontend}";
          locations = let
            backend = cfg.backend.url;
          in {
            "/" = {
              tryFiles = "/en-US/$uri @index-redirect";
              extraConfig = "expires 10m;";
            };

            "/resources" = {
              tryFiles = "$uri @index-redirect";
              extraConfig = "expires 1h;";
            };

            "@index-redirect" = {
              extraConfig = "rewrite (.*) /$lang/index.html;";
            };

            "~ ^/(ar|bg|bs|cs|da|de|et|el|es|eo|eu|fa|fr|gl|ko|hr|id|it|he|ka|lv|lt|hu|mk|ms|nl|ja|nb|nn|pl|pt|pt-BR|ro|ru|sk|sl|sr|sh|fi|sv|th|tr|uk|vi|zh|hi)/" = {
              tryFiles = "$uri $uri/ /$1/index.html =404";
            };

            "/api" = {
              proxyPass = "${backend}/api/v1";
            };

            "/api/v1" = {
              proxyPass = "${backend}";
            };

            "/api/v1/ws" = {
              proxyPass = "${backend}";
              proxyWebsockets = true;
            };
          };
        };
      };

      appendHttpConfig = ''
        map $http_accept_language $header_lang {
	          default ''';
            ~*^en-US ''';
            ~*^en ''';
            ~*^ar ar;
            ~*^cs cs;
            ~*^da da;
            ~*^de de;
            ~*^es es;
            ~*^fa fa;
            ~*^fr fr;
            ~*^ko ko;
            ~*^hi hi;
            ~*^it it;
            ~*^he he;
            ~*^ka ka;
            ~*^hu hu;
            ~*^mk mk;
            ~*^nl nl;
            ~*^ja ja;
            ~*^nb nb;
            ~*^pl pl;
            ~*^pt pt;
            ~*^ro ro;
            ~*^ru ru;
            ~*^sl sl;
            ~*^fi fi;
            ~*^sv sv;
            ~*^th th;
            ~*^tr tr;
            ~*^uk uk;
            ~*^vi vi;
            ~*^zh zh;
            ~*^lt lt;
          }
        map $cookie_lang $lang {
            default $header_lang;
            ~*^en-US ''';
            ~*^en ''';
            ~*^ar ar;
            ~*^cs cs;
            ~*^da da;
            ~*^de de;
            ~*^es es;
            ~*^fa fa;
            ~*^fr fr;
            ~*^ko ko;
            ~*^hi hi;
            ~*^it it;
            ~*^he he;
            ~*^ka ka;
            ~*^hu hu;
            ~*^mk mk;
            ~*^nl nl;
            ~*^ja ja;
            ~*^nb nb;
            ~*^pl pl;
            ~*^pt pt;
            ~*^ro ro;
            ~*^ru ru;
            ~*^sl sl;
            ~*^fi fi;
            ~*^sv sv;
            ~*^th th;
            ~*^tr tr;
            ~*^uk uk;
            ~*^vi vi;
            ~*^zh zh;
            ~*^lt lt;
          }
      '';
    };

    users.groups.wwwrun = {};
    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };
  };
}
