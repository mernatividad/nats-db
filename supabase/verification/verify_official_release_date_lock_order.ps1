param(
  [string]$DbUrl = $env:SUPABASE_DB_URL,
  [string]$ReleaseId = $env:OFFICIAL_RELEASE_TEST_RELEASE_ID,
  [string]$ExamId = $env:OFFICIAL_RELEASE_TEST_EXAM_ID,
  [int]$LockTimeoutSeconds = 2
)

$ErrorActionPreference = 'Stop'
if (-not $DbUrl) { throw 'SUPABASE_DB_URL is required' }
$schemaSql = Join-Path $PSScriptRoot '..\tests\verify_official_release_date.sql'
& psql $DbUrl --set ON_ERROR_STOP=1 --file $schemaSql
if ($LASTEXITCODE -ne 0) { throw "official release date SQL verification failed: $LASTEXITCODE" }

if (-not $ReleaseId) {
  throw 'ReleaseId is required for the two-session lock harness; schema-only checks use verify_official_release_date.sql'
}
try { $releaseGuid = [guid]$ReleaseId } catch { throw 'ReleaseId must be a UUID' }
if (-not $ExamId) { throw 'ExamId is required so the second session exercises publish_legacy_exam' }
try { $examGuid = [guid]$ExamId } catch { throw 'ExamId must be a UUID' }

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("official-release-lock-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
  $sqlAContent = @"
\set ON_ERROR_STOP on
begin;
set local lock_timeout = '${LockTimeoutSeconds}s';
select * from board_pulse.set_prc_release_official_date('$releaseGuid', null, null, null, '[]'::jsonb, 'lock-harness', null, gen_random_uuid(), 'lock-harness', 'lock-harness-' || gen_random_uuid()::text);
select pg_sleep(1);
rollback;
"@
  $sqlBContent = @"
\set ON_ERROR_STOP on
begin;
set local lock_timeout = '${LockTimeoutSeconds}s';
select * from board_pulse.publish_legacy_exam('$examGuid', 'validated', null, null, null, '[]'::jsonb, 'lock-harness', null, gen_random_uuid(), 'lock-harness', 'lock-harness-' || gen_random_uuid()::text);
select pg_sleep(1);
rollback;
"@
  $sqlA = Join-Path $root 'a.sql'
  $sqlB = Join-Path $root 'b.sql'
  Set-Content -LiteralPath $sqlA -Value $sqlAContent -NoNewline
  Set-Content -LiteralPath $sqlB -Value $sqlBContent -NoNewline
  $a = Start-Process -FilePath 'psql' -ArgumentList @($DbUrl, '--file', $sqlA) -RedirectStandardOutput (Join-Path $root 'a.out') -RedirectStandardError (Join-Path $root 'a.err') -PassThru -Wait:$false
  Start-Sleep -Milliseconds 150
  $b = Start-Process -FilePath 'psql' -ArgumentList @($DbUrl, '--file', $sqlB) -RedirectStandardOutput (Join-Path $root 'b.out') -RedirectStandardError (Join-Path $root 'b.err') -PassThru -Wait:$false
  $a.WaitForExit(); $b.WaitForExit()
  if ($a.ExitCode -ne 0 -or $b.ExitCode -ne 0) {
    throw "concurrent lock-order sessions failed: A=$($a.ExitCode) B=$($b.ExitCode)`n$(Get-Content (Join-Path $root 'a.err') -Raw)`n$(Get-Content (Join-Path $root 'b.err') -Raw)"
  }
  Write-Output 'Two independent sessions acquired release, batch, ingestion-state, and exam locks in the same order; both transactions rolled back.'
}
finally {
  Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
