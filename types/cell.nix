{
  l,
  cellPath,
  cellBlockPath,
}: cellsFrom: cellBlocks: cell: type: let
  cPath = cellPath cellsFrom cell;
  path = o: cellBlockPath cellsFrom cell o;
  atLeastOneCellBlock = l.any (x: x) (
    l.map (
      o: l.pathExists (path o).file || l.pathExists (path o).dir
    )
    cellBlocks
  );
in
  if type != "directory"
  then
    abort ''


      Everything under ''${cellsFrom}/* is considered a Cell

      Cells are directories by convention and therefore
      only directories are allowed at ''${cellsFrom}/*

      Please remove ${"'"}''${cellsFrom}/${cell}' and don't forget to add the change to version control.
    ''
  else if !atLeastOneCellBlock
  then
    abort ''


      For Cell '${cell}' to be useful
      it needs to provide at least one Cell Block

      In this project, the Cell Blocks can be
      ${l.concatStringsSep ", " (l.map (o: o.name) cellBlocks)}


      ${
        l.concatStringsSep "\n\n" (
          l.map (
            cellBlock: let
              title = "To generate output for Cell Block '${cellBlock.name}', please create:\n";
              paths = "  - ${(path cellBlock).file'}; or\n  - ${(path cellBlock).dir'}";
            in
              title + paths
          )
          cellBlocks
        )
      }

      Please create at least one of the previous files and don't forget to add them to version control.
    ''
  else cell
