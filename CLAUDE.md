# claude-harness

A Claude Code harness for timed builds (hackathons, technical tests). It ships one user-level skill,
`/scaffold`, which turns an empty folder into a tested Spring Boot REST API with its own Claude setup.
It is Java backend only; React (full-stack) support was removed.
README.md is the user guide; this file is for working on the harness itself.

## Layout
- `skills/scaffold/SKILL.md`: the procedure Claude follows: a Spring Boot REST API with Swagger UI
  and problem-detail errors. Arguments are ignored (`/scaffold backend` still works).
- `skills/scaffold/templates/`: files copied into the new project. `copy-templates.ps1` does all
  copying (`-Part backend|harness -Root <dir>`); the skill must never copy templates by hand.
  - `templates/backend/`: Java starter code plus the project harness (`CLAUDE.md`, `spec-SKILL.md`,
    `verify-SKILL.md`).
  - `templates/settings.json`, `gitignore`, `gitattributes`: project settings.
- `install.ps1`: copies `skills/*` to `%USERPROFILE%\.claude\skills\`.

## Working on it
- This repo is the source of truth. Edit here, then run `.\install.ps1 -Force`. Never edit the
  installed copy under `%USERPROFILE%\.claude\skills\` directly.
- Windows and PowerShell 7 only. In scripts, pass `Set-Content`/`Add-Content` parameters by name
  (`-LiteralPath`, `-Value`): with `-NoNewline`, PowerShell 7 binds positional arguments wrongly.
- `.gitattributes` in templates is copied whole, never merged: later lines win.
- Spring Boot 4 changes that templates rely on: test annotations live in
  `org.springframework.boot.webmvc.test.autoconfigure`; Jackson 3; springdoc-openapi 3.x
  (2.8.x for Spring Boot 3). A controller nested in a test class needs an explicit `@Import`.

## Testing a change
A change is tested by running the skill as written, end to end, in a fresh empty folder (for
example via a subagent told to follow SKILL.md literally and report every place it had to
improvise), then checking: tests pass, `/api/health` returns OK, Swagger UI answers, the commit is
clean. The run uses port 8080, so stop any server holding it first.

## Conventions
- Small commits with imperative subjects. No secrets: the repository is public.
- Keep README.md in step with SKILL.md (what gets created, troubleshooting).
