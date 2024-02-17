{ pkgs, tests }:
let
  formatValue = val:
    if (builtins.isList val || builtins.isAttrs val) then builtins.toJSON val
    else builtins.toString val;
  resultToString = { name, expected, result }: ''
    ${name} failed: expected ${formatValue expected}, but got ${formatValue result}
  '';
  results = pkgs.lib.runTests tests;
in
if results != [ ]
then
  pkgs.runCommand "nix-flake-tests-failure" { } ''
    cat <<EOF
    ${builtins.concatStringsSep "\n" (map resultToString results)}
    EOF
    exit 1
  ''
else pkgs.runCommand "nix-flake-tests-success" { } "echo > $out"
