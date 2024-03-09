{ lib }:
rec {
  options = rec {
    str = lib.mkOption {
      type = lib.types.nullishOrStringish;
      default = null;
    };

    path = str;

    name = str;

    id = str;

    uses = str;

    alias = str;

    with_ = lib.mkOption {
      type = lib.types.attrsOf lib.types.nullishOrStringish;
      default = { };
    };

    action = lib.types.submodule {
      options = {
        inherit name with_;
      };
    };

    actions = lib.mkOption {
      type = lib.types.attrsOf action;
      default = { };
    };

    step = {
      inherit
        id
        name
        uses
        with_
        alias
        ;
    };

    job = {
      inherit name;
    };
  };
}
