{ pkgs }:
rec {
  lib = import ./lib.nix { inherit (pkgs) lib; };

  utils = import ./utils.nix { inherit lib; };

  common = import ./common.nix { inherit lib; };

  eval =
    { configuration }:
    let
      configurationModule = pkgs.lib.evalModules {
        modules = [ ../modules/configuration.nix ];
        specialArgs = {
          configuration =
            let
              configuration' = configuration {
                # arguments available to a user
                inherit (internalModules.config.accessible) workflows actions;
                inherit (utils) qq stepsIf;
                inherit (lib.values) null_;
                values = configurationModule.config.values;
              };
            in
            configuration';

          inherit common lib;
        };
      };

      internalModules = pkgs.lib.evalModules {
        modules = [
          ../modules/accessible.nix
          ../modules/clean.nix
          ../modules/write.nix
          ../modules/docs.nix
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

        specialArgs = {
          inherit configurationModule;

          inherit
            utils
            common
            pkgs
            lib
            ;
        };
      };
    in
    {
      configuration = {
        inherit (configurationModule) config options;
      };
      internal = {
        inherit (internalModules) config options;
      };
    };

  example = eval { configuration = import ./example.nix { inherit (pkgs) lib; }; };

  tests = import ./tests.nix { inherit example; };
}
