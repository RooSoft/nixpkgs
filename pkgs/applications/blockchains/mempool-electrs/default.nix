{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, Security
, rocksdb
}:

rustPlatform.buildRustPackage rec {
  pname = "mempool-electrs";
  version = "20240215";

  src = fetchFromGitHub {
    owner = "mempool";
    repo = "electrs";
    rev = "13e50239acf204df46255d4d401b4af8f0273596";
    hash = "sha256-Ux7vlZq7oxGjCUKR4wxkfdlO7fkm8Gbefg2v6s84Ar4=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "electrum-client-0.8.0" = "sha256-HDRdGS7CwWsPXkA1HdurwrVu4lhEx0Ay8vHi08urjZ0=";
    };
  };

  # needed for librocksdb-sys
  nativeBuildInputs = [ rustPlatform.bindgenHook ];

  # link rocksdb dynamically
  # ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
  # ROCKSDB_LIB_DIR = "${rocksdb}/lib";

  buildInputs = lib.optionals stdenv.isDarwin [ Security ];

  meta = with lib; {
    description = "A block chain index engine and HTTP API written in Rust based on romanz/electrs";
    homepage = "https://github.com/Blockstream/electrs";
    license = licenses.mit;
    maintainers = with maintainers; [ roosoft ];
    mainProgram = "electrs";
  };
}
