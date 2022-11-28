{
  l,
  yants,
  paths,
}: {
  Cell = import ./cell.nix {
    inherit l;
    inherit (paths) cellPath cellBlockPath;
  };
  Target = log:
    with yants log;
    # unfortunately eval during check can cause infinite recursions
    # if blockType == "runnables" || blockType == "installables"
    # then attrs drv
    # else if blockType == "functions"
    # then attrs function
    # else throw "unreachable";
      attrs any;
  Systems = log: with yants log; list (enum "system" l.systems.doubles.all);
  BlockTypes = log:
    with yants log;
      list (struct "cellBlock" {
        name = string;
        type = string;
        __functor = option function;
        ci = option (attrs bool);
        actions = option (functionWithArgs {
          system = false;
          target = false;
          fragment = false;
          fragmentRelPath = false;
        });
      });
  Block = log:
    with yants log;
      block: (
        if l.typeOf block == "set"
        then attrs any block
        else
          functionWithArgs {
            inputs = false;
            cell = false;
          }
          block
      );
  ActionCommand = with yants "std" "actions"; drv;
}
