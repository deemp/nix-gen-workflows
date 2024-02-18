{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
          checks.nix-unit =
            let
              inputs' = lib.mapAttrs (name: input: "${input.outPath}") inputs;
              inputsFile = builtins.toFile "inputs.json" (builtins.toJSON inputs');
            in
            pkgs.stdenv.mkDerivation {
              name = "nix-unit-tests";
              nativeBuildInputs = [ pkgs.nix ];
              src = ./.;
              buildPhase = ''
                export NIX_PATH=nixpkgs=${pkgs.path}
                export HOME=$(realpath .)
                cd nix
                ${lib.getExe pkgs.nix-unit} \
                  --eval-store $(realpath .) \
                  --arg inputs 'builtins.fromJSON (builtins.readFile ${inputsFile})' \
                  tests.nix
                touch $out  
              '';
            };
        }
      )
    )
    //
    {
      overlays.default = final: prev: {
        nix-gen-workflows = (import ./nix { pkgs = prev; }).eval;
      };
    }
  ;
}
