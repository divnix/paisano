{l}: {
  accumulate =
    l.foldl'
    (
      acc: new: let
        first = l.head new;
        second = l.head cdr;
        third = l.head cdr';
        fourth = l.head cdr_;
        tail = l.tail cdr_;

        cdr = l.tail new;
        cdr' = l.tail cdr;
        cdr_ = l.tail cdr';
      in
        (
          if first == null
          then {inherit (acc) output;}
          else {output = acc.output // first;}
        )
        // (
          if second == null
          then {inherit (acc) actions;}
          else {actions = acc.actions // second;}
        )
        // (
          if third == null
          then {inherit (acc) init;}
          else {init = acc.init ++ [third];}
        )
        // (
          if fourth == null
          then {inherit (acc) ci;}
          else {ci = acc.ci ++ (l.concatMap (t: l.flatten t.ci) [fourth]);}
        )
        // (
          if tail == [null]
          then {inherit (acc) ci';}
          else {ci' = acc.ci' ++ (l.concatMap (t: l.flatten t.ci') tail);}
        )
    )
    {
      output = {};
      actions = {};
      init = [];
      ci = [];
      ci' = []; # with drv (eval-costly)
    };

  optionalLoad = cond: elem:
    if cond
    then elem
    else [
      null # empty output
      null # empty action
      null # empty init
      null # empty ci
      null # empty ci'
    ];
}
