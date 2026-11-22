# Opencode - Setup 

### Create Skills

```bash
mkdir -p ~/.config/opencode/skills/git-release

cat << 'EOF' > ~/.config/opencode/skills/git-release/SKILL.md
---
name: git-release
description: Create consistent releases and changelogs
license: MIT
---

## Workflow
1. Summarize merged PRs since the last tag.
2. Propose a semver bump.
3. Draft release notes and ask before tagging.
EOF
```

### Create Prompts

```bash
mkdir -p ~/.config/opencode/prompts

cat > ~/.config/opencode/prompts/reviewer.txt << 'EOF'
You are a code reviewer. Focus on correctness, security, performance, and maintainability.
Report findings in severity order (high, medium, low), each with file, line, and a suggested fix.
Do not modify files. If the code looks fine, say so briefly.
EOF
```