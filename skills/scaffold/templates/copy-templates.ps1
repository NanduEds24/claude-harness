# Copies the /scaffold templates into a project and fills in the version placeholders.
# Usage (from the project root, with the Maven project at <root>):
#   & "<skill>\templates\copy-templates.ps1" -Part backend|harness -Root <root>
param(
    [Parameter(Mandatory)] [ValidateSet('backend', 'harness')] [string] $Part,
    [string] $Root = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
$t = $PSScriptRoot
$java = 'src/main/java/com/example/app'
$test = 'src/test/java/com/example/app'

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

function Get-Pom { [xml] (Get-Content (Join-Path $Root 'pom.xml')) }

switch ($Part) {
    'backend' {
        Copy-Template 'backend/HealthController.java' "$java/health/HealthController.java"
        Copy-Template 'backend/HealthControllerTest.java' "$test/health/HealthControllerTest.java"
        Copy-Template 'backend/ApiExceptionHandler.java' "$java/common/ApiExceptionHandler.java"
        Copy-Template 'backend/ApiExceptionHandlerTest.java' "$test/common/ApiExceptionHandlerTest.java"
        Copy-Template 'backend/application.properties' 'src/main/resources/application.properties'

        $boot = (Get-Pom).project.parent.version
        # Swagger UI: springdoc 3.x targets Spring Boot 4, 2.8.x targets Spring Boot 3.
        $springdoc = if ($boot -like '3.*') { '2.8.6' } else { '3.1.1' }
        $pomPath = Join-Path $Root 'pom.xml'
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
    'harness' {
        $pom = Get-Pom
        $boot = $pom.project.parent.version
        $javaVersion = $pom.project.properties.'java.version'

        Copy-Template 'backend/CLAUDE.md' 'CLAUDE.md'
        $md = Join-Path $Root 'CLAUDE.md'
        (Get-Content -Raw $md).Replace('<BOOT>', $boot).Replace('<JAVA>', $javaVersion) | Set-Content -NoNewline -LiteralPath $md
        "filled CLAUDE.md with Spring Boot $boot, Java $javaVersion"
        Copy-Template 'settings.json' '.claude/settings.json'
        Copy-Template 'backend/spec-SKILL.md' '.claude/skills/spec/SKILL.md'
        Copy-Template 'backend/verify-SKILL.md' '.claude/skills/verify/SKILL.md'
        Merge-Lines 'gitignore' '.gitignore'
        # Copied whole, not merged: later .gitattributes lines override earlier ones.
        Copy-Template 'gitattributes' '.gitattributes'
        $help = Join-Path $Root 'HELP.md'
        if (Test-Path $help) { Remove-Item $help; 'removed HELP.md' }
    }
}
