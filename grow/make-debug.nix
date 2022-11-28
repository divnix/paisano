{l}: debug: s: attrs: let
  traceString = l.trace s;
  traceAttrs = l.traceSeqN 1 attrs;
  alsoTraceAttrPath = let
    path = l.attrsets.attrByPath debug null attrs;
  in
    (l.trace "path: ${l.concatStringsSep ''.'' debug}") (l.traceSeqN 1 path);
  debugIsAttrPath =
    l.typeOf debug
    == "list"
    && l.attrsets.hasAttrByPath debug attrs;
in
  traceString traceAttrs (
    if debugIsAttrPath
    then alsoTraceAttrPath attrs
    else attrs
  )
