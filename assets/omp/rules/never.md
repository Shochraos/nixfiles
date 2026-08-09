---
alwaysApply: true
---

# Never

- Never run `git commit` or `git push` unless the user explicitly asks for it in
  this turn. Reading history with `git diff`, `git log` or `git rev-parse` is
  always fine, and so is `git add -N` when a build system only sees tracked
  files.
- Never read decrypted secret values, not even to verify that a template
  renders. Reference secrets indirectly and verify structurally instead:
  placeholder markers, manifest entries, file modes.
- Never add explanatory inline comments. Prefer self-documenting names and
  intermediate bindings. Docstrings and API documentation comments are exempt —
  write those where the language or the project uses them. Match the comment
  conventions already present in a file, and never remove a pre-existing
  comment unless asked.
