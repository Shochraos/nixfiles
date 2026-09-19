{ den, lib, ... }:
{
  den.aspects.ai = {
    __functor =
      self: args:
      let
        allowed = [
          "local"
          "stt"
        ];
        unknown = if builtins.isAttrs args then builtins.attrNames (removeAttrs args allowed) else [ ];
      in
      if !builtins.isAttrs args then
        throw "den.aspects.ai must be called with an argument set, e.g. (ai { stt = true; })"
      else if unknown != [ ] then
        throw "den.aspects.ai: unknown argument(s) ${lib.concatStringsSep ", " unknown} — expected only ${lib.concatStringsSep ", " allowed}"
      else
        {
          includes = [
            self.tools
          ]
          ++ lib.optional (args.local or false) self.local
          ++ lib.optional (args.stt or false) self.stt;
        };

    provides.tools = den.aspects.ai-harness;
    provides.stt = den.aspects.ai-stt;
    provides.local = den.aspects.ai-local;
  };
}
