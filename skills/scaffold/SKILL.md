---
name: scaffold
description: Scaffold an empty folder into a tested Java Spring Boot REST API starter (Swagger UI, problem-detail errors) with a Claude harness (CLAUDE.md, permissions, /spec and /verify skills), verified and committed. Run only when the user types /scaffold in an empty project folder.
disable-model-invocation: true
---

# /scaffold

Turn the current (empty) folder into a tested Spring Boot REST API starter, ready for a timed build.
Target: under 10 minutes. Use the PowerShell tool for every command. Ignore any arguments (an older
`/scaffold backend` builds the same project).

Conventions:
- `<root>` is the folder /scaffold was run in; the Maven project goes there. `<skill>` is this
  skill's directory.
- **Start every command block with `Set-Location`** as written, so a working directory left over from
  an earlier command never puts files in the wrong place.
- Copy templates only with `<skill>\templates\copy-templates.ps1`. It fills in versions, adds Swagger
  to the pom and removes generator leftovers. Don't copy template files by hand.
- Tell the user one short line per step. Ask questions only if a step fails.

## 1. Preflight

```powershell
Set-Location <root>
Get-ChildItem -Force -Name
java -version; git --version
git config user.name; git config user.email
```

- The folder must be empty apart from `.git`, `.claude`, `.vscode`, `.idea`. Otherwise stop and ask.
- If a required tool is missing, stop and say which.
- If `user.name` or `user.email` is empty, ask the user for them and set them with
  `git config --global` (the commit in step 5 fails without them).
- `<JAVA>`: the installed major Java version if it is 17, 21, 25 or 27, otherwise 21.

## 2. Spring Boot project

```powershell
Set-Location <root>
Invoke-WebRequest -OutFile starter.zip -Uri "https://start.spring.io/starter.zip?type=maven-project&language=java&javaVersion=<JAVA>&groupId=com.example&artifactId=app&name=app&packageName=com.example.app&dependencies=web,data-jpa,h2,validation,devtools"
Expand-Archive starter.zip -DestinationPath .
Remove-Item starter.zip
& "<skill>\templates\copy-templates.ps1" -Part backend -Root <root>
.\mvnw.cmd test | Select-String 'Tests run:|BUILD'
```

The output must end with `BUILD SUCCESS` (4 tests: application context, health, two error-handler
tests). The first run downloads dependencies: use a 10-minute timeout. If the script or the tests
fail, show the user the exact error and stop; don't patch around it.

## 3. Claude harness

```powershell
Set-Location <root>
& "<skill>\templates\copy-templates.ps1" -Part harness -Root <root>
```

This writes `CLAUDE.md` (with versions filled in), `.claude/settings.json`, the `/spec` and `/verify`
skills, `.gitignore` and `.gitattributes`.

## 4. Verify end to end

1. Check port 8080 is free (this form doesn't fail when nothing is listening):
   ```powershell
   $busy = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
   if ($busy) { $busy | ForEach-Object { "$($_.LocalPort) held by " + (Get-Process -Id $_.OwningProcess).ProcessName } } else { 'port free' }
   ```
   If it is held, stop and tell the user. It may be their own server; don't kill it.
2. Start the app as a background command: `Set-Location <root>; .\mvnw.cmd spring-boot:run`.
3. Wait for the health endpoint (run this with a 3-minute tool timeout):
   ```powershell
   $ok = $false
   foreach ($i in 1..60) {
     try { if ((Invoke-RestMethod http://localhost:8080/api/health).status -eq 'OK') { $ok = $true; break } } catch {}
     Start-Sleep 2
   }
   if ($ok) { 'health OK' } else { 'health check timed out' }
   ```
4. Check the API docs and the error format:
   ```powershell
   (Invoke-WebRequest http://localhost:8080/swagger-ui.html).StatusCode
   (Invoke-RestMethod http://localhost:8080/v3/api-docs).paths.PSObject.Properties.Name
   try { Invoke-RestMethod http://localhost:8080/api/does-not-exist } catch { $_.ErrorDetails.Message }
   ```
   Expect `200`, a path list containing `/api/health`, and a JSON error body with `"status":404`.

Leave the app running for the user (it stops if this Claude session ends).

## 5. Commit

```powershell
Set-Location <root>
git init -b main   # skip if .git already exists
git add -A
git commit -m "Scaffold starter project"
git log --oneline -1
git status --short
git ls-files | Select-String -Pattern 'target/'
```

`git status --short` and the last command must print nothing.

## 6. Report

At most 6 lines: the Spring Boot and Java versions, test results, the Swagger UI URL, the commit hash,
any step that failed or was skipped, and the next step: "Paste the brief and run /spec in plan mode
(Shift+Tab)."
