{ fetchNodeModules, stdenvNoCC, src, meta, makeWrapper, rsync, curl, cacert
, nodejs }:
let

  fetchFiles = { name, hash, fetcher }:
    stdenvNoCC.mkDerivation {
      inherit name;
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
      nativeBuildInputs = [ curl cacert ];
      buildCommand = ''
        mkdir $out
        cd $out
        ${builtins.readFile fetcher}
      '';
    };

  mkDerivationMempool = args:
    stdenvNoCC.mkDerivation ({
      version = src.rev;
      inherit src meta;

      nativeBuildInputs = [ makeWrapper nodejs rsync ];

      phases = "unpackPhase patchPhase buildPhase installPhase";
    } // args);

  sync = "${rsync}/bin/rsync -a --inplace";

  modules = fetchNodeModules {
    inherit src nodejs;
    preBuild = "cd frontend";
    hash = "sha256-/Z0xNvob7eMGpzdUWolr47vljpFiIutZpGwd0uYhPWI=";
  };

  frontendAssets = fetchFiles {
    name = "mempool-frontend-assets";
    hash = "sha256-3TmulAfzJJMf0UFhnHEqjAnzc1TNC5DM2XcsU7eyinY=";
    fetcher = ./frontend-assets-fetch.sh;
  };

in mkDerivationMempool {
  pname = "mempool-frontend";

  buildPhase = ''
    cd frontend

    export HOME=$(pwd)

    rm proxy.conf.js
    cp proxy.conf.mixed.js proxy.conf.js

    cat proxy.conf.js

    ${sync} --chmod=+w ${modules}/lib/node_modules .
    patchShebangs node_modules

    # sync-assets.js is called during `npm run build` and downloads assets from the
    # internet. Disable this script and instead add the assets manually after building.
    : > sync-assets.js

    # If this produces incomplete output (when run in a different build setup),
    # see https://github.com/mempool/mempool/issues/1256
    npm run build

    # Add assets that would otherwise be downloaded by sync-assets.js
    ${sync} ${frontendAssets}/ dist/mempool/browser/resources

    runHook postBuild
  '';

  installPhase = ''
    ${sync} dist/mempool/browser/ $out

    runHook postInstall
  '';

  passthru = { assets = frontendAssets; };
}
