---
name: linux-script-writer
description: Write consistent Linux shell scripts
license: MIT
---

## Workflow
1. Keep scripts Idempotent and consistent with best practices.
2. Use functions to organize code and avoid repetition.
3. Use flags and arguments to make scripts flexible and reusable.
4. Always have -h or --help flag to provide usage information.
5. Always have -v or --version flag to provide version information.
6. Always have --uninstall flag to undo any changes made by the script.
7. Always show a progress bar or spinner for long-running operations.
8. Always ask for confirmation before performing any destructive actions.
9. Always use sudo before performing any actions that require elevated privileges.
10. Keep scripts compatible with bash, sh, and zsh, and enable colorized output for better readability.