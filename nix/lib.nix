{ lib }:
let
  nestedListOf = elemType: lib.types.listOf (lib.types.either elemType (nestedListOf elemType));
  nonEmptyListOf = elemType:
    let list = lib.types.addCheck (lib.types.coercedTo (nestedListOf elemType) lib.flatten (lib.types.listOf elemType)) (l: l != [ ]); in
    list // {
      description = "arbitrarily nested, non-empty when flattened ${lib.types.optionDescriptionPhrase (class: class == "noun") list}";
      # TODO remove after switching to newer nixpkgs
      substSubModules = m: nonEmptyListOf (elemType.substSubModules m);
    };

  null_ = { type = "null_"; };

  mapAttrsRecursive' =
    f: val: (
      if builtins.isAttrs val
      then
        lib.pipe val [
          (lib.mapAttrs' f)
          (lib.mapAttrs (name: value: mapAttrsRecursive' f value))
        ]
      else if builtins.isList val
      then map (mapAttrsRecursive' f) val
      else val
    );

  maxDepth = 100;

  attrsNestedOf = elemType:
    let elems = lib.genList (_: null) maxDepth; in
    lib.foldl
      (t: _: lib.types.attrsOf (lib.types.either elemType t) // {
        description = "(nested (max depth is ${toString maxDepth}) attribute set of ${
          lib.types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
        })";
      })
      elemType
      elems;

  attrsEmpty =
    lib.types.addCheck
      (lib.types.attrs // { description = "empty attribute set"; })
      (x: builtins.length (lib.attrNames x) == 0);
in
lib.recursiveUpdate lib {
  types = {
    inherit
      nonEmptyListOf
      attrsNestedOf
      attrsEmpty
      ;
  };

  values = {
    inherit null_;
  };

  inherit mapAttrsRecursive';
}
