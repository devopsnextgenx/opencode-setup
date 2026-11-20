# AGENTS.md

## Code style
- Follow existing patterns in neighboring files before introducing new ones.
- Type hints on all public functions; no `Any` unless justified in a comment.
- Prefer small, pure functions. Keep route handlers thin; put logic in `api/services/`.
- Use `ruff` defaults; don't reformat unrelated code.

## Testing rules
- Every bug fix or new feature needs a test.
- Run the relevant tests after changes and report the result.

## Workflow
- Make the smallest change that solves the task.
- For changes touching more than 3 files, outline a plan first and wait for approval.
- Never commit, push, or tag unless explicitly asked.
- Schema changes require an Alembic migration (`alembic revision --autogenerate -m "msg"`); review it before applying.

## Agents and skills
- Use the `@reviewer` subagent for read-only code review before finishing large changes.
- Load the `git-release` skill when preparing a release or changelog.

## Definition of done
1. Code compiles and lints cleanly.
2. Tests pass (new tests added where relevant).
3. Summary of what changed and anything left unresolved.