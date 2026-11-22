---
name: grok-author
description: Writes Grok skills (SKILL.md), agents, and config.toml from a plain-language description. Use whenever the user wants to create, draft, improve, rewrite, or review a Grok skill, agent, or coding-agent config, even if they never name the file type.
license: MIT
compatibility: grok
---

# Grok Author

Turn a user's description into well-formed Grok skills, agents, and config, saved in this repo's `grok/` tree. Read the workflow once, then follow it in order.

## Repo layout

`grok/scripts/install_grok.sh` copies this tree to `~/.grok/`. Only these locations are picked up:

```
grok/agents/<agent-name>.md       one file per agent (file name = agent name)
grok/skills/<skill-name>/SKILL.md one folder per skill (SKILL.md in capitals)
grok/config.toml                  user config (models, MCP, UI, subagent models)
```

Do not create files elsewhere. Grok discovers `skills/` and `agents/` under `~/.grok/` after install. A project `.grok/config.toml` does not load `[models]` or `[ui]`.

## Step 1: Decide what to build

| The user wants... | Build |
|---|---|
| A persona with its own model or permission mode | Agent |
| Reusable know-how any session can load | Skill |
| Endpoint, MCP, or UI defaults | `config.toml` |
| A one-off instruction | Answer in chat |

If the request spans several, build skill, then agent, then config. If the description is ambiguous, choose the most likely reading, say which you chose in one line, and proceed.

## Step 2: Gather context

1. Extract the goal, who invokes it, the inputs, the expected output, and hard constraints.
2. Read `grok/agents`, `grok/skills`, and `grok/config.toml`. Match existing names and tone. Do not overwrite a file without telling the user.
3. Name: lowercase letters and digits with single hyphens, at most 64 characters, matching `^[a-z0-9]+(-[a-z0-9]+)*$`.

## Step 3: Write the artifact

State the role and the goal first, then the steps in order. Define the output format. Say when to stop and when to ask.

### Skill: `grok/skills/<name>/SKILL.md`

`name` must equal the folder name. `description` says what the skill does and which phrases should trigger it.

```markdown
---
name: git-release
description: Creates consistent releases and changelogs. Use when the user asks to cut a release, bump a version, tag, or write release notes.
license: MIT
compatibility: grok
---

# Git Release

## Workflow
1. ...
```

### Agent: `grok/agents/<name>.md`

The file name is the agent name. Frontmatter is config. The body is the system prompt.

```markdown
---
name: reviewer
description: Reviews changes for bugs and security issues without editing files.
model: legion
permission_mode: plan
---

You are a code reviewer. ...
```

- `description`: what it does and when to use it.
- `model`: catalog key from `config.toml`, such as `legion`. Omit it to inherit the session model.
- `permission_mode`: `plan` for read-only review, `default` when the agent must edit.
- Grant the least access that does the job. A reviewer does not edit. A refactorer may edit and still works in small steps.

For a subagent, say exactly what it returns. The caller only sees that final message.

### Config: `grok/config.toml`

Add or change only the needed keys. Keep existing tables. Valid homes:

- `[model.<id>]` and `[models]` for the local endpoint (`base_url`, `context_window`, `max_completion_tokens`).
- `[mcp_servers.<name>]` with `command`, `args`, `env`, `cwd`, and `enabled`.
- `[ui] show_thinking_blocks` for visible reasoning.
- `[subagents.models]` to pin an agent to a catalog key.

## Step 4: Validate

1. Name matches the regex and the file or folder name.
2. Frontmatter is valid YAML, begins on line 1, and includes `name` and `description`.
3. `config.toml` parses: `python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' grok/config.toml`.
4. Read the prompt once as the receiving model. It should be able to act without further questions.

## Step 5: Report

Reply briefly with the paths created or changed, how to call the agent or skill, and how to install: `./grok/scripts/install_grok.sh --dry-run`, then `./grok/scripts/install_grok.sh --force --verify`. Name any assumption the user should confirm.
