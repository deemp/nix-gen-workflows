{ lib
, common
, config
, configuration
, options
, ...
}@args:
{
  options = {
    valuesSchema = lib.mkOption {
      type = lib.types.attrsOf (lib.types.addCheck lib.types.anything (lib.isType "option"));
      default = configuration.valuesSchema or { };
    };

    values = lib.mkOption {
      type = lib.types.submodule { options = options.valuesSchema.default; };
      default =
        lib.recursiveUpdate
          (lib.mapAttrs (name: value: value.default or null) (options.valuesSchema.default or { }))
          (configuration.values or { });
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

  config = {

    inherit (configuration) actions;
    workflows = lib.mapAttrs
      (_: workflow:
        workflow
        //
        {
          jobs = lib.mapAttrs
            (_: job:
              job
              //
              {
                steps = lib.flatten (job.steps or [ ]);
              }
            )
            (workflow.jobs or { });
        }
      )
      (configuration.workflows or { });
  };
}
