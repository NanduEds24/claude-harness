# claude-harness

A small Claude Code harness for timed builds (hackathons, technical tests). One command turns an empty
folder into a tested Java Spring Boot project with the Claude setup already in place, so the clock is
spent on features, not setup.

## What's inside

| Skill | What it does |
|---|---|
| `/scaffold backend` | A Spring Boot REST API: health endpoint, Swagger UI, consistent JSON errors, tests, Claude harness. Committed and verified. |
| `/scaffold` | The same backend plus a React + TypeScript frontend (Vite, Tailwind, Vitest) wired through a dev proxy. |

Each scaffolded project gets its own harness:

| File | Purpose |
|---|---|
| `CLAUDE.md` | Stack, commands, working rules, and known traps (Spring Boot 4 test imports, H2, PATCH validation, ...) |
| `.claude/settings.json` | Pre-approved Maven, npm and git commands; destructive commands denied |
| `.claude/skills/spec` | `/spec`: turns the brief into `SPEC.md` (must-haves, endpoints, data model, build order, demo script) |
| `.claude/skills/verify` | `/verify`: runs the tests and exercises the feature on the running app before a commit |

## Requirements

Windows with PowerShell 7, Git, Java 17+ (21 or 25 recommended), Claude Code. Node 20+ only for the
full-stack mode. Internet access to start.spring.io and Maven Central.

## Install

```powershell
git clone https://github.com/NanduEds24/claude-harness.git
cd claude-harness
.\install.ps1
```

This copies `skills\scaffold` to `%USERPROFILE%\.claude\skills\scaffold`, so `/scaffold` works in every
folder. Run `.\install.ps1 -Force` to replace an older copy without being asked. Start a new Claude
Code session afterwards.

Install with `git clone` rather than a downloaded ZIP: Windows marks files from a ZIP as downloaded,
and the default `RemoteSigned` policy then blocks the helper script. If you did use a ZIP, run
`Get-ChildItem -Recurse | Unblock-File` in the extracted folder first.

## Use

```powershell
mkdir my-app; cd my-app
claude
```

Then in Claude Code:

```text
/scaffold backend
```

It takes about 2 minutes once Maven has its dependencies cached (5-10 minutes on a first run). When it
reports success:

1. Paste the brief, switch to plan mode (Shift+Tab) and run `/spec`. Agree the must-haves.
2. Build one feature at a time: entity, repository, service, controller, tests.
3. Run `/verify`, then commit. Repeat.
4. Demo through Swagger UI at http://localhost:8080/swagger-ui.html.

## What `/scaffold backend` creates

```text
my-app/
├── CLAUDE.md
├── .claude/settings.json
├── .claude/skills/spec/SKILL.md
├── .claude/skills/verify/SKILL.md
├── pom.xml                      Spring Boot, Web MVC, JPA, H2, Validation, DevTools, springdoc-openapi
├── mvnw, mvnw.cmd
└── src/
    ├── main/java/com/example/app/
    │   ├── AppApplication.java
    │   ├── common/ApiExceptionHandler.java     every error as {"status","title","detail"}
    │   └── health/HealthController.java        GET /api/health
    ├── main/resources/application.properties   H2 in memory, H2 console on
    └── test/java/com/example/app/              4 passing tests
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `API key is invalid` when starting Claude | An `ANTHROPIC_API_KEY` environment variable overrides your login. Remove it for the terminal: `Remove-Item Env:ANTHROPIC_API_KEY` |
| `copy-templates.ps1 cannot be loaded` | Files came from a ZIP download; see the note under Install |
| `Port 8080 was already in use` | Another server is running. Stop it, or find it with `Get-NetTCPConnection -LocalPort 8080` |
| A warning about `mvnw.cmd` line endings on the first commit | Harmless |

## Updating

```powershell
cd claude-harness
git pull
.\install.ps1 -Force
```
