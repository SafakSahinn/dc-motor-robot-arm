param(
  [Parameter(Mandatory=$true)][string]$Q,
  [int]$N = 20,
  [switch]$Abs
)
# Semantic Scholar relevance search. Prints year | cites | venue | title | doi
$enc = [uri]::EscapeDataString($Q)
$url = "https://api.semanticscholar.org/graph/v1/paper/search?query=$enc&limit=$N&fields=title,year,venue,citationCount,externalIds,abstract"
$r = $null
for ($t = 0; $t -lt 6 -and -not $r; $t++) {
  try { $r = Invoke-RestMethod -Uri $url -Method Get }
  catch { Start-Sleep -Seconds (4 + 3*$t) }
}
if (-not $r) { "FAILED: " + $Q; return }
"TOTAL: " + $r.total + "  Q: " + $Q
foreach ($w in $r.data) {
  $doi = ""; if ($w.externalIds -and $w.externalIds.DOI) { $doi = $w.externalIds.DOI }
  "{0} | {1} | {2} | {3} | {4}" -f $w.year, $w.citationCount, $w.venue, $w.title, $doi
  if ($Abs -and $w.abstract) { "    ABS: " + $w.abstract }
}
