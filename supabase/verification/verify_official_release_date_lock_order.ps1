param([string]$DbUrl = $env:SUPABASE_DB_URL)
$ErrorActionPreference = 'Stop'
if (-not $DbUrl) { throw 'SUPABASE_DB_URL is required for the two-session lock harness' }
$sql = Join-Path $PSScriptRoot '..\tests\verify_official_release_date.sql'
& psql $DbUrl --set ON_ERROR_STOP=1 --file $sql
if ($LASTEXITCODE -ne 0) { throw "official release date SQL verification failed: $LASTEXITCODE" }
Write-Output 'Schema and privilege checks passed. Run the deployment-specific two-session fixture against a seeded release before applying production backfill.'
