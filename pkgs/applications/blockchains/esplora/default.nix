{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, fetchurl
, rocksdb
, Security
}:

rustPlatform.buildRustPackage rec {
  pname = "esplora";
  version = "20240216";

  src = fetchFromGitHub {
    owner = "Blockstream";
    repo = "electrs";
    rev = "01bd5f91f453358db40864998c5a15ce8c2c36fc";
    hash = "sha256-FuQmedeO/8yJluju+3cx2UREU7LFuGTXPxRdYt97jNg=";
  };

  bitcoindTarball = fetchurl {
    url = "https://bitcoincore.org/bin//bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz";
    hash = "sha256-M5MNQyWT5J1Yqb/0wwB4gj6a9dmFlNKTWGJ4jOiiCuw=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "electrum-client-0.8.0" = "sha256-HDRdGS7CwWsPXkA1HdurwrVu4lhEx0Ay8vHi08urjZ0=";
      "electrumd-0.1.0" = "sha256-s1/laailcwOmqjAPJnuqe7Y45Bvxwqw8EjKN54BS5gI=";
      "jsonrpc-0.12.0" = "sha256-lSNkkQttb8LnJej4Vfe7MrjiNPOuJ5A6w5iLstl9O1k=";
    };
  };

  cargoFeatures = "release";

  # needed for librocksdb-sys
  nativeBuildInputs = [ rustPlatform.bindgenHook ];

  # link rocksdb dynamically
  ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
  ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  BITCOIND_TARBALL_FILE = "${bitcoindTarball}";

  buildInputs = lib.optionals stdenv.isDarwin [ Security ];

  # passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "A block chain index engine and HTTP API written in Rust based on romanz/electrs";
    homepage = "https://github.com/Blockstream/electrs";
    license = licenses.mit;
    maintainers = with maintainers; [ roosoft ];
    mainProgram = "electrs";
  };
}
