{ pkgs }:
rec {
  lib = import ./lib.nix { inherit (pkgs) lib; };

  utils = import ./utils.nix { inherit lib; };

  common = import ./common.nix { inherit lib; };

  eval = { configuration, extraSpecialArgs ? { } }:
    let
      module = pkgs.lib.evalModules {
        modules = [
          ../modules/initial.nix
          ../modules/accessible.nix
          ../modules/clean.nix
        ];
        specialArgs =
          {
            configuration = configuration {
              inherit (module.config.accessible) workflows actions;
              inherit (utils) qq;
              inherit (lib.values) null_;
            };

            inherit utils common;
          }
          //
          extraSpecialArgs;
      };
    in
    {
      inherit (module) config options;
    };

  example = eval { configuration = import ./example.nix; };

  tests = import ./tests.nix { inherit example; };
}
