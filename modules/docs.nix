# MIT - Copyright (c) 2017-2019 Robert Helgesson and Home Manager contributors.
#
# This is an adapted version of the original https://sr.ht/~rycee/nmd/
{ lib
, pkgs
, options
, config
, modulesPath
, ...
}:
let
  cfg = config.modules-docs;

  # Generate some meta data for a list of packages. This is what
  # `relatedPackages` option of `mkOption` lib/options.nix influences.
  #
  # Each element of `relatedPackages` can be either
  # - a string:   that will be interpreted as an attribute name from `pkgs`,
  # - a list:     that will be interpreted as an attribute path from `pkgs`,
  # - an attrset: that can specify `name`, `path`, `package`, `comment`
  #   (either of `name`, `path` is required, the rest are optional).
  mkRelatedPackages =
    let
      unpack = p:
        if builtins.isString p then
          { name = p; }
        else if builtins.isList p then
          { path = p; }
        else
          p;

      repack = args:
        let
          name = args.name or (lib.concatStringsSep "." args.path);
          path = args.path or [ args.name ];
          pkg = args.package or (
            let
              bail = throw "Invalid package attribute path '${toString path}'";
            in
            lib.attrByPath path bail pkgs
          );
        in
        {
          attrName = name;
          packageName = pkg.meta.name;
          available = pkg.meta.available;
        } // lib.optionalAttrs (pkg.meta ? description) {
          inherit (pkg.meta) description;
        } // lib.optionalAttrs (pkg.meta ? longDescription) {
          inherit (pkg.meta) longDescription;
        } // lib.optionalAttrs (args ? comment) { inherit (args) comment; };
    in
    map (p: repack (unpack p));

  mkUrl = root: path: "${root.url}/tree/${root.branch}/${path}";

  # Transforms a module path into a (path, url) tuple where path is relative
  # to the repo root, and URL points to an online view of the module.
  mkDeclaration =
    let
      rootsWithPrefixes = map
        (p: p // { prefix = "${toString p.path}/"; })
        cfg.roots;
    in
    decl:
    let
      root = lib.findFirst
        (x: lib.hasPrefix x.prefix decl)
        null
        rootsWithPrefixes;
    in
    if root == null then
    # We need to strip references to /nix/store/* from the options or
    # else the build will fail.
      { path = lib.removePrefix "${builtins.storeDir}/" decl; url = ""; }
    else
      rec {
        path = lib.removePrefix root.prefix decl;
        url = mkUrl root path;
      };

  # Sort modules and put "enable" and "package" declarations first.
  moduleDocCompare = a: b:
    let
      isEnable = lib.hasPrefix "enable";
      isPackage = lib.hasPrefix "package";
      compareWithPrio = pred: cmp: lib.splitByAndCompare pred lib.compare cmp;
      moduleCmp = compareWithPrio isEnable (compareWithPrio isPackage lib.compare);
    in
    lib.compareLists moduleCmp (map toString a.loc) (map toString b.loc) < 0;

  # Replace functions by the string <function>
  substFunction = x:
    if builtins.isAttrs x then
      lib.mapAttrs (name: substFunction) x
    else if builtins.isList x then
      map substFunction x
    else if builtins.isFunction x then
      "<function>"
    else
      x;

  cleanUpOption = opt:
    let
      applyOnAttr = n: f: lib.optionalAttrs (lib.hasAttr n opt) { ${n} = f opt.${n}; };
    in
    opt
    // applyOnAttr "declarations" (map mkDeclaration)
    // applyOnAttr "example" substFunction
    // applyOnAttr "default" substFunction
    // applyOnAttr "type" substFunction
    // applyOnAttr "relatedPackages" mkRelatedPackages;

  optionsDocs = map cleanUpOption (
    builtins.sort
      moduleDocCompare
      (
        builtins.filter
          (opt: opt.visible && !opt.internal)
          (lib.optionAttrSetToDocList options)
      )
  );

  inherit (import ../nix/commands/lib.nix { inherit pkgs options; })
    mkLocSuffix nestedOptionsType flatOptionsType;

  # TODO: display values like TOML instead.
  toMarkdown = optionsDocs:
    let
      optionsDocsPartitionedIsMain = lib.partition (opt: lib.head opt.loc != "_module") optionsDocs;
      nixMain = optionsDocsPartitionedIsMain.right;
      nixExtra = optionsDocsPartitionedIsMain.wrong;
      concatOpts = opts: (lib.concatStringsSep "\n\n" (map optToMd opts));

      # TODO: handle opt.relatedPackages. What is it for?
      optToMd = opt:
        (let heading = lib.showOption opt.loc; in
        ''
          ## `${heading}`
        ''
        + (lib.optionalString opt.internal "\n**internal**\n")
        + (builtins.toString opt.description)
        + ''

          **Type**:
          
          ```console
          ${opt.type}
          ```
        ''
        + (lib.optionalString (opt?default && opt.default != null) ''
          
          **Default value**:
          
          ```nix
          ${lib.removeSuffix "\n" opt.default.text}
          ```
        '')
        + (lib.optionalString (opt ? example) ''

          **Example value**:
          
          ```nix
          ${lib.removeSuffix "\n" opt.example.text}
          ```
        '')
        + ''

          **Declared in**:

        ''
        + (
          lib.concatStringsSep
            "\n"
            (map
              (decl: "- [${decl.path}](${decl.url})")
              opt.declarations
            )
        ))
      ;

      doc = [
        "# Options\n"
        (concatOpts nixMain)
      ];
    in
    lib.concatStringsSep "\n" doc;
in
{
  options.modules-docs = {
    roots = lib.mkOption {
      internal = true;
      type = lib.types.listOf (lib.types.submodule {
        options =
          let str =
            lib.mkOption {
              type = lib.types.str;
            }; in
          {
            url = str;
            path = str;
            branch = str;
          };
      });
      description = ''
        Add to this list for each new module root. The attr should have path,
        url and branch attributes (TODO: convert to submodule).
      '';
    };

    data = lib.mkOption {
      visible = false;
      type = lib.types.listOf lib.types.attrs;
      description = ''
        Contains a list of each module option, nicely split out for
        consumption.
      '';
    };

    markdown = lib.mkOption {
      visible = false;
      type = lib.types.package;
      description = ''
        Modules documentation rendered to markdown.
      '';
    };
  };

  config.modules-docs = {
    data = optionsDocs;
    markdown = pkgs.writeText "modules-docs.md" (toMarkdown optionsDocs);
  };
}
