{
  l,
  deSystemize,
  paths,
  types,
}: let
  inherit (types) Block Target;
  makeImportSignatureFor = import ./make-import-signature.nix {inherit l deSystemize;};
  makeExtractFor = import ./make-extract.nix {inherit l types paths;};
  makeDebug = import ./make-debug.nix {inherit l;};
  processCfg = import ./make-process-cfg.nix {inherit l types;};
  helpers = import ./make-helpers.nix {inherit l;};
  /*
  A function that 'grows' Cell Blocks from Cells found in 'cellsFrom'.

  This figurative glossary is so non-descriptive, yet fitting, that
  it will be easy to reason about this nomenclature even in a casual
  conversation when not having convenient access to the actual code.

  Essentially, it is a special type of importer, that detects nix &
  some companion files placed in a specific folder structure inside
  your repository.

  The root of that special folder hierarchy is declared via 'cellsFrom'.
  This is a good opportunity to isolate your actual build-relevant source
  code from other repo boilerplate or documentation as a first line measure
  to improve build caching.

  Cell Blocks are the actual typed flake outputs, for convenience, Cell Blocks
  are grouped into Block Types which usually augment a Cell Block with action
  definitions that the std TUI will be able to understand and execute.

  The usual dealings with 'system' are greatly reduced in std. Inspired by
  the ideas known partly as "Super Simple Flakes" in the community, contrary
  to clasical nix, _all_ outputs are simply scoped by system as the first-level
  output key. That's it. Never deal with it again. The 'deSystemize' function
  automatically folds any particular system scope of inputs automatically one
  level up. So, when dealing with inputs, no dealing with 'system' either.

  If you need to crosscompile and know your current system, `inputs.nixpkgs.system`
  always has it. And all other inputs still expose `inputs.foo.system` as a
  fall back. But use your escape hatch wisely. If you feel that you need it and
  you aren't doing cross-compilation, search for the upstream bug.
  It's there! Guaranteed!

  Debugging? You can gain a better understanding of the `inputs` argument by
  declaring the debug attribute for example like so: `debug = ["inputs" "yants"];`.
  A tracer will give you more context about what's in it for you.

  Finally, there are a couple of special inputs:

  - `inputs.cells` - all other cells, deSystemized
  - `inputs.nixpkgs` - an _instatiated_ nixpkgs, configurabe via `nixpkgsConfig`
  - `inputs.self` - the `sourceInfo` (and only that) of the current flake

  Overlays? Go home or file an upstream bug. They are possible, but so heavily
  discouraged that you gotta find out for yourself if you really need to use
  them in a Cell Block. Hint: `.extend`.

  Yes, std is opinionated. Make sure to also meet `alejandra`. 😎

  */
  grow = {
    inputs,
    cellsFrom,
    cellBlocks,
    systems ? [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ],
    debug ? false,
    nixpkgsConfig ? {},
  }: let
    inherit (processCfg {inherit cellBlocks systems cellsFrom;}) systems' cells' cellBlocks';
    inherit (helpers) accumulate optionalLoad;

    _debug = s: attrs:
      if debug == false
      then attrs
      else makeDebug debug s attrs;
    __makeImportSignatureFor = makeImportSignatureFor {inherit inputs nixpkgsConfig;};
    ___extract = makeExtractFor cellsFrom;

    # List of all flake outputs injected by std in the outputs and inputs.cells format
    loadOutputFor = system: let
      __extract = ___extract system;
      # Load a cell, return the flake outputs injected by std
      _makeImportSignatureFor = cell: {
        inputs = _debug "inputs on ${system}" (__makeImportSignatureFor system res.output); # recursion on cells
        inherit cell;
      };
      loadCellFor = cellName: let
        _extract = __extract cellName;
        cPath = paths.cellPath cellsFrom cellName;
        loadCellBlock = cellBlock: let
          oPath = paths.cellBlockPath cellsFrom cellName cellBlock;
          isFile = l.pathExists oPath.file;
          isDir = l.pathExists oPath.dir;
          Target' = path': Target "paisano/import: ${path'}"; # TODO: implement lazy target block type checks
          import' = path': path: let
            # since we're not really importing files within the framework
            # the non-memoization of scopedImport doesn't have practical penalty
            block = Block "paisano/import: ${path'}" (l.scopedImport signature path);
            signature = _makeImportSignatureFor res.output; # recursion on cell
          in
            if l.typeOf block == "set"
            then block
            else block signature;
          imported =
            if isFile
            then Target' oPath.file' (import' oPath.file' oPath.file)
            else if isDir
            then Target' oPath.dir' (import' oPath.dir' oPath.dir)
            else throw "unreachable!";
          # extract instatiates actions and extracts metadata for the __std registry
          extracted = l.mapAttrsToList (_extract cellBlock) imported;
        in
          optionalLoad (isFile || isDir)
          [
            # top level output
            {${cellBlock.name} = imported;}
            # __std.actions (slow)
            {${cellBlock.name} = l.listToAttrs (map (x: x.actions) extracted);}
            # __std.init (fast)
            {
              cellBlock = cellBlock.name;
              blockType = cellBlock.type;
              readme =
                if l.pathExists oPath.readme
                then oPath.readme
                else "";
              targets = map (x: x.init) extracted;
            }
            # __std.ci
            {
              ci = map (x: x.ci) extracted;
            }
            # __std.ci'
            {
              ci' = map (x: x.ci') extracted;
            }
          ];
        res = accumulate (l.map loadCellBlock cellBlocks');
      in [
        # top level output
        {${cellName} = res.output;}
        # __std.actions (slow)
        {${cellName} = res.actions;}
        # __std.init (fast)
        {
          cell = cellName;
          readme =
            if l.pathExists cPath.readme
            then cPath.readme
            else "";
          cellBlocks = res.init; # []
        }
        # __std.ci
        {
          inherit (res) ci;
        }
        # __std.ci'
        {
          inherit (res) ci';
        }
      ]; # };
      res = accumulate (l.map loadCellFor cells');
    in [
      # top level output
      {${system} = res.output;}
      # __std.actions (slow)
      {${system} = res.actions;}
      # __std.init (fast)
      {
        name = system;
        value = res.init;
      }
      # __std.ci
      {
        ci = [
          {
            name = system;
            value = res.ci;
          }
        ];
      }
      # __std.ci'
      {
        ci' = [
          {
            name = system;
            value = res.ci';
          }
        ];
      }
    ];
    res = accumulate (l.map loadOutputFor systems');
  in
    res.output
    // {
      __std.ci = l.listToAttrs res.ci;
      __std.ci' = l.listToAttrs res.ci';
      __std.init = l.listToAttrs res.init;
      __std.actions = res.actions;
      __std.nixConfig = let
        # FIXME: refactor when merged NixOS/nixpkgs#203999
        nixConfig = l.generators.toKeyValue {
          mkKeyValue = l.generators.mkKeyValueDefault {
            mkValueString = v:
              if l.isList v
              then l.concatStringsSep " " v
              else if (l.isPath v || v ? __toString)
              then toString v
              else l.generators.mkValueStringDefault {} v;
          } " = ";
        };
      in
        nixConfig (import "${inputs.self}/flake.nix").nixConfig or {};
    };

  growOn = import ./grow-on.nix {inherit l grow;};
in {inherit grow growOn;}
