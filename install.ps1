# Installs the harness skills into your user-level Claude Code skills folder,
# so they work in every project: %USERPROFILE%\.claude\skills\<skill>
# Usage, from a clone of this repo:  .\install.ps1
param([switch] $Force)
$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'skills'
$target = Join-Path $HOME '.claude\skills'
New-Item -ItemType Directory -Force $target | Out-Null

foreach ($skill in Get-ChildItem $source -Directory) {
    $dest = Join-Path $target $skill.Name
    if ((Test-Path $dest) -and -not $Force) {
        $answer = Read-Host "$dest already exists. Replace it? [y/N]"
        if ($answer -notmatch '^[yY]') { "skipped $($skill.Name)"; continue }
    }
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $skill.FullName $dest -Recurse
    "installed /$($skill.Name) -> $dest"
}
"Done. Start a new Claude Code session to pick up the skills."
