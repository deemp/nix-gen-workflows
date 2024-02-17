{ lib }:
rec
{
  types = rec {
    # from nixpkgs
    null_Or = elemType: with lib; with lib.types; with lib.values; mkOptionType rec {
      name = "null_Or";
      description = "null_ or ${optionDescriptionPhrase (class: class == "noun" || class == "conjunction") elemType}";
      descriptionClass = "conjunction";
      check = x: x == null_ || elemType.check x;
      merge = loc: defs:
        let nrNulls = count (def: def.value == null_) defs; in
        if nrNulls == builtins.length defs then null_
        else if nrNulls != 0 then
          throw "The option `${showOption loc}` is defined both null_ and not null_, in ${showFiles (getFiles defs)}."
        else elemType.merge loc defs;
      emptyValue = { value = { _type = "null"; }; };
      getSubOptions = elemType.getSubOptions;
      getSubModules = elemType.getSubModules;
      substSubModules = m: null_Or (elemType.substSubModules m);
      functor = (defaultFunctor name) // { wrapped = elemType; };
      nestedTypes.elemType = elemType;
    };

    null_OrNullOrStr = null_Or (lib.types.nullOr lib.types.str);

    # node = elemType: with lib; with lib.types; with lib.values; mkOptionType rec {
    #   name = "node";
    #   description = "node of type ${optionDescriptionPhrase (class: class == "noun" || class == "conjunction") elemType}";
    #   descriptionClass = "conjunction";
    #   check = x: x.type == "node" || elemType.check x.value;
    #   merge = loc: defs:
    #     let nrNulls = count (def: def.value == null_) defs; in
    #     if nrNulls == builtins.length defs then null_
    #     else if nrNulls != 0 then
    #       throw "The option `${showOption loc}` is defined both null_ and not null_, in ${showFiles (getFiles defs)}."
    #     else elemType.merge loc defs;
    #   emptyValue = { value = { _type = "null"; }; };
    #   getSubOptions = elemType.getSubOptions;
    #   getSubModules = elemType.getSubModules;
    #   substSubModules = m: node (elemType.substSubModules m);
    #   functor = (defaultFunctor name) // { wrapped = elemType; };
    #   nestedTypes.elemType = elemType;
    # };

    # node = lib.types.either null_OrNullOrStr;
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
