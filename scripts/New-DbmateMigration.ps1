function New-DbmateMigration {
  param([Parameter(Mandatory=$true)][string]$Name)

  $root = (Resolve-Path ".").Path
  $dir  = Join-Path $root "db\migrations"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $file  = Join-Path $dir ("{0}_{1}.sql" -f $stamp, $Name)

  $content = @"
-- migrate:up
SELECT 1;

-- migrate:down
SELECT 1;
"@

  $enc = New-Object System.Text.UTF8Encoding($false) # UTF-8 sem BOM
  [IO.File]::WriteAllText($file, $content, $enc)

  $head = (Get-Content -Encoding Byte -TotalCount 3 -Path $file)
  "{0} criado. Head: {1:X2} {2:X2} {3:X2}" -f $file,$head[0],$head[1],$head[2]
}
