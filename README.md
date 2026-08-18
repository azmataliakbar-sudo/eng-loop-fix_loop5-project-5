# fix_loop5

Project 5 from the Loop Engineering crash course.

## Run

```powershell
.\engine.ps1
```

Run it twice. Each run should give the same verdicts and remember nothing between runs.

## What it does

- Runs 3 candidate fixes (candidate-a, candidate-b, candidate-c) in parallel worktrees.
- A separate `reviewer.js` grades each candidate by running `npm test`.
- Only PASS candidates get a PR file.
- One command runs the whole draft-and-review body.

## Done when

- One command runs the whole body (several candidates, isolated checkouts, a verdict for each).
- A fresh run remembers nothing from the last run.
- It needs a heartbeat + a spine to become a loop.
