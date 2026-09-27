# Third-party skills in this folder

Copied unmodified from [anthropics/skills](https://github.com/anthropics/skills) at commit `3337550` (2026-09-27), at Ismail's request. Each folder keeps its own `LICENSE.txt` (Apache License 2.0). Project-specific skills (everything else in `.claude/skills/`) are this project's own.

| Skill | Why it is here |
|---|---|
| `frontend-design` | Deliberate visual direction for new UI (premium, non-generic) — read alongside `quran-premium-3d-ui`. |
| `canvas-design` | Producing brand/illustration assets (posters, onboarding art) as PNG/PDF. |
| `algorithmic-art` | Seeded generative patterns (e.g. geometric ornament, waiting-screen motifs) prototyped in p5.js before porting to CustomPainter. |
| `theme-factory` | Consistent themes for reports, docs and slides produced from this project. |
| `web-artifacts-builder` | Interactive HTML reports/dashboards (e.g. plans like `docs/quran/HIFZ_TIMELINE_ENGINE.html`). |
| `mcp-builder` | Designing MCP servers over the app's data (Quran corpus, mosque platform, Supabase). |

Update: re-copy from a newer upstream commit and update the commit hash above.

## Plugins enabled for this project (`.claude/settings.json`)

Six official Anthropic plugins from [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) at commit `fa59bc9`, installed with `--scope project` from a local mirror marketplace `talib-alilm-plugins` at `C:\Users\ismail\.claude\plugin-sources\talib-marketplace` (cloning the official marketplace failed on this machine with "early EOF"). On another machine: `claude plugin marketplace add anthropics/claude-plugins-official`, then install the same six names from it.

| Plugin | Why |
|---|---|
| `feature-dev` | Structured feature workflow (explore → architect → review agents) — pairs with `lightweight-feature-rules`. |
| `security-guidance` | Warnings on risky edits + a commit reviewer (hardcoded secrets etc.) — this repo is public and has leaked a secret before. |
| `claude-md-management` | Audit and keep `CLAUDE.md` / project memory current. |
| `pr-review-toolkit` | Review agents for tests, error handling, type design, comments. |
| `claude-code-setup` | Recommends hooks/skills/subagents tailored to this codebase. |
| `hookify` | Turn recurring mistakes into hooks (e.g. heavy work added to app startup). |
