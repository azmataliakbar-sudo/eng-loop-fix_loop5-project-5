$root = "C:\Projects\eng_loop\fix_loop5"
$doneFile = Join-Path $root "task-done.txt"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$candidates = @(
    @{ Name = "candidate-a"; File = "candidates\candidate-a.js" },
    @{ Name = "candidate-b"; File = "candidates\candidate-b.js" },
    @{ Name = "candidate-c"; File = "candidates\candidate-c.js" }
)

$verdicts = @()
$createdPaths = @()

foreach ($c in $candidates) {
    $wtPath = Join-Path $root "wt-$stamp-$($c.Name)"

    $null = git worktree add $wtPath HEAD 2>&1
    if (Test-Path (Join-Path $wtPath "src\calc.js")) {
        Copy-Item -Path (Join-Path $root $c.File) -Destination (Join-Path $wtPath "src\calc.js") -Force

        Push-Location $wtPath
        try {
            npm test 2>&1 | Out-Null
            $exit = $LASTEXITCODE
        } finally {
            Pop-Location
        }

        if ($exit -eq 0) {
            $verdict = "PASS"
            Set-Content -Path (Join-Path $root "PR-$($c.Name).md") -Value "# PR: $($c.Name)`n`nVerdict: PASS"
        } else {
            $verdict = "FAIL"
        }
    } else {
        $verdict = "WORKTREE-ERROR"
        $exit = -1
    }

    $verdicts += [PSCustomObject]@{
        Candidate = $c.Name
        Verdict = $verdict
        ExitCode = $exit
    }

    $createdPaths += $wtPath
}

# Properly remove each worktree, then prune.
foreach ($p in $createdPaths) {
    if (Test-Path $p) {
        git worktree remove --force $p 2>&1 | Out-Null
    }
}
git worktree prune 2>&1 | Out-Null

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

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
