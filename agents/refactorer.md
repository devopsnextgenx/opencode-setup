---
description: Refactors code according to instructions by breaking tasks into small, manageable edits and executing them iteratively. Use it when you need to improve code structure, update syntax, or implement a refactor plan.
mode: subagent
model: llama-local/legion
temperature: 0.1
permission:
  edit: allow
  bash: ask
  skill:
    "git-*": allow
---
