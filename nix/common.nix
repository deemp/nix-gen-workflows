{ lib }:
rec
{
  types = rec {
    null_Or = elemType: lib.types.nullOr elemType // {
      name = "null_Or";
      description = "null_ or ${lib.types.optionDescriptionPhrase (class: class == "noun" || class == "conjunction") elemType}";
      descriptionClass = "conjunction";
      check = x: x == lib.values.null_ || elemType.check x;
      merge = loc: defs:
        let nrNulls = lib.count (def: def.value == lib.values.null_) defs; in
        if nrNulls == builtins.length defs then lib.values.null_
        else if nrNulls != 0 then
          throw "The option `${lib.showOption loc}` is defined both null_ and not null_, in ${lib.showFiles (lib.getFiles defs)}."
        else elemType.merge loc defs;
      emptyValue = { value = { _type = "null"; }; };
      substSubModules = m: null_Or (elemType.substSubModules m);
    };

    null_OrNullOrStr = null_Or (lib.types.nullOr lib.types.str);
  };

  options = rec {
    str = lib.mkOption {
      type = types.null_OrNullOrStr;
      default = null;
    };

    path = str;

    name = str;

    id = str;

    uses = str;

    alias = str;

    with_ = lib.mkOption {
      type = lib.types.attrsOf types.null_OrNullOrStr;
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
      inherit id name uses with_ alias;
    };

    job = {
      inherit name;
    };
  };

  mkWorkflowsOption = steps: lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        inherit (options) path actions;
        jobs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              inherit (options) name;
              steps = lib.mkOption steps;
            };
          });
          default = { };
        };
      };
    });
    default = { };
  };
}
