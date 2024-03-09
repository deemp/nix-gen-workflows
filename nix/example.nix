{ lib, ... }:
{
  workflows,
  actions,
  qq,
  null_,
  stepsIf,
  values,
  ...
}:
{
  valuesSchema = {
    foo = lib.mkOption {
      type = lib.types.int;
      description = "`foo`";
      default = 4;
    };
  };

  actions = {
    checkout = {
      name = "actions/checkout@v4";
      with_ = {
        repository = "abra";
        filter = "filter";
      };
    };
  };

  workflows = {
    workflow-1 = with workflows.workflow-1.accessors; {
      on.workflow_dispatch = { };
      path = ".github/workflows/action.yaml";
      actions = { };
      accessors = {
        matrix.cadabra = { };
      };
      jobs = {
        a = {
          name = "Hello";
          steps = [
            {
              id = "1";
              uses.checkout = {
                with_ = {
                  filter = "filter-1";
                  abra = null_;
                  cadabra = matrix.cadabra;
                };
              };
            }
            {
              uses = "actions/cache";
              alias = "cache";
            }
            (stepsIf (values == { }) [
              {
                uses = "something-3";
                alias = "something-3";
              }
            ])
            (stepsIf (values.foo == 4) [
              {
                uses = "something-4";
                alias = "something-4";
              }
            ])
          ];
        };

        b = {
          name = qq workflows.workflow-1.jobs.a.name + qq workflows.workflow-1.jobs.a.name;
          steps = [
            {
              name = "hello";
              uses.checkout = {
                with_ = {
                  repository = "abra";
                  filter = null_;
                };
              };
            }
            [
              { uses = workflows.workflow-1.jobs.a.steps."2".uses; }
              { uses = workflows.workflow-1.jobs.a.steps.cache.uses; }
            ]
          ] ++ (workflows.workflow-1.jobs.a.steps [ "cache" ]);
        };
      };
    };

    workflow-2 = {
      on.workflow_dispatch = { };
      path = ".github/workflows/action-2.yaml";

      jobs = {
        a = {
          name = workflows.workflow-1.jobs.b.name;
          steps = [ { id = "1"; } ];
        };
      };
    };
  };
}
