$root = "C:\Projects\eng_loop\fix_loop5"
$worktreeBase = Join-Path $root "worktrees"
$doneFile = Join-Path $root "task-done.txt"

$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Remove any leftover worktrees from a previous run, so this run starts fresh.
if (Test-Path $worktreeBase) {
    Remove-Item -Recurse -Force $worktreeBase
}
New-Item -ItemType Directory -Path $worktreeBase | Out-Null

$candidates = @(
    @{ Name = "candidate-a"; File = "candidates\candidate-a.js" },
    @{ Name = "candidate-b"; File = "candidates\candidate-b.js" },
    @{ Name = "candidate-c"; File = "candidates\candidate-c.js" }
)

$verdicts = @()

foreach ($c in $candidates) {
    $wtPath = Join-Path $worktreeBase $c.Name
    git worktree add $wtPath HEAD 2>&1 | Out-Null

    $srcDest = Join-Path $wtPath "src\calc.js"
    Copy-Item -Path (Join-Path $root $c.File) -Destination $srcDest -Force

    Push-Location $wtPath
    try {
        npm test 2>&1 | Out-Null
        $exit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    if ($exit -eq 0) {
        $verdict = "PASS"
        $prFile = "PR-$($c.Name).md"
        Set-Content -Path (Join-Path $root $prFile) -Value "# PR: $($c.Name)`n`nVerdict: PASS"
    } else {
        $verdict = "FAIL"
    }

    $verdicts += [PSCustomObject]@{
        Candidate = $c.Name
        Verdict = $verdict
        ExitCode = $exit
    }
}

# Clean up worktrees.
git worktree prune 2>&1 | Out-Null
if (Test-Path $worktreeBase) {
    Remove-Item -Recurse -Force $worktreeBase
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Count existing DONE and SUMMARY files for numbering.
$doneCount = 0
if (Test-Path $doneFile) {
    $doneCount = (Get-Content $doneFile | Where-Object { $_ -match '^DONE-' }).Count
}
$nextDone = $doneCount + 1
"DONE-$nextDone at $now" | Add-Content -Path $doneFile

$summaryCount = (Get-ChildItem -Path $root -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue).Count
$nextSummary = $summaryCount + 1

$summaryLines = @(
    "Run: $nextSummary"
    "Started: $startedAt"
    "Finished: $now"
    "Candidates:"
)
foreach ($v in $verdicts) {
    $summaryLines += "  $($v.Candidate) : $($v.Verdict) (test exit $($v.ExitCode))"
}
Set-Content -Path (Join-Path $root "SUMMARY$nextSummary.md") -Value $summaryLines

Write-Output "===== Engine (body, not a loop) ====="
Write-Output "Run: $nextSummary"
foreach ($v in $verdicts) {
    Write-Output "$($v.Candidate) : $($v.Verdict)"
}
Write-Output "Wrote task-done.txt -> DONE-$nextDone"
Write-Output "Wrote SUMMARY$nextSummary.md"
Write-Output "===================================="
