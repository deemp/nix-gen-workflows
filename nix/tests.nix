{ example }:
{
  testPass = {
    expr = example.config.clean;
    expected = {
      workflow-1 = {
        jobs = {
          a = {
            name = "Hello";
            steps = [
              {
                id = "1";
                uses = "actions/checkout@v4";
                with_ = {
                  filter = "filter-1";
                  repository = "abra";
                };
              }
              {
                uses = "actions/cache";
              }
            ];
          };
          b = {
            name = "\${{ Hello }}\${{ Hello }}";
            steps = [
              {
                name = "hello";
                uses = "actions/checkout@v4";
                with_ = {
                  repository = "abra";
                };
              }
              {
                uses = "actions/cache";
              }
            ];
          };
        };
      };
      workflow-2 = {
        jobs = {
          a = {
            name = "\${{ Hello }}\${{ Hello }}";
            steps = [
              {
                id = "1";
              }
            ];
          };
        };
      };
    };
  };
}
