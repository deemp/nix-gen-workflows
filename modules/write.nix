{ lib
, pkgs
, config
, ...
}:
{
  options = {
    write = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
    };
  };
  config = {
    write = lib.pipe config.workflows [
      (lib.filterAttrs (name: value: value.path != null))
      (lib.mapAttrs (name: value:
        let
          name' = (lib.strings.escapeNixIdentifier name);
          generate = (pkgs.formats.yaml { }).generate name' config.clean.normalized.${name};
          path = value.path;
        in
        pkgs.writeShellScriptBin name' ''
          mkdir -p "$(dirname ${path})"
          cp ${generate} "${path}"
          chmod +w "${path}"
        ''))
    ];
  };
}
