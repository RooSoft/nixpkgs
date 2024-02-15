{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, rocksdb_6_23
, Security
}:

let
  rocksdb = rocksdb_6_23;
in
rustPlatform.buildRustPackage rec {
  pname = "esplora";
  version = "20240215";

  src = fetchFromGitHub {
    owner = "Blockstream";
    repo = "electrs";
    rev = "05828cd6684be84e36fb1eb8f08f62428618a";
    hash = "sha256-U7o6b/UbPw0LSVPUzxmTd+03GM2S/RsxdS9mopmsnDU=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "electrum-client-0.8.0" = "sha256-HDRdGS7CwWsPXkA1HdurwrVu4lhEx0Ay8vHi08urjZ0=";
      "electrumd-0.1.0" = "sha256-s1/laailcwOmqjAPJnuqe7Y45Bvxwqw8EjKN54BS5gI=";
      "jsonrpc-0.12.0" = "sha256-lSNkkQttb8LnJej4Vfe7MrjiNPOuJ5A6w5iLstl9O1k=";
    };
  };

  # needed for librocksdb-sys
  nativeBuildInputs = [ rustPlatform.bindgenHook ];

  # link rocksdb dynamically
  ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
  ROCKSDB_LIB_DIR = "${rocksdb}/lib";

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
