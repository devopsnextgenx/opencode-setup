---
name: opencode-author
description: Writes OpenCode prompts, skills (SKILL.md) and agents from a plain-language description. Use whenever the user wants to create, draft, improve, rewrite or review a system prompt, a prompt file, an agent or subagent definition (agents/*.md), or a skill, or says things like "make me an agent that...", "write a skill for...", "I need a prompt for...", or "turn this workflow into a skill", even if they never name the file type. Puts the files in this repo's prompts/, skills/ and agents/ folders in the format OpenCode expects.
license: MIT
compatibility: opencode
---

# OpenCode Author

Turn a user's description into well-formed OpenCode prompts, skills and agents, saved in the right folder with the right frontmatter. Read the whole workflow once, then follow it in order.

## Repo layout

This repo is installed to `~/.config/opencode/` by `scripts/install_opencode.sh`, so only these locations are picked up:

```
agents/<agent-name>.md          one file per agent (file name = agent name)
skills/<skill-name>/SKILL.md    one folder per skill (SKILL.md in capitals)
prompts/<prompt-name>.md        shared prompt text, referenced from opencode.json
opencode.json                   global config
```

Do not create files elsewhere (such as `commands/`), because the installer will not copy them.

## Step 1: Decide what to build

Pick the smallest artifact that fits. If the request spans several, build them in this order: prompt, skill, agent.

| The user wants... | Build | Why |
|---|---|---|
| A persona or standing behavior with its own tools, permissions or model | **Agent** | Agents own permissions and mode; skills and prompts do not |
| Reusable know-how or a procedure any agent can load on demand | **Skill** | Loaded only when relevant, so it costs no context otherwise |
| Long or shared system-prompt text used by one or more agents via `opencode.json` | **Prompt file** | Keeps `opencode.json` readable and lets agents share text |
| A one-off instruction | Just answer in chat | Nothing needs saving |

If the description is ambiguous, choose the most likely reading, say which you chose in one line, and proceed. Ask a question only when a wrong guess would waste real effort (for example, whether an agent may edit files or run shell commands).

## Step 2: Gather context

1. Extract from the description: the goal, who or what invokes it, the inputs, the expected output, and any hard constraints.
2. Look at what already exists with `ls agents skills prompts` and read `AGENTS.md` and `opencode.json`. Match the repo's existing naming and tone, and never overwrite an existing file without telling the user.
3. Choose a name: lowercase letters and digits with single hyphens, at most 64 characters, matching `^[a-z0-9]+(-[a-z0-9]+)*$`. Prefer a verb-noun or role name (`code-reviewer`, `release-notes`) over a vague one (`helper`).

## Step 3: Write the artifact

### Writing any prompt (applies to all three types)

- State the role and the goal in the first lines, then the context and the reason for the task. A model that knows why can handle cases the prompt did not anticipate.
- Be direct and specific. Say what to do, in the order to do it, rather than listing what to avoid. Where a prohibition is needed, give the reason.
- Define the output: format, length, and where it should be written. Show one short example when the format is non-obvious.
- Say when to stop and when to ask the user, so the agent neither guesses silently nor asks needlessly.
- Use plain headings or lists for structure. Avoid ALL CAPS and stacked "never/always" rules, which cause over-literal behavior.
- Keep it as short as the task allows. Cut anything the model would do correctly without being told.

### Skill: `skills/<name>/SKILL.md`

Frontmatter fields OpenCode reads: `name` (required), `description` (required, 1 to 1024 characters), `license`, `compatibility`, `metadata` (string-to-string map). Unknown fields are ignored. `name` must equal the folder name.

```markdown
---
name: git-release
description: Creates consistent releases and changelogs. Use when the user asks to cut a release, bump a version, tag, or write release notes, even if they do not say "release".
---

# Git Release

## Workflow
1. ...
```

Rules:
- The `description` is the only thing agents see before loading the skill, so it must say what the skill does and list the situations and phrases that should trigger it. Lean slightly pushy, because agents tend to under-use skills.
- Put "when to use" information in the description, not in the body.
- Write the body as imperative steps with the reasoning behind them. Keep it under 500 lines.
- Move bulky material into siblings and point to them from the body with a note on when to read them: `references/` for docs, `scripts/` for deterministic code, `assets/` for templates.
- Quote YAML values that contain a colon.

### Agent: `agents/<name>.md`

The file name is the agent name, the frontmatter is its config, and the Markdown body is its system prompt.

```markdown
---
description: Reviews changes for bugs and security issues without editing files. Use after code is written or before merging.
mode: subagent
temperature: 0.1
steps: 20
permission:
  edit: deny
  bash:
    "*": deny
    "git diff*": allow
    "git log*": allow
  webfetch: deny
---

You are a code reviewer. ...
```

Fields:
- `description` (required): what it does and when to use it. Subagents are chosen by this text.
- `mode`: `primary` (user switches to it), `subagent` (invoked by other agents or with `@name`), or `all`.
- `model`: `provider/model-id`. Omit it unless the user asks, so the agent inherits the session model.
- `temperature`: low (0 to 0.2) for analysis and code, higher for brainstorming.
- `steps`: cap on agentic iterations, useful for narrow subagents.
- `permission`: `edit`, `bash`, `webfetch`, `skill` and others, each `allow`, `ask` or `deny`. `bash` also takes a map of command patterns. Add `skill: { "name": allow }` to let the agent load a specific skill.
- `hidden`, `color`: optional display options.

Grant the least privilege that does the job:

| Archetype | edit | bash | webfetch |
|---|---|---|---|
| Reviewer or auditor | deny | deny, or allow read-only git commands | deny |
| Researcher | deny | deny | allow |
| Planner | deny | ask | allow |
| Builder | allow | ask, with safe commands allowed | ask |
| Docs writer | allow | deny | ask |

Body structure that works: role and goal, what to do step by step, what to hand back and in what format, and when to stop or ask. For a subagent, say exactly what it returns, because the calling agent only sees that final message.

### Prompt file: `prompts/<name>.md`

Create one only when the text is long or shared. Reference it from `opencode.json`:

```json
{
  "agent": {
    "my-agent": {
      "description": "...",
      "mode": "primary",
      "prompt": "{file:./prompts/my-agent.md}"
    }
  }
}
```

Edit `opencode.json` surgically: add or change only the needed entry, keep existing keys, and keep it valid JSON. For an agent that lives in `agents/<name>.md`, put the prompt in the body instead and skip this step.

## Step 4: Validate

Before reporting, check each item and fix failures:

1. Name matches the regex and the file or folder name. Skill folder contains exactly `SKILL.md`.
2. Frontmatter is valid YAML, begins on line 1, and has all required fields. Description is within 1024 characters for skills.
3. Permissions follow least privilege and match the archetype. Nothing is `allow` that the description does not require.
4. Every path mentioned exists, and any `{file:...}` reference resolves.
5. `opencode.json` still parses, for example with `python3 -m json.tool opencode.json >/dev/null` or `jq empty opencode.json`.
6. Read the prompt once as the receiving model: could it act without further questions?

## Step 5: Report

Reply briefly with:
- The files created or changed, as paths.
- How to use them: switch to a primary agent with Tab, call a subagent with `@name`, and skills load automatically when the description matches or through the `skill` tool.
- How to install: `./scripts/install_opencode.sh --dry-run`, then `./scripts/install_opencode.sh --force --verify`.
- Any assumption you made that the user should confirm.

## Version note

OpenCode v1 uses the `permission:` map shown above. OpenCode v2 documents `permissions:` as an ordered list of `{action, resource, effect}` rules and a `system` field. If the installed version is v2 (check `opencode --version` or the existing agents in this repo), follow the format already used in `agents/` and see https://opencode.ai/docs for the current schema.

## Example

User: "I want an agent that reviews my shell scripts for portability and safety."

Result:
- `agents/shell-reviewer.md` with `mode: subagent`, `edit: deny`, read-only bash, and a body covering POSIX portability, quoting, `set -eu`, unsafe `rm` and `curl | sh`, and a findings-by-severity output format.
- No skill or prompt file, because nothing needs sharing.
- Reply: the path, "call it with `@shell-reviewer`", and the assumption that it should not edit files.
