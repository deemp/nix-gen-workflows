{ lib
, common
, config
, configuration
, ...
}@args:
{
  options = {
    inherit (common.options) actions;

    workflows = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          inherit (common.options) path actions;
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
                                (lib.types.attrsOf common.options.action)
                                //
                                {
                                  check = x:
                                    builtins.isAttrs x
                                    && builtins.length (builtins.attrValues x) == 1;
                                }
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
