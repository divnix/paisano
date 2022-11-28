{
  l,
  paths,
  types,
}: cellsFrom: system: cellName: cellBlock: name: target: let
  tPath = paths.targetPath cellsFrom cellName cellBlock name;
  targetFragment = ''"${system}"."${cellName}"."${cellBlock.name}"."${name}"'';
  actionFragment = action: {
    actionFragment = ''"__std"."actions"."${system}"."${cellName}"."${cellBlock.name}"."${name}"."${action}'';
  };
  actions =
    if cellBlock ? actions
    then
      cellBlock.actions {
        inherit system target;
        fragment = targetFragment;
        fragmentRelPath = "${cellName}/${cellBlock.name}/${name}";
      }
    else [];
  ci =
    if cellBlock ? ci
    then
      l.mapAttrsToList (action: _:
        if ! l.any (a: a.name == action) actions
        then
          throw ''
            divnix/std(ci-integration): Block Type '${cellBlock.type}' has no '${action}' Action defined.
            ---
            ${l.generators.toPretty {} (l.removeAttrs cellBlock ["__functor"])}
          ''
        else {
          inherit name;
          cell = cellName;
          block = cellBlock.name;
          blockType = cellBlock.type;
          inherit action;
          inherit targetFragment;
          inherit (actionFragment action) actionFragment;
        })
      cellBlock.ci
    else [];

  ci' = let
    f = set:
      set
      // {
        actionDrv = actions.${set.action}.drvPath or null;
      };
  in
    map f ci;
in {
  inherit ci ci';
  actions = {
    inherit name;
    value = l.listToAttrs (map (a: {
        inherit (a) name;
        value = types.ActionCommand a.command;
      })
      actions);
  };
  init = {
    inherit name;
    deps = target.meta.after or target.after or [];
    description = target.meta.description or target.description or "n/a";
    readme =
      if l.pathExists tPath.readme
      then tPath.readme
      else "";
    # for speed only extract name & description, the bare minimum for display
    actions = map (a: {inherit (a) name description;}) actions;
  };
}
