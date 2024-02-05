{fetchNodeModules, stdenvNoCC, src, meta, makeWrapper, rsync, nodejs, nodejsRuntime}: 
let

  mkDerivationMempool = args:
    stdenvNoCC.mkDerivation ({
      version = src.rev;
      inherit src meta;

      nativeBuildInputs = [ makeWrapper nodejs rsync ];

      phases = "unpackPhase patchPhase buildPhase installPhase";
    } // args);

  sync = "${rsync}/bin/rsync -a --inplace";

  nodeModules = 
    fetchNodeModules {
      inherit src nodejs;
      preBuild = "cd backend";
      hash = "sha256-HpzzSTuSRWDWGbctVhTcUA01if/7OTI4xN3DAbAAX+U=";
    };

in 
  mkDerivationMempool {
    pname = "mempool-backend";

    buildPhase = ''
      cd backend

      export HOME=$(pwd)

      ${sync} --chmod=+w ${nodeModules}/lib/node_modules .
      patchShebangs node_modules

      npm run package

      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out/lib/mempool-backend
      ${sync} package/ $out/lib/mempool-backend

      makeWrapper ${nodejsRuntime}/bin/node $out/bin/mempool-backend \
        --add-flags $out/lib/mempool-backend/index.js

      runHook postInstall
    '';

    passthru = { inherit nodejs nodejsRuntime; };
  }
