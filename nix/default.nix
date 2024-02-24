{ pkgs }:
rec {
  lib = import ./lib.nix { inherit (pkgs) lib; };

  utils = import ./utils.nix { inherit lib; };

  common = import ./common.nix { inherit lib; };

  eval = { configuration, extraSpecialArgs ? { } }:
    let
      module = pkgs.lib.evalModules {
        modules = [
          ../modules/configuration.nix
          ../modules/accessible.nix
          ../modules/clean.nix
          ../modules/write.nix
          ../modules/docs.nix
          ../modules/parameters.nix
          {
            config.modules-docs.roots = [
              {
                url = "https://github.com/deemp/nix-gen-workflows";
                path = toString ../.;
                branch = "main";
              }
            ];
          }
        ];
        specialArgs =
          {
            configuration = configuration {
              inherit (module.config.accessible) workflows actions;
              inherit (utils) qq stepsIf;
              inherit (lib.values) null_;
              config = module.config.user.parameters;
            };

            inherit utils common pkgs lib;
          }
          //
          extraSpecialArgs;
      };
    in
    {
      inherit (module) config options;
    };

  example = eval { configuration = import ./example.nix { inherit (pkgs) lib; }; };

  tests = import ./tests.nix { inherit example; };
}
