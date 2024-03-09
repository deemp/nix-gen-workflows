{
  lib,
  common,
  config,
  configuration,
  options,
  ...
}:
{
  options = {
    valuesSchema = lib.mkOption {
      type = (lib.types.attrsOf (lib.types.addCheck lib.types.anything (lib.isType "option"))) // {
        description = "attribute set of (option)";
      };
      description = ''
        Schema for values used to parameterize workflows. 
        These values are available via arguments of a configuration.
      '';
      default = { };
    };

    values = lib.mkOption {
      type = lib.types.submodule' rec {
        modules = {
          options = config.valuesSchema;
        };
        name = "attribute set of (value)";
        description = name;
      };
      description = ''
        Values used to parameterize workflows.
        These values must match the [valuesSchema](#valuesschema).
      '';
      default = { };
    };

    inherit (common.options) actions;

    workflows = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            inherit (common.options) path actions;
            accessors = lib.mkOption {
              type = lib.types.attrsNestedOf lib.types.attrsEmpty;
              default = { };
            };
            jobs = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    inherit (common.options) name;
                    steps = lib.mkOption {
                      type = lib.types.nonEmptyListOf (
                        lib.types.submodule {
                          options = common.options.step // {
                            uses = lib.mkOption {
                              type = lib.types.oneOf [
                                lib.types.nullishOrStringish
                                (lib.types.addCheck (lib.types.attrsOf common.options.action) (
                                  x: builtins.length (builtins.attrNames x) == 1
                                ))
                              ];
                              default = null;
                            };
                          };
                        }
                      );
                      default = [ ];
                    };
                  };
                }
              );
              default = { };
            };
          };
        }
      );
      default = { };
    };
  };

  config = configuration;
}
