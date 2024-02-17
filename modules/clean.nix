{ lib
, config
, utils
, ...
}:
{
  options = {
    clean = lib.mkOption {
      type = lib.types.submodule {
        options = rec {
          default = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          # correct identifiers:
          # with_ -> with
          normalized = default;
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
