{ lib
, config
, utils
, ...
}:
{
  options = {
    clean = lib.mkOption {
      type = lib.types.submodule {
        options =
          let
            option = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
            };
          in
          {
            default = option;
            normalized = option;
          };
      };
    };
  };

  config = {
    clean = rec {
      default =
        utils.cleanWorkflows (
          utils.resolveWorkflows {
            inherit config;
          }
        );
      normalized = lib.pipe default [
        (
          # rename: "with_" -> "with"
          lib.mapAttrsRecursive'
            (name: value: {
              name = if name == "with_" then "with" else name;
              inherit value;
            })
        )
      ];
    };
  };
}
