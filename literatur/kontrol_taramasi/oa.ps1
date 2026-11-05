param(
  [Parameter(Mandatory=$true)][string]$Q,
  [int]$N = 25,
  [string]$Out = "",
  [switch]$Abs
)
# OpenAlex title_and_abstract search. Prints year | cites | venue | title | doi
$enc = [uri]::EscapeDataString($Q)
$url = "https://api.openalex.org/works?filter=title_and_abstract.search:$enc&per-page=$N&sort=cited_by_count:desc"
$r = Invoke-RestMethod -Uri $url -Method Get
$rows = @()
foreach ($w in $r.results) {
  $abs = ""
  if ($Abs -and $w.abstract_inverted_index) {
    $pos = @{}
    foreach ($p in $w.abstract_inverted_index.PSObject.Properties) {
      foreach ($i in $p.Value) { $pos[[int]$i] = $p.Name }
    }
    $abs = (($pos.Keys | Sort-Object) | ForEach-Object { $pos[$_] }) -join " "
  }
  $venue = ""
  if ($w.primary_location -and $w.primary_location.source) { $venue = $w.primary_location.source.display_name }
  $rows += [pscustomobject]@{
    year = $w.publication_year; cites = $w.cited_by_count; venue = $venue
    title = $w.display_name; doi = $w.doi; id = $w.id; abstract = $abs
  }
}
"TOTAL: " + $r.meta.count + "  Q: " + $Q
foreach ($x in $rows) {
  "{0} | {1} | {2} | {3} | {4}" -f $x.year, $x.cites, $x.venue, $x.title, $x.doi
  if ($Abs -and $x.abstract) { "    ABS: " + $x.abstract }
}
if ($Out) { $rows | ConvertTo-Json -Depth 4 | Out-File -Encoding utf8 $Out }
