{
  l,
  types,
}: cfg: let
  inherit (types) BlockTypes Systems Cell;
  inherit (cfg) cellBlocks systems cellsFrom;
in rec {
  cellBlocks' = let
    unique =
      l.foldl' (
        acc: e:
          if l.elem e.name acc.visited
          then acc
          else {
            visited = acc.visited ++ [e.name];
            result = acc.result ++ [e];
          }
      ) {
        visited = [];
        result = [];
      };
  in
    (unique
      (BlockTypes "paisano/grow/args" cellBlocks))
    .result;
  systems' = Systems "paisano/grow/args" systems;
  cells' = l.mapAttrsToList (Cell cellsFrom cellBlocks') (l.readDir cellsFrom);
}
