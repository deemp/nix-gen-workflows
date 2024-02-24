{ lib
, config
, ...
}: {
  options = {
    user = lib.mkOption {
      type = lib.types.submodule {
        options = {
          parameters = lib.mkOption {
            type = lib.types.submodule {
              options = config.parameters;
            };
            default = { };
          };
        };
      };
      default = { };
    };
  };
}
