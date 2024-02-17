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

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nix-unit
            ];
          };

          default = import ./nix { inherit pkgs; };
        in
        default
        //
        {
          inherit devShells;
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
