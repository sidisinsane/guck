# ---
# description: Installs guck for Windows.
# usage: irm https://raw.githubusercontent.com/sidisinsane/guck/main/install.ps1 | iex
# exits:
#   0: success
#   1: fail
# ---

$ErrorActionPreference = "Stop"

$GithubUser = "sidisinsane"
$GithubRepo = "guck"
$GuckDir    = "$env:USERPROFILE\.guck"
$BinDir     = "$env:USERPROFILE\.local\bin"

# Clone or update repo
if (Test-Path "$GuckDir\.git") {
  Write-Host "Updating guck in $GuckDir..."
  git -C $GuckDir fetch --all
  git -C $GuckDir reset --hard origin/main
} else {
  Write-Host "Installing guck to $GuckDir..."
  git clone "https://github.com/$GithubUser/$GithubRepo.git" $GuckDir
}

# Create bin directory
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

# Symlink dispatcher
$target = Join-Path $GuckDir "guck.sh"
$link   = Join-Path $BinDir "guck"
New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null
Write-Host "Symlinked guck to $link"

# Add GUCK_DIR and PATH to user environment
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
[System.Environment]::SetEnvironmentVariable("GUCK_DIR", $GuckDir, "User")

if ($userPath -notlike "*$BinDir*") {
  [System.Environment]::SetEnvironmentVariable(
    "PATH",
    "$userPath;$BinDir",
    "User"
  )
  Write-Host "Done! Restart your terminal to use guck."
} else {
  Write-Host "guck is already in your PATH."
}

Write-Host "Installation complete!"
