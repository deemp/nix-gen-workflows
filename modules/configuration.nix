{ lib
, common
, config
, configuration
, options
, ...
}:
{
  options = {
    valuesSchema = lib.mkOption {
      type =
        (lib.types.attrsOf (lib.types.addCheck lib.types.anything (lib.isType "option")))
        //
        {
          description = "attribute set of options";
        };
      description = "Schema for user-supplied values.";
      default = { };
    };

    values = lib.mkOption {
      type =
        lib.types.submodule' rec {
          modules = { options = config.valuesSchema; };
          name = "attrset of values that match `valuesSchema` options";
          description = name;
        };
      description = "User-supplied values.";
      default = { };
    };

    inherit (common.options) actions;

    workflows = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          inherit (common.options) path actions;
          accessors = lib.mkOption {
            type = lib.types.attrsNestedOf lib.types.attrsEmpty;
            default = { };
          };
          jobs = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                inherit (common.options) name;
                steps = lib.mkOption {
                  type =
                    lib.types.nonEmptyListOf (lib.types.submodule {
                      options =
                        common.options.step
                        //
                        {
                          uses = lib.mkOption {
                            type = lib.types.oneOf [
                              common.types.null_OrNullOrStr
                              (
                                lib.types.addCheck
                                  (lib.types.attrsOf common.options.action)
                                  (x: builtins.length (builtins.attrNames x) == 1)
                              )
                            ];
                            default = null;
                          };
                        };
                    });
                  default = [ ];
                };
              };
            });
            default = { };
          };
        };
      });
      default = { };
    };
  };

  config = configuration;
}
