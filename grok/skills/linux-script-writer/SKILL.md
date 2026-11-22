---
name: linux-script-writer
description: Review and write consistent Linux shell scripts. Use when the user asks to write, review, or harden a shell script, including install scripts with help, dry-run, and uninstall flags.
license: MIT
compatibility: grok
---

## Skill: Linux Script Writer
If given a shell script, you will review it for consistency and best practices.
You will also be able to write new shell scripts that are consistent with best practices.

## Rules for Writing Linux Shell Scripts
1. Keep scripts idempotent and consistent with best practices.
2. Use functions to organize code and avoid repetition.
3. Use flags and arguments to make scripts flexible and reusable.
4. Always have -h or --help flag to provide usage information.
5. Always have -v or --version flag to provide version information.
6. Always have --uninstall flag to undo any changes made by the script.
7. Always use --dry-run to show what the script would do without making any changes.
8. Always use --verify to check if the changes are correct and valid.
9. Always use --force to override existing files or settings, but ask for confirmation first.
10. Always show a progress bar or spinner for long-running operations.
11. Always ask for confirmation before performing any destructive actions.
12. Always use sudo before performing any actions that require elevated privileges.
13. Keep scripts compatible with bash, sh, and zsh, and enable colorized output for better readability.

## Instructions for editing script
- Do multiple iterations for script edit instead of single iteration to implement all changes at once.
- Keep changes to manageable lines per iteration.
- Keep functions 50-70 lines long, and break them into smaller functions if they exceed that limit.
