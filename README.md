# 🧠 ai-skills

A curated, open-source collection of **skills for AI coding agents** — structured Markdown instructions that guide AI assistants (Claude, Cursor, Copilot, etc.) to perform specialized tasks with greater precision, consistency, and quality.

> Think of skills as **reusable playbooks** your AI agent follows when tackling specific workflows — from writing technical worklogs to generating production-grade UI, processing documents, managing health records, and more.

---

## What is a Skill?

A **skill** is a folder containing a `SKILL.md` file (plus optional templates, scripts, and assets) that an AI agent reads before tackling a specific type of task. Instead of re-explaining your preferences and workflow every time, you install a skill once and the agent knows exactly how to behave.

```
my-skill/
├── SKILL.md              ← Core instructions for the agent
├── templates/            ← Reusable output templates
├── references/           ← Domain-specific reference docs
└── assets/               ← Supporting files (icons, fonts, etc.)
```

Each skill has:
- A clear **trigger description** — so the agent knows when to use it
- Step-by-step **instructions** — reducing ambiguity and hallucination
- **Output templates** — ensuring consistent, high-quality results

---

## Skill Categories

| Category | Description |
|---|---|
| 📝 **Documents** | Word docs, PDFs, spreadsheets, presentations |
| 💻 **Coding** | Worklogs, code review, architecture design |
| 🎨 **Frontend** | UI components, landing pages, design systems |
| 🏥 **Health** | Medical record interpretation, elderly care guidance |
| 🤖 **Agent Tools** | Skill creation, personal assistant, local agent API |
| 📊 **Data** | Excel/CSV processing, data visualization |

---

## Getting Started

### Install a skill on Claude.ai

1. Download the `.skill` file from this repo
2. Go to **Claude.ai → Settings → Skills**
3. Click **Install skill** and upload the `.skill` file
4. The skill is now active — Claude will use it automatically when relevant

### Use a skill manually

Copy the content of any `SKILL.md` into your system prompt, or reference it directly in your conversation with an AI agent:

```
Read the instructions in SKILL.md and follow them to complete this task.
```

---

## Skills in this Repo

### 🛠️ [`coding-worklog`](./coding-worklog/)
Guide the agent to create structured Markdown worklogs (`WORKLOG_V1.0.0.md`) documenting problem statements, solution trade-offs, completed work, remaining tasks, and a phased roadmap.

**Triggers on:** *"create worklog", "log progress", "write worklog", end of coding session*

---

> More skills coming soon. Contributions welcome!

---

## Contributing

Have a skill you'd like to share? Contributions are welcome!

1. Fork this repo
2. Create your skill folder under the appropriate category
3. Follow the skill structure above
4. Submit a Pull Request with a brief description of what your skill does

**Skill quality checklist:**
- [ ] Clear `description` in YAML frontmatter — includes both what it does and when to trigger
- [ ] Step-by-step instructions an agent can follow without ambiguity
- [ ] At least one example or template showing expected output
- [ ] Tested with at least one AI agent (Claude, Cursor, etc.)

---

## Philosophy

Most AI agents are capable — they just lack **context and structure** for specialized tasks. Skills bridge that gap by encoding domain knowledge, output formats, and decision logic directly into reusable instruction sets.

Good skills are:
- **Specific** — narrow scope, deep guidance
- **Opinionated** — make decisions so the agent doesn't have to guess
- **Transferable** — work across different AI agents and tools
- **Living documents** — updated as workflows evolve

---

## License

MIT — free to use, modify, and distribute. Attribution appreciated.

---

<p align="center">Built with ❤️ to make AI agents actually useful in the real world.</p>
