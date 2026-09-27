# Generates harbour-astnovel_{en,de,ru,fi}.ts from strings.tsv
# TSV columns: context <TAB> source(zh) <TAB> en <TAB> de <TAB> ru <TAB> fi
$ErrorActionPreference = "Stop"
$root = "D:\DSH\AstNovel-Sailfish\sfdk\harbour-astnovel\translations"
$lines = [System.IO.File]::ReadAllLines("$root\strings.tsv")
$langs = @("en", "de", "ru", "fi")
$langAttr = @{ en = "en_US"; de = "de_DE"; ru = "ru_RU"; fi = "fi_FI" }
function Esc([string]$s) {
    $s = $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
    return $s
}
# Group rows by context, preserving order of first appearance
$order = New-Object System.Collections.ArrayList
$byCtx = @{}
foreach ($ln in $lines) {
    if ($ln.Trim() -eq "") { continue }
    $p = $ln.Split("`t")
    if ($p.Count -ne 6) { throw "Bad TSV row (expected 6 cols): $($p[0]) / $($p[1])" }
    $ctx = $p[0]
    if (-not $byCtx.ContainsKey($ctx)) {
        $byCtx[$ctx] = New-Object System.Collections.ArrayList
        [void]$order.Add($ctx)
    }
    [void]$byCtx[$ctx].Add($p)
}
foreach ($lang in $langs) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
    [void]$sb.AppendLine('<!DOCTYPE TS>')
    [void]$sb.AppendLine("<TS version=`"2.1`" language=`"$($langAttr[$lang])`" sourcelanguage=`"zh_CN`">")
    foreach ($ctx in $order) {
        [void]$sb.AppendLine("<context>")
        [void]$sb.AppendLine("    <name>$ctx</name>")
        foreach ($p in $byCtx[$ctx]) {
            $src = Esc($p[1]); $tr = Esc($p[2 + $langs.IndexOf($lang)])
            [void]$sb.AppendLine("    <message>")
            [void]$sb.AppendLine("        <source>$src</source>")
            [void]$sb.AppendLine("        <translation>$tr</translation>")
            [void]$sb.AppendLine("    </message>")
        }
        [void]$sb.AppendLine("</context>")
    }
    [void]$sb.AppendLine("</TS>")
    $out = "$root\harbour-astnovel_$lang.ts"
    [System.IO.File]::WriteAllText($out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    $n = ($order | ForEach-Object { $byCtx[$_].Count } | Measure-Object -Sum).Sum
    Write-Output "$out : $n messages"
}
# Compile .qm with the lrelease bundled in PySide6 (Build Engine has none)
$lrel = Join-Path (python -c "import PySide6, os; print(os.path.dirname(PySide6.__file__))") "lrelease.exe"
if (-not (Test-Path $lrel)) { throw "lrelease.exe not found (pip install pyside6)" }
& $lrel -silent (Get-ChildItem "$root\harbour-astnovel_*.ts" | ForEach-Object { $_.FullName })
Get-ChildItem "$root\*.qm" | ForEach-Object { Write-Output ("QM: {0} ({1} B)" -f $_.Name, $_.Length) }
