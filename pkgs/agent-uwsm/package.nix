{ uwsm }:

assert uwsm.version == "0.27.2";
assert uwsm.src.outputHash == "sha256-CeSK7GrE7ew+3vNwGrif0O7Gxn92SH07Um8k8KzYmgk=";
uwsm.overrideAttrs (old: {
  pname = "agent-uwsm";
  patches = (old.patches or [ ]) ++ [ ./headless.patch ];
  patchFlags = [
    "-p1"
    "--fuzz=0"
  ];
})
