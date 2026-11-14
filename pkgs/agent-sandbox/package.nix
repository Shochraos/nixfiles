{
  lib,
  stdenv,
  sandbox-runtime,
  libseccomp,
  renderDevices ? [ ],
}:

let
  validDevice =
    device:
    builtins.isString device
    && builtins.match "/dev/(dri/renderD[0-9]+|nvidia[0-9]+|nvidiactl)" device != null;
  arch =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      "x86_64"
    else if stdenv.hostPlatform.system == "aarch64-linux" then
      "aarch64"
    else
      throw "agent-sandbox supports only x86_64-linux and aarch64-linux";
in
assert builtins.isList renderDevices && builtins.all validDevice renderDevices;
assert builtins.length (lib.unique renderDevices) == builtins.length renderDevices;
assert stdenv.buildPlatform.system == stdenv.hostPlatform.system;
assert sandbox-runtime.version == "0.0.83";
assert sandbox-runtime.src.outputHash == "sha256-t+Xky8dJXu11C9Zdl2dAWl5FryYGbZDTdxVTm3xOfNc=";
sandbox-runtime.overrideAttrs (old: {
  pname = "agent-sandbox";
  patches = (old.patches or [ ]) ++ [
    ./runtime.patch
    ./seccomp.patch
    ./worker-bootstrap.patch
  ];
  buildInputs = (old.buildInputs or [ ]) ++ [ libseccomp ];
  postPatch = (old.postPatch or "") + ''
    file=src/sandbox/linux-sandbox-utils.ts
    test "$(grep -o '@AGENT_SANDBOX_HELPER@' "$file" | wc -l)" -eq 4
    test "$(grep -o '@AGENT_SANDBOX_RENDER_DEVICES@' "$file" | wc -l)" -eq 1
    substituteInPlace "$file" \
      --replace-fail '@AGENT_SANDBOX_HELPER@' "$out/libexec/agent-sandbox/apply-seccomp" \
      --replace-fail '@AGENT_SANDBOX_RENDER_DEVICES@' '${builtins.toJSON renderDevices}'
  '';
  preBuild = (old.preBuild or "") + ''
    mkdir -p agent-seccomp
    cc -O2 -Wall -Wextra -o agent-seccomp/generator vendor/seccomp-src/seccomp-unix-block.c -lseccomp
    agent-seccomp/generator agent-seccomp/unix.bpf ${arch} unix
    agent-seccomp/generator agent-seccomp/namespaces.bpf ${arch} namespaces
    node -e '
      const fs = require("node:fs");
      const array = (name, file) => {
        const bytes = fs.readFileSync(file);
        const lines = [];
        for (let i = 0; i < bytes.length; i += 8)
          lines.push("    " + Array.from(bytes.subarray(i, i + 8), b => "0x" + b.toString(16).padStart(2, "0")).join(", ") + ",");
        return "static const unsigned char " + name + "[] = {\n" + lines.join("\n") + "\n};\n";
      };
      fs.writeFileSync("agent-seccomp/unix-block-bpf.h",
        "#if defined(__${arch}__)\n" +
        array("unix_block_bpf", "agent-seccomp/unix.bpf") +
        array("namespace_block_bpf", "agent-seccomp/namespaces.bpf") +
        "#else\n#error \"these filters were generated for another architecture\"\n#endif\n");
    '
    cc -O2 -Wall -Wextra -I agent-seccomp -o agent-seccomp/apply-seccomp vendor/seccomp-src/apply-seccomp.c
  '';
  postInstall = (old.postInstall or "") + ''
    install -Dm755 agent-seccomp/apply-seccomp "$out/libexec/agent-sandbox/apply-seccomp"
  '';
  meta = old.meta // {
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
