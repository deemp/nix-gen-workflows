{ lib }:
rec
{
  qq = x: "\${{ ${builtins.toString x} }}";

  stepsIf = cond: steps: if cond then steps else [ ];

  convertUses = x:
    x
    //
    (
      lib.optionalAttrs
        (x?uses && builtins.isAttrs x.uses)
        (
          let uses = builtins.head (builtins.attrValues x.uses); in
          {
            uses = uses.name or null;
            with_ = (x.with_ or { }) // (uses.with_ or { });
          }
        )
    );

  removeNulls = lib.filterAttrsRecursive (_: value: value != null);

  removeAliases = lib.filterAttrsRecursive (name: _: name != "alias");

  convertNull_s =
    lib.mapAttrs
      (_: value:
        if value == lib.values.null_
        then null
        else if builtins.isList value
        then map convertNull_s value
        else if builtins.isAttrs value
        then convertNull_s value
        else value
      );

  resolveWorkflows = { config, stepsPipe ? [ ], doMakeAccessors ? false }:
    lib.pipe config.workflows [
      (lib.mapAttrs
        (_: workflow:
          workflow
          //
          (
            let actions = lib.recursiveUpdate config.actions (workflow.actions or { }); in
            {
              inherit actions;
              jobs =
                lib.mapAttrs
                  (_: job:
                    job
                    //
                    {
                      steps =
                        lib.pipe job.steps (
                          [
                            (map
                              (x:
                                lib.pipe x [
                                  removeNulls
                                  convertNull_s
                                  (x:
                                    if x?uses && builtins.isAttrs x.uses then
                                      x
                                      //
                                      (
                                        let
                                          action = builtins.head (builtins.attrNames x.uses);
                                          actions' = lib.recursiveUpdate actions x.uses;
                                        in
                                        {
                                          uses.${action} = actions'.${action};
                                        }
                                      )
                                    else x
                                  )
                                  convertUses
                                ]
                              )
                            )
                          ]
                          ++
                          stepsPipe
                        );
                    })
                  workflow.jobs;
            }
          )
        ))
    ];

  cleanJobs = workflow:
    workflow
    //
    {
      jobs =
        lib.mapAttrs
          (
            _: value: value // {
              steps = lib.pipe value.steps [
                (builtins.filter (x: x != { }))
                (map convertUses)
                (map removeNulls)
                (map removeAliases)
                (map (x: if (x.with_ or { }) == { } then builtins.removeAttrs x [ "with_" ] else x))
              ];
            }
          )
          workflow.jobs;
    };

  cleanWorkflows =
    lib.mapAttrs (_: workflow:
      lib.pipe workflow [
        (x: builtins.removeAttrs x [ "actions" "path" "accessors" ])
        cleanJobs
        convertNull_s
        removeNulls
      ]
    );
}
