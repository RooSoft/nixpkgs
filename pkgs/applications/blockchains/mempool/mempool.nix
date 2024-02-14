{ fetchFromGitHub, nodejs-18_x, nodejs-slim-18_x
, lib, buildNpmPackage, callPackage, runCommand }:
let

  nodejs = nodejs-18_x;
  nodejsRuntime = nodejs-slim-18_x;

  fetchNodeModules = callPackage ./fetch-node-modules.nix { };

  src = fetchFromGitHub {
    owner = "mempool";
    repo = "mempool";
    rev = "v2.5.0";
    hash = "sha256-8HmfytxRte3fQ0QKOljUVk9YAuaXhQQWuv3EFNmOgfQ=";
  };

  meta = with lib; {
    description = "Bitcoin blockchain and mempool explorer";
    homepage = "https://github.com/mempool/mempool/";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ erikarvstedt ];
    platforms = platforms.unix;
  };

in {
  backend = callPackage ./backend.nix {
    inherit nodejs nodejsRuntime src meta fetchNodeModules;
  };

  frontend = callPackage ./frontend.nix {
    inherit nodejs src meta fetchNodeModules;
  };
}
