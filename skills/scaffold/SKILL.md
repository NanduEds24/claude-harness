---
name: scaffold
description: Scaffold an empty folder into a tested Java Spring Boot starter with a Claude harness (CLAUDE.md, permissions, /spec and /verify skills), verified and committed. "/scaffold backend" builds a backend-only REST API project with Swagger UI; "/scaffold" builds Spring Boot + React (Vite, TypeScript). Run only when the user types /scaffold in an empty project folder.
argument-hint: "[backend]"
disable-model-invocation: true
---

# /scaffold

Turn the current (empty) folder into a tested starter, ready for a timed build. Target: under 10
minutes. Use the PowerShell tool for every command.

**Mode** (from the arguments: `$ARGUMENTS`):
- `backend` → **backend mode**: a Spring Boot REST API only, with the Maven project at `<root>`.
  Skip every step marked *(full-stack only)*.
- empty → **full-stack mode**: Spring Boot in `<root>\backend` plus React in `<root>\frontend`.
  Skip every step marked *(backend only)*.

Conventions:
- `<root>` is the folder /scaffold was run in. `<skill>` is this skill's directory. `<mode>` is
  `backend` or `fullstack`. `<be>` is `<root>` in backend mode and `<root>\backend` in full-stack mode.
- **Start every command block with `Set-Location`** as written, so a working directory left over from
  an earlier command never puts files in the wrong place.
- Copy templates only with `<skill>\templates\copy-templates.ps1`, always passing `-Mode <mode>`. It
  creates folders, fills in versions, adds Swagger to the pom and removes generator leftovers. Don't
  copy template files by hand.
- Tell the user one short line per step. Ask questions only if a step fails.

## 1. Preflight

```powershell
Set-Location <root>
Get-ChildItem -Force -Name
java -version; git --version
git config user.name; git config user.email
```

*(full-stack only)* also run `node -v; npm -v`.

- The folder must be empty apart from `.git`, `.claude`, `.vscode`, `.idea`. Otherwise stop and ask.
- If a required tool is missing, stop and say which.
- If `user.name` or `user.email` is empty, ask the user for them and set them with
  `git config --global` (the commit in step 6 fails without them).
- `<JAVA>`: the installed major Java version if it is 17, 21, 25 or 27, otherwise 21.

## 2. Backend

Download Spring Boot. In backend mode, leave out `&baseDir=backend` so the project lands in `<root>`:

```powershell
Set-Location <root>
Invoke-WebRequest -OutFile starter.zip -Uri "https://start.spring.io/starter.zip?type=maven-project&language=java&javaVersion=<JAVA>&groupId=com.example&artifactId=app&name=app&packageName=com.example.app&dependencies=web,data-jpa,h2,validation,devtools&baseDir=backend"
Expand-Archive starter.zip -DestinationPath .
Remove-Item starter.zip
& "<skill>\templates\copy-templates.ps1" -Part backend -Mode <mode> -Root <root>
Set-Location <be>
.\mvnw.cmd test | Select-String 'Tests run:|BUILD'
```

The output must end with `BUILD SUCCESS` (4 tests: application context, health, two error-handler
tests). The first run downloads dependencies: use a 10-minute timeout. If the script or the tests
fail, show the user the exact error and stop; don't patch around it.

## 3. Frontend *(full-stack only)*

```powershell
Set-Location <root>
npm create vite@latest frontend -- --template react-ts --no-interactive
Set-Location <root>\frontend
npm install --no-fund --no-audit
npm install --no-fund --no-audit tailwindcss @tailwindcss/vite
npm install --no-fund --no-audit -D vitest jsdom @testing-library/react @testing-library/jest-dom
npm pkg set scripts.test="vitest run"
Set-Location <root>
& "<skill>\templates\copy-templates.ps1" -Part frontend -Mode fullstack -Root <root>
Select-String -Path frontend\src\*.ts*, frontend\index.html -Pattern 'assets/|App\.css|icons\.svg'
```

If the last command prints anything, remove those references. Then, from `<root>\frontend`, run
`npm test`, `npm run lint` and `npm run build`; each must exit 0. (`lint` runs oxlint, which prints
nothing when there are no problems.)

## 4. Claude harness

```powershell
Set-Location <root>
& "<skill>\templates\copy-templates.ps1" -Part harness -Mode <mode> -Root <root>
```

This writes `CLAUDE.md` (the variant for the mode, with versions filled in), `.claude/settings.json`,
the `/spec` and `/verify` skills for the mode, `.gitignore` and `.gitattributes`.

## 5. Verify end to end

1. Check the ports are free (this form doesn't fail when nothing is listening). In backend mode
   check only 8080:
   ```powershell
   $busy = Get-NetTCPConnection -LocalPort 8080,5173 -State Listen -ErrorAction SilentlyContinue
   if ($busy) { $busy | ForEach-Object { "$($_.LocalPort) held by " + (Get-Process -Id $_.OwningProcess).ProcessName } } else { 'ports free' }
   ```
   If a port is held, stop and tell the user. It may be their own server; don't kill it.
2. Start the backend as a background command: `Set-Location <be>; .\mvnw.cmd spring-boot:run`.
   *(full-stack only)* also start `Set-Location <root>\frontend; npm run dev -- --port 5173 --strictPort`.
3. Wait for the health endpoint (run this with a 3-minute tool timeout). `<base>` is `http://localhost:8080` in backend mode and
   `http://localhost:5173` (through the Vite proxy) in full-stack mode:
   ```powershell
   $ok = $false
   foreach ($i in 1..60) {
     try { if ((Invoke-RestMethod <base>/api/health).status -eq 'OK') { $ok = $true; break } } catch {}
     Start-Sleep 2
   }
   if ($ok) { 'health OK' } else { 'health check timed out' }
   ```
4. *(backend only)* Check the API docs and the error format:
   ```powershell
   (Invoke-WebRequest http://localhost:8080/swagger-ui.html).StatusCode
   (Invoke-RestMethod http://localhost:8080/v3/api-docs).paths.PSObject.Properties.Name
   try { Invoke-RestMethod http://localhost:8080/api/does-not-exist } catch { $_.ErrorDetails.Message }
   ```
   Expect `200`, a path list containing `/api/health`, and a JSON error body with `"status":404`.
5. *(full-stack only)* Check the page renders. Use a browser tool if one is available; otherwise:
   ```powershell
   & "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe" --headless=new --disable-gpu --user-data-dir="$env:TEMP\scaffold-edge" --virtual-time-budget=5000 --dump-dom http://localhost:5173 2>$null | Select-String 'Backend status'
   ```
   The output must contain `OK`.

Leave the servers running for the user (they stop if this Claude session ends).

## 6. Commit

```powershell
Set-Location <root>
git init -b main   # skip if .git already exists
git add -A
git commit -m "Scaffold starter project"
git log --oneline -1
git status --short
git ls-files | Select-String -Pattern 'node_modules/|target/|dist/'
```

`git status --short` and the last command must print nothing.

## 7. Report

At most 6 lines: the mode, the Spring Boot and Java versions, test results, the verification result
(Swagger UI URL in backend mode, page OK in full-stack mode), the commit hash, any step that failed or
was skipped, and the next step: "Paste the brief and run /spec in plan mode (Shift+Tab)."
