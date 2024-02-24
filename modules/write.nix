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
    write =
      let
        workflowWriters = lib.pipe config.workflows [
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
      in
      workflowWriters
      //
      {
        all = lib.pipe workflowWriters [
          (lib.mapAttrsToList (_: value: lib.getExe value))
          (lib.concatStringsSep "\n")
          (pkgs.writeShellScriptBin "all")
        ]
        ;
      };
  };
}
