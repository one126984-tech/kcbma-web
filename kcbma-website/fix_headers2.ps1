# Fix sub-page headers: read canonical header from index.html, adapt paths, inject into sub-pages
# Encoding-safe: reads/writes raw bytes only

$rootDir = 'C:\Users\lll\projects\kcbma-website'
$indexFile = Join-Path $rootDir 'index.html'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Read index.html
$idxBytes = [System.IO.File]::ReadAllBytes($indexFile)
$idxContent = [System.Text.Encoding]::UTF8.GetString($idxBytes)
# Remove BOM if present
if ($idxContent[0] -eq [char]0xFEFF) { $idxContent = $idxContent.Substring(1) }

# Extract header block: from util-bar comment to end of mobile-menu closing div
$startMark = 'UTIL BAR'
$closingDiv = [char]60 + '/div>'
$startCommentIdx = $idxContent.IndexOf($startMark)
# Walk back to find the start of the comment line
$startIdx = $idxContent.LastIndexOf([char]60 + '!--', $startCommentIdx)
$ctaIdx = $idxContent.IndexOf('mobile-cta-area', $startIdx)
$ctaEnd = $idxContent.IndexOf($closingDiv, $ctaIdx)
$innerEnd = $idxContent.IndexOf($closingDiv, $ctaEnd + 6)
$outerEnd = $idxContent.IndexOf($closingDiv, $innerEnd + 6)
$endPos = $outerEnd + 6
$baseHeader = $idxContent.Substring($startIdx, $endPos - $startIdx)

Write-Host "Base header extracted: $($baseHeader.Length) chars"

# Adapt paths for sub-pages (add ../ prefix for relative paths)
# index.html uses: href="about/...", href="info/...", href="jobs/...", href="policy/...", href="partners/..."
# sub-pages need:  href="../about/...", href="../info/...", etc.
# Also: src="assets/... -> src="../assets/...
$subHeader = $baseHeader
$subHeader = $subHeader -replace 'href="about/', 'href="../about/'
$subHeader = $subHeader -replace 'href="info/', 'href="../info/'
$subHeader = $subHeader -replace 'href="jobs/', 'href="../jobs/'
$subHeader = $subHeader -replace 'href="policy/', 'href="../policy/'
$subHeader = $subHeader -replace 'href="partners/', 'href="../partners/'
$subHeader = $subHeader -replace 'href="index\.html"', 'href="../index.html"'
$subHeader = $subHeader -replace 'src="assets/', 'src="../assets/'

# Also remove any existing active class from <li> elements
$subHeader = $subHeader -replace '<li class="active">', '<li>'

Write-Host "Sub-page header adapted."
Write-Host "First 200 chars:"
Write-Host $subHeader.Substring(0, 200)

# Get all HTML files except index.html
$files = Get-ChildItem $rootDir -Recurse -Filter '*.html' |
    Where-Object { $_.FullName -ne $indexFile }

Write-Host "Processing $($files.Count) sub-page files..."

foreach ($file in $files) {
    $relPath = $file.FullName.Replace($rootDir + '\', '')

    # Read raw bytes, decode as UTF-8
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Fix DOCTYPE if stripped (starts with OCTYPE instead of <!DOCTYPE)
    if ($content.StartsWith('OCTYPE')) {
        $content = '<!D' + $content
    }

    # Determine active class based on file path
    $folder = $relPath.Split('\')[0]
    $filename = [System.IO.Path]::GetFileName($file.FullName)

    $activeHeader = $subHeader

    if ($folder -eq 'about') {
        $activeHeader = $activeHeader -replace '(<li>)(<a href="\.\./about/intro\.html">)', '<li class="active">$2'
    } elseif ($folder -eq 'info' -and $filename -like 'forum*') {
        $activeHeader = $activeHeader -replace '(<li>)(<a href="\.\./info/forum\.html">)', '<li class="active">$2'
    } elseif ($folder -eq 'jobs') {
        $activeHeader = $activeHeader -replace '(<li>)(<a href="\.\./jobs/list\.html">)', '<li class="active">$2'
    } elseif ($folder -eq 'info' -and $filename -like 'sinmungo*') {
        $activeHeader = $activeHeader -replace '(<li>)(<a href="\.\./info/sinmungo\.html">)', '<li class="active">$2'
    } elseif ($folder -eq 'info' -or $folder -eq 'policy') {
        # info/index and policy/* -> active on 정보교류
        $activeHeader = $activeHeader -replace '(<li>)(\s+<a href="\.\./info/index\.html">)', '<li class="active">$2'
    }
    # partners/* -> no active class

    # Find the old header block boundaries in this file
    # Try UTIL BAR comment first, then fall back to just util-bar div
    $utilBarSearch = 'util-bar'
    $divTag = [char]60 + 'div'
    $commentTag = [char]60 + '!--'
    $oldCommentIdx = $content.IndexOf('UTIL BAR')
    if ($oldCommentIdx -ge 0) {
        $oldStartIdx = $content.LastIndexOf($commentTag, $oldCommentIdx)
    } else {
        $oldStartIdx = -1
    }
    if ($oldStartIdx -lt 0) {
        # Fall back: find the util-bar div directly
        $ubIdx = $content.IndexOf($utilBarSearch)
        if ($ubIdx -ge 0) {
            $oldStartIdx = $content.LastIndexOf($divTag, $ubIdx)
        }
    }

    if ($oldStartIdx -lt 0) {
        Write-Host "  $relPath : SKIPPED (no util-bar found)"
        continue
    }

    # Find end of mobile-menu in this file
    $closingDiv = [char]60 + '/div>'
    $oldCtaIdx = $content.IndexOf('mobile-cta-area', $oldStartIdx)
    if ($oldCtaIdx -lt 0) {
        Write-Host "  $relPath : SKIPPED (no mobile-cta-area found)"
        continue
    }
    $oldCtaEnd = $content.IndexOf($closingDiv, $oldCtaIdx)
    $oldInnerEnd = $content.IndexOf($closingDiv, $oldCtaEnd + 6)
    $oldOuterEnd = $content.IndexOf($closingDiv, $oldInnerEnd + 6)
    $oldEndPos = $oldOuterEnd + 6

    # Replace
    $newContent = $content.Substring(0, $oldStartIdx) + $activeHeader + "`n" + $content.Substring($oldEndPos)

    # Write back as UTF-8 without BOM
    [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)

    Write-Host "  $relPath : OK"
}

Write-Host ""
Write-Host "Done."
