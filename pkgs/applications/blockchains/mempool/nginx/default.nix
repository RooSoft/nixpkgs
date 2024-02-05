{ runCommand, rsync }:
let

  sync = "${rsync}/bin/rsync -a --inplace";

in runCommand "mempool-nginx-conf" { } ''
  ${sync} --chmod=u+w ${./conf}/ $out
''
