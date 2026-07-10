{lib}: let
  startsIdentChar = s: builtins.match "[A-Za-z0-9_].*" s != null;

  # Split on the literal `$DNVR_ROOT`, re-attaching any occurrence that
  # continues into an identifier ($DNVR_ROOT_DIR, $DNVR_ROOTS) back onto the
  # preceding literal part — those name *other* variables and must stay
  # verbatim. The result alternates literal parts around real expansions.
  rootParts = v:
    lib.foldl' (
      acc: part:
        if acc == []
        then [part]
        else if startsIdentChar part
        then lib.init acc ++ ["${lib.last acc}$DNVR_ROOT${part}"]
        else acc ++ [part]
    ) []
    (lib.splitString "$DNVR_ROOT" (toString v));
in {
  # Render an `export K=V` line where `$DNVR_ROOT` in V is left for the
  # executing shell to expand; everything else — including any other `$` — is
  # escaped verbatim. This is what lets eval stay pure while values carry
  # location-dependent paths: the expansion happens wherever the export runs
  # (shellHook, runner, wrapper), where DNVR_ROOT is live. Exactly
  # `$DNVR_ROOT` at an identifier boundary is special; no other variable is
  # expanded.
  exportLine = k: v:
    "export ${k}="
    + lib.concatStringsSep "\"$DNVR_ROOT\"" (map lib.escapeShellArg (rootParts v));

  refersToRoot = v: builtins.length (rootParts v) > 1;
}
