{ lib }:
let
  maxDepth = 100;

  nestedListOf =
    elemType:
    let
      elems = lib.genList (_: null) maxDepth;
    in
    lib.foldl (
      t: _:
      lib.types.listOf (lib.types.either elemType t)
      // {
        description = "nested (max depth is ${toString maxDepth}) list of ${
          lib.types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
        }";
      }
    ) elemType elems;

  nonEmptyListOf =
    elemType:
    let
      list = lib.types.addCheck (lib.types.coercedTo (nestedListOf elemType) lib.flatten (
        lib.types.nonEmptyListOf elemType
      )) (l: l != [ ]);
    in
    list
    // {
      description = "nested (max depth is ${toString maxDepth}) non-empty when flattened list of ${
        lib.types.optionDescriptionPhrase (class: class == "noun") elemType
      }";
      substSubModules = m: nonEmptyListOf (elemType.substSubModules m);
    };

  null_ = {
    type = "null_";
  };

  null_Or =
    elemType:
    lib.types.nullOr elemType
    // {
      name = "null_Or";
      description = "null_ or ${
        lib.types.optionDescriptionPhrase (class: class == "noun" || class == "conjunction") elemType
      }";
      descriptionClass = "conjunction";
      check = x: x == null_ || elemType.check x;
      merge =
        loc: defs:
        let
          nrNulls = lib.count (def: def.value == null_) defs;
        in
        if nrNulls == builtins.length defs then
          null_
        else if nrNulls != 0 then
          throw "The option `${lib.showOption loc}` is defined both null_ and not null_, in ${lib.showFiles (lib.getFiles defs)}."
        else
          elemType.merge loc defs;
      emptyValue = {
        value = {
          _type = "null";
        };
      };
      substSubModules = m: null_Or (elemType.substSubModules m);
    };

  nullishOr = type: null_Or (lib.types.nullOr type);

  stringish = lib.types.coercedTo (lib.types.addCheck lib.types.attrs (
    x: x ? __toString
  )) builtins.toString lib.types.str;

  nullishOrStringish = nullishOr stringish;

  mapAttrsRecursive' =
    f: val:
    (
      if builtins.isAttrs val then
        lib.pipe val [
          (lib.mapAttrs' f)
          (lib.mapAttrs (_: value: mapAttrsRecursive' f value))
        ]
      else if builtins.isList val then
        map (mapAttrsRecursive' f) val
      else
        val
    );

  attrsNestedOf =
    elemType:
    let
      elems = lib.genList (_: null) maxDepth;
    in
    lib.foldl (
      t: _:
      lib.types.attrsOf (lib.types.either elemType t)
      // {
        description = "nested (max depth is ${toString maxDepth}) attribute set of ${
          lib.types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
        }";
      }
    ) elemType elems;

  attrsEmpty = lib.types.addCheck (lib.types.attrs // { description = "empty attribute set"; }) (
    x: x == { }
  );

  submodule' =
    {
      modules,
      name ? "submodule",
      description,
    }:
    lib.types.submoduleWith {
      shorthandOnlyDefinesConfig = true;
      modules = lib.toList modules;
      inherit name description;
    };

  strOneOf = types: lib.types.addCheck lib.types.str (x: builtins.elem x types);
in
lib.recursiveUpdate lib {
  types = {
    inherit
      attrsEmpty
      attrsNestedOf
      nonEmptyListOf
      null_Or
      nullishOr
      nullishOrStringish
      stringish
      strOneOf
      submodule'
      ;
  };

  values = {
    inherit null_;
  };

  inherit mapAttrsRecursive';
}
