# Copies the /scaffold templates into a project and fills in the version placeholders.
# Usage (from the project root):
#   & "<skill>\templates\copy-templates.ps1" -Part backend|frontend|harness -Mode fullstack|backend -Root <root>
# Mode "backend" expects the Maven project at <root>; mode "fullstack" expects it in <root>\backend.
param(
    [Parameter(Mandatory)] [ValidateSet('backend', 'frontend', 'harness')] [string] $Part,
    [ValidateSet('fullstack', 'backend')] [string] $Mode = 'fullstack',
    [string] $Root = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
$t = $PSScriptRoot
$be = if ($Mode -eq 'backend') { '' } else { 'backend/' }
$java = "${be}src/main/java/com/example/app"
$test = "${be}src/test/java/com/example/app"

function Copy-Template([string] $From, [string] $To) {
    $dest = Join-Path $Root $To
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    Copy-Item (Join-Path $t $From) $dest -Force
    "copied $To"
}

# Appends the template's lines that the existing file lacks (keeps what the generator wrote).
function Merge-Lines([string] $From, [string] $To) {
    $dest = Join-Path $Root $To
    if (-not (Test-Path $dest)) { Copy-Template $From $To; return }
    $have = Get-Content $dest
    $add = Get-Content (Join-Path $t $From) | Where-Object { $_ -and ($have -notcontains $_) }
    if (-not $add) { "$To already complete"; return }
    # Append with LF endings so the file doesn't end up with mixed line endings.
    $text = [IO.File]::ReadAllText($dest)
    $sep = if ($text.EndsWith("`n")) { "`n" } else { "`n`n" }
    [IO.File]::AppendAllText($dest, $sep + ($add -join "`n") + "`n")
    "merged into $To"
}

function Get-Pom { [xml] (Get-Content (Join-Path $Root "${be}pom.xml")) }

switch ($Part) {
    'backend' {
        Copy-Template 'backend/HealthController.java' "$java/health/HealthController.java"
        Copy-Template 'backend/HealthControllerTest.java' "$test/health/HealthControllerTest.java"
        Copy-Template 'backend/ApiExceptionHandler.java' "$java/common/ApiExceptionHandler.java"
        Copy-Template 'backend/ApiExceptionHandlerTest.java' "$test/common/ApiExceptionHandlerTest.java"
        Copy-Template 'backend/application.properties' "${be}src/main/resources/application.properties"

        $boot = (Get-Pom).project.parent.version
        # Swagger UI: springdoc 3.x targets Spring Boot 4, 2.8.x targets Spring Boot 3.
        $springdoc = if ($boot -like '3.*') { '2.8.6' } else { '3.1.1' }
        $pomPath = Join-Path $Root "${be}pom.xml"
        $pomText = Get-Content -Raw $pomPath
        if ($pomText -notmatch 'springdoc-openapi') {
            $dep = "`t`t<dependency>`n`t`t`t<groupId>org.springdoc</groupId>`n`t`t`t<artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>`n`t`t`t<version>$springdoc</version>`n`t`t</dependency>`n`t</dependencies>"
            $pomText = ([regex] '\t</dependencies>').Replace($pomText, $dep, 1)
            Set-Content -NoNewline -LiteralPath $pomPath -Value $pomText
            "added springdoc-openapi $springdoc to pom.xml"
        }

        if ($boot -like '3.*') {
            foreach ($f in "$test/health/HealthControllerTest.java", "$test/common/ApiExceptionHandlerTest.java") {
                $p = Join-Path $Root $f
                (Get-Content -Raw $p).Replace('org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest',
                    'org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest') | Set-Content -NoNewline -LiteralPath $p
            }
            "adjusted test imports for Spring Boot $boot"
        }
    }
    'frontend' {
        Copy-Template 'frontend/vite.config.ts' 'frontend/vite.config.ts'
        Copy-Template 'frontend/App.tsx' 'frontend/src/App.tsx'
        Copy-Template 'frontend/App.test.tsx' 'frontend/src/App.test.tsx'
        Copy-Template 'frontend/index.css' 'frontend/src/index.css'
        Copy-Template 'frontend/test-setup.ts' 'frontend/src/test-setup.ts'
        foreach ($leftover in 'frontend/src/App.css', 'frontend/src/assets', 'frontend/public/icons.svg', 'frontend/README.md') {
            $p = Join-Path $Root $leftover
            if (Test-Path $p) { Remove-Item $p -Recurse -Force; "removed $leftover" }
        }
        $html = Join-Path $Root 'frontend/index.html'
        (Get-Content -Raw $html) -replace '<title>.*</title>', '<title>App</title>' | Set-Content -NoNewline -LiteralPath $html
        "set page title"
    }
    'harness' {
        $pom = Get-Pom
        $boot = $pom.project.parent.version
        $javaVersion = $pom.project.properties.'java.version'
        $variant = if ($Mode -eq 'backend') { 'backend/' } else { '' }
        $spec = if ($Mode -eq 'backend') { 'backend/spec-SKILL.md' } else { 'skills/spec/SKILL.md' }
        $verify = if ($Mode -eq 'backend') { 'backend/verify-SKILL.md' } else { 'skills/verify/SKILL.md' }

        Copy-Template "${variant}CLAUDE.md" 'CLAUDE.md'
        $md = Join-Path $Root 'CLAUDE.md'
        (Get-Content -Raw $md).Replace('<BOOT>', $boot).Replace('<JAVA>', $javaVersion) | Set-Content -NoNewline -LiteralPath $md
        "filled CLAUDE.md with Spring Boot $boot, Java $javaVersion"
        Copy-Template 'settings.json' '.claude/settings.json'
        Copy-Template $spec '.claude/skills/spec/SKILL.md'
        Copy-Template $verify '.claude/skills/verify/SKILL.md'
        Merge-Lines 'gitignore' '.gitignore'
        # Copied whole, not merged: later .gitattributes lines override earlier ones.
        Copy-Template 'gitattributes' '.gitattributes'
        $help = Join-Path $Root 'HELP.md'
        if (Test-Path $help) { Remove-Item $help; 'removed HELP.md' }
    }
}
