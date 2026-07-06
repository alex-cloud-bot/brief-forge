param(
  [string]$RepoName = "brief-forge",
  [ValidateSet("public", "private")]
  [string]$Visibility = "public"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Gh = "D:\GPT\tools\bin\gh.exe"

if (-not (Test-Path -LiteralPath $Gh)) {
  throw "GitHub CLI not found: $Gh"
}

Set-Location -LiteralPath $ProjectRoot

& $Gh auth status
if ($LASTEXITCODE -ne 0) {
  Write-Host "GitHub is not logged in. Starting browser login..."
  & $Gh auth login --web --hostname github.com --git-protocol https
  if ($LASTEXITCODE -ne 0) {
    throw "GitHub login was not completed."
  }
}

$repoExists = $false
$repoViewOutput = & $Gh repo view $RepoName 2>$null
if ($LASTEXITCODE -eq 0) {
  $repoExists = $true
}

if (-not $repoExists) {
  & $Gh repo create $RepoName "--$Visibility" --source "." --remote origin --push
} else {
  $remoteUrl = (& $Gh repo view $RepoName --json url --jq ".url").Trim()
  git remote remove origin 2>$null
  git remote add origin "$remoteUrl.git"
  git push -u origin main
}

& $Gh repo view $RepoName --web

Write-Host ""
Write-Host "Repository pushed. If GitHub Pages is not already active, open repository Settings -> Pages and set Source to GitHub Actions."
