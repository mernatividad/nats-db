# Exam-results search verification runbook

Use this runbook after the indexed search migration has been deployed to the linked Supabase project.
Run commands from the repository root (`C:\projects\nats22`) in PowerShell.

## 1. Confirm the migration is applied

```powershell
supabase db push --dry-run
```

Expected result: no pending `20260903_index_passer_search_corpus.sql` migration.

If it is listed as pending, apply it deliberately:

```powershell
supabase db push
```

## 2. Set a real exam slug

Use the database exam slug without the route suffix `-passers` or `-top-notchers`.

```powershell
$env:EXAM_SLUG = "august-2026-guidance-counselors-computer-based-licensure-examination-results"
```

## 3. Run the remote query plan

The current CLI must support `supabase db query`. Check first:

```powershell
supabase db query --help
```

Then run the checked-in verification query with the selected slug:

```powershell
$sql = (Get-Content -Raw .\supabase\verification\exam-results-search-plan.sql).Replace(
  "replace-with-exam-slug",
  $env:EXAM_SLUG
)

New-Item -ItemType Directory -Force .\.artifacts | Out-Null

$verificationSqlPath = Join-Path $env:TEMP "exam-results-search-plan.sql"
$sql | Set-Content -Path $verificationSqlPath -Encoding utf8

supabase db query --linked --file $verificationSqlPath --output-format json |
  Tee-Object .\.artifacts\exam-results-search-plan.json
```

If the installed CLI does not have `db query`, use the latest CLI temporarily:

```powershell
npx supabase@latest db query --linked --file $verificationSqlPath --output-format json |
  Tee-Object .\.artifacts\exam-results-search-plan.json

Remove-Item -LiteralPath $verificationSqlPath -Force
```

## 4. Review the evidence

Confirm the JSON plan contains:

- `passer_search_index_search_document_trgm_idx` for the name predicate, or another clearly index-backed
  trigram plan;
- the exam-scope index where applicable;
- materially fewer rows removed by the name filter than the baseline;
- execution time materially below the supplied baseline of `278.412 ms` on comparable data;
- no repeated computed `unnest` subplans over the full corpus.

The supplied pre-migration baseline scanned the computed view, removed `6,695` rows by filter, and ran in
`278.412 ms`. A plan that still performs a broad scan should not be treated as rollout-ready.

### Verified post-migration result

For `august-2026-guidance-counselors-computer-based-licensure-examination-results`, the supplied post-migration
plan ran in `6.002 ms` and used `passer_search_index_search_document_trgm_idx` through a `Bitmap Index Scan`.
The query returned zero rows for the sample name `Juan Cruz`, but the index path was confirmed and only one
candidate row was removed by the exam/passers filter. This is approximately a 46x execution-time improvement
over the supplied pre-migration baseline; repeat with a known matching name before final rollout approval.

The known matching name `ABAD, NEIL FRANCO ESTANDARTE` then returned one row in `3.819 ms`, again using
`passer_search_index_search_document_trgm_idx` through a `Bitmap Index Scan`, with zero rows removed by the
exam/passers filter. This confirms both the indexed execution path and a matching result in the scoped corpus.

## 5. Verify refresh behavior

After a successful scraper ingest, confirm the run log contains:

```text
passer_search_index_refreshed
```

Then rerun the query above and confirm the newly ingested release is searchable only after its release-gating
conditions are satisfied.

For a read-only count check against a specific release, run the repository verifier with runtime credentials:

```powershell
node scripts/verify-search-index-parity.mjs `
  --url $env:SUPABASE_URL `
  --anon-key $env:SUPABASE_ANON_KEY `
  --slug $env:EXAM_SLUG
```

The command passes when the indexed corpus contains every canonical result and no more than the canonical results
plus the release's top-notcher rows. It fails on the observed stale-index condition, without printing the key.

If it fails because the indexed count is behind canonical results, an authorized operator must refresh the corpus
after confirming the release data is correct. Keep the service-role key in the environment only:

```powershell
$headers = @{
  apikey = $env:SUPABASE_SERVICE_ROLE_KEY
  Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
  "Accept-Profile" = "board_pulse"
  "Content-Type" = "application/json"
}
Invoke-RestMethod -Method Post `
  -Uri "$env:SUPABASE_URL/rest/v1/rpc/refresh_passer_search_index" `
  -Headers $headers -Body "{}"
```

Rerun the parity verifier and a known-name scoped search after the refresh. Record the counts and operator/time in
the release run log; do not paste credentials or raw examinee lists into the log.

## 6. Cloudflare checks before broad rollout

Record evidence that:

- `/api/search` is proxied through Cloudflare;
- burst and sustained rate limits are active;
- `CF-Ray` and a trustworthy client-IP header reach the origin;
- direct origin access is locked down;
- `429` responses preserve `Retry-After` and remain compatible with the browser UI;
- sampled shard/API parity, p50/p95/p99 latency, 4xx/5xx/429 rates, database load, and index freshness are
  monitored.

Keep the shard fallback enabled until parity and rollback thresholds have been reviewed.

## Verification status

- Repository contracts and the indexed-plan verification SQL are prepared; migration/query execution has not been
  re-run in this environment because no local Supabase stack or staging SQL connection is available.
- The read-only parity verifier is available, but it still requires a reachable Supabase REST endpoint and runtime
  credentials; run it for each affected release after the one-time materialized-view refresh.
- Cloudflare proxy/rate-limit coverage and origin lock-down still require operator evidence.
- Shard fallback remains available for the rollout window.
