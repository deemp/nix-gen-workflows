{
  inputs = {
    nixpkgs.url = "github:deemp/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs:
    (
      inputs.flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;
          default = import ./nix { inherit pkgs; };
        in
        default
        //
        {
          packages.nix-unit = pkgs.writeShellApplication {
            name = "nix-unit-tests";
            text = ''${lib.getExe pkgs.nix-unit} --flake .#tests.${system}'';
          };
          checks.nix-unit =
            pkgs.stdenv.mkDerivation {
              name = "nix-unit-tests";
              phases = [ "unpackPhase" "buildPhase" ];
              src = ./.;
              buildPhase = ''
                export HOME="$(realpath .)"
                ${lib.getExe pkgs.nix-unit} \
                  --eval-store "$HOME" \
                  --flake \
                  --option extra-experimental-features flakes \
                  --override-input nixpkgs ${inputs.nixpkgs.outPath} \
                  --override-input flake-utils ${inputs.flake-utils.outPath} \
                  --override-input flake-utils/systems ${inputs.flake-utils.inputs.systems.outPath} \
                  .#tests.${system}
                touch $out
              '';
            };
        }
      )
    )
    //
    {
      overlays.default = _: prev: {
        nix-gen-workflows = (import ./nix { pkgs = prev; }).eval;
      };
    }
  ;
}
