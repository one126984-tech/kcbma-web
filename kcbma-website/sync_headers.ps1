# sync_headers.ps1
# Replaces the header block (util-bar -> mobile-menu closing divs) in every
# sub-page HTML file, then re-applies the correct active class to the GNB <li>.

$projectRoot = "C:\Users\lll\projects\kcbma-website"

$canonicalHeader = @'
<!-- ① UTIL BAR -->
<div class="util-bar">
  <div class="inner">
    <div class="util-left">
      <a href="https://cafe.naver.com/kcbma114" target="_blank" rel="noopener" class="util-cafe">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M16.273 12.845L7.376 0H0v24h7.727V11.155L16.624 24H24V0h-7.727z"/></svg>
        네이버카페
      </a>
      <span class="util-divider"></span>
      <a href="#" data-open-modal="login">로그인</a>
      <a href="#" data-open-modal="signup">회원가입</a>
    </div>
    <div class="util-right">
    </div>
  </div>
</div>

<!-- ② HEADER -->
<header id="site-header">
  <div class="header-inner">
    <a href="../index.html" class="brand">
      <img src="../assets/img/logo-shield.jpg" alt="KCBMA 엠블럼" class="brand-mark" />
      <div class="brand-text">
        <span class="brand-name-ko">대한집합건물관리인협회</span>
        <span class="brand-name-en">Korea Collective Building Managers Association</span>
      </div>
    </a>
    <nav class="gnb" aria-label="주요메뉴">
      <li><a href="../about/intro.html">협회소개</a></li>
      <li>
        <a href="../info/index.html">정보교류</a>
        <div class="gnb-dropdown">
          <a href="../policy/law.html">법규·정책</a>
          <a href="../info/videos.html">영상 자료실</a>
          <a href="../info/columns.html">시설업체 칼럼</a>
        </div>
      </li>
      <li><a href="../info/forum.html">정책토론</a></li>
      <li><a href="../jobs/list.html">구인구직</a></li>
      <li><a href="../info/sinmungo.html">정책신문고</a></li>
    </nav>
    <div class="header-cta">
      <a href="../partners/apply.html" class="btn-adv">광고 문의</a>
    </div>
    <button class="mobile-menu-btn" id="mobile-menu-btn" aria-label="메뉴열기">
      <span></span><span></span><span></span>
    </button>
  </div>
</header>

<!-- MOBILE MENU -->
<div id="mobile-menu" role="dialog" aria-modal="true" aria-label="모바일 메뉴">
  <div class="mobile-menu-inner">
    <div class="mobile-menu-header">
      <img src="../assets/img/logo-horizontal.png" alt="KCBMA" />
      <button class="mobile-close" id="mobile-close" aria-label="메뉴닫기">✕</button>
    </div>
    <ul>
      <li><a href="../about/intro.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">협회소개</a></li>
      <li class="mobile-nav-group">
        <details>
          <summary>정보교류</summary>
          <div class="mobile-nav-sub">
            <a href="../policy/law.html">법규·정책</a>
            <a href="../info/videos.html">영상 자료실</a>
            <a href="../info/columns.html">시설업체 칼럼</a>
          </div>
        </details>
      </li>
      <li><a href="../info/forum.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">정책토론</a></li>
      <li><a href="../jobs/list.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">구인구직</a></li>
      <li><a href="../info/sinmungo.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">정책신문고</a></li>
    </ul>
    <div class="mobile-cta-area">
      <a href="../partners/apply.html">광고 문의</a>
      <a href="https://cafe.naver.com/kcbma114" target="_blank" style="background:rgba(255,255,255,.08);">네이버카페 바로가기</a>
    </div>
  </div>
</div>
'@

function Get-ActiveLi {
    param([string]$RelPath)
    # RelPath uses forward slashes, e.g. "about/intro.html"
    if ($RelPath -match '^about/') {
        return 'about'
    } elseif ($RelPath -match '^info/forum') {
        return 'forum'
    } elseif ($RelPath -match '^jobs/') {
        return 'jobs'
    } elseif ($RelPath -match '^info/sinmungo') {
        return 'sinmungo'
    } elseif ($RelPath -match '^(info|policy)/') {
        return 'info'
    } else {
        return 'none'
    }
}

function Add-ActiveClass {
    param([string]$Header, [string]$ActiveKey)
    # Match purely on URL (ASCII only) to avoid encoding issues with Korean text
    switch ($ActiveKey) {
        'about' {
            # <li><a href="../about/intro.html">...</a></li>
            return $Header -replace '(<li>)(<a href="\.\./about/intro\.html">)', '<li class="active">$2'
        }
        'forum' {
            # <li><a href="../info/forum.html">...</a></li>
            return $Header -replace '(<li>)(<a href="\.\./info/forum\.html">)', '<li class="active">$2'
        }
        'jobs' {
            return $Header -replace '(<li>)(<a href="\.\./jobs/list\.html">)', '<li class="active">$2'
        }
        'sinmungo' {
            return $Header -replace '(<li>)(<a href="\.\./info/sinmungo\.html">)', '<li class="active">$2'
        }
        'info' {
            # The dropdown li:  <li>\n        <a href="../info/index.html">...
            return $Header -replace '(<li>)(\s*<a href="\.\./info/index\.html">)', '<li class="active">$2'
        }
        default { return $Header }
    }
}

# Collect sub-page HTML files
$subDirs = @('about','info','jobs','partners','policy')
$htmlFiles = @()
foreach ($dir in $subDirs) {
    $dirPath = Join-Path $projectRoot $dir
    if (Test-Path $dirPath) {
        $files = Get-ChildItem -Path $dirPath -Filter "*.html" | Sort-Object FullName
        $htmlFiles += $files
    }
}

Write-Host "Found $($htmlFiles.Count) sub-page HTML files.`n"

$changed = 0

foreach ($file in $htmlFiles) {
    $relPath = $file.FullName.Substring($projectRoot.Length + 1) -replace '\\','/'
    
    # Read with UTF-8 (strip BOM if present)
    $rawBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    # Detect BOM
    $hasBom = ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF)
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    # Remove BOM character if present at start
    if ($content.StartsWith([char]0xFEFF)) {
        $content = $content.Substring(1)
    }

    # Normalise line endings to LF for consistent regex matching
    $content = $content -replace "`r`n", "`n"
    $content = $content -replace "`r", "`n"

    # Find start of util-bar (allow leading whitespace)
    $utilBarMatch = [regex]::Match($content, '[ \t]*<div class="util-bar"')
    if (-not $utilBarMatch.Success) {
        Write-Host "  ${relPath}: SKIPPED (no util-bar found)"
        continue
    }
    $startPos = $utilBarMatch.Index

    # Walk backwards over any HTML comment lines that immediately precede the util-bar div
    # (e.g. "<!-- Util Bar -->" or "<!-- ① UTIL BAR -->") including the newline after each comment.
    # We do this by repeatedly checking if the text immediately before startPos ends with
    # a line that is solely an HTML comment (possibly preceded by a blank line).
    $prefix = $content.Substring(0, $startPos)
    $commentLinePattern = [regex]'([ \t]*<!--[^\n]*-->\n)$'
    while ($true) {
        $cm = $commentLinePattern.Match($prefix)
        if ($cm.Success) {
            $startPos = $startPos - $cm.Length
            $prefix = $content.Substring(0, $startPos)
        } else {
            break
        }
    }

    # Find id="mobile-menu" after startPos
    $mobileSearch = $content.IndexOf('id="mobile-menu"', $startPos)
    if ($mobileSearch -lt 0) {
        Write-Host "  ${relPath}: SKIPPED (no mobile-menu found)"
        continue
    }

    # Find the triple-closing </div> pattern after the mobile-menu opening
    $searchSlice = $content.Substring($mobileSearch)
    $tripleClose = [regex]::Match($searchSlice, '</div>\s*</div>\s*</div>')
    if (-not $tripleClose.Success) {
        Write-Host "  ${relPath}: SKIPPED (cannot find mobile-menu closing divs)"
        continue
    }

    $endPos = $mobileSearch + $tripleClose.Index + $tripleClose.Length

    # Consume trailing newlines belonging to the header block
    while ($endPos -lt $content.Length -and $content[$endPos] -eq "`n") {
        $endPos++
    }

    # Build replacement with active class
    $activeKey = Get-ActiveLi -RelPath $relPath
    $newHeader = Add-ActiveClass -Header $canonicalHeader -ActiveKey $activeKey

    # Stitch together
    $before = $content.Substring(0, $startPos)
    $after  = $content.Substring($endPos)
    $newContent = $before + $newHeader + "`n`n" + $after

    if ($newContent -eq $content) {
        Write-Host "  ${relPath}: SKIPPED (already up-to-date)"
        continue
    }

    # Write back with UTF-8 without BOM
    [System.IO.File]::WriteAllText($file.FullName, $newContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  ${relPath}: OK"
    $changed++
}

Write-Host "`nDone. $changed/$($htmlFiles.Count) files updated."
