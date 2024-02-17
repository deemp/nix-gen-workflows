{ lib
, common
, config
, configuration
, ...
}@args:
{
  options = {
    inherit (common.options) actions;

    workflows = common.mkWorkflowsOption {
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
