{ lib }:
let
  nonEmptyListOf = elemType: lib.types.nonEmptyListOf elemType // {
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
in
lib.recursiveUpdate lib {
  types = {
    inherit nonEmptyListOf;
  };

  values = {
    inherit null_;
  };

  inherit mapAttrsRecursive';
}
