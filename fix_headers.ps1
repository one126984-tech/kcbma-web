# Fix all sub-page headers - UTF-8 safe PowerShell script
# Run with: powershell -File fix_headers.ps1

$rootDir = 'C:\Users\lll\projects\kcbma-website'
$indexFile = Join-Path $rootDir 'index.html'

# Get all HTML files except index.html
$files = Get-ChildItem $rootDir -Recurse -Filter '*.html' | 
    Where-Object { $_.FullName -ne $indexFile }

Write-Host "Found $($files.Count) sub-page HTML files."

foreach ($file in $files) {
    $relPath = $file.FullName.Replace($rootDir + '\', '')
    
    # Read raw bytes, decode as UTF-8
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $enc = [System.Text.Encoding]::UTF8
    $content = $enc.GetString($bytes)
    
    # Fix DOCTYPE if stripped (starts with OCTYPE instead of <!DOCTYPE)
    if ($content.StartsWith('OCTYPE')) {
        $content = '<!D' + $content
    }
    
    # Determine active class based on file path
    $activeAbout = ''
    $activeInfo = ''
    $activeForum = ''
    $activeJobs = ''
    $activeSinmungo = ''
    
    if ($relPath -like 'about\*') {
        $activeAbout = ' class="active"'
    } elseif ($relPath -like 'info\forum*') {
        $activeForum = ' class="active"'
    } elseif ($relPath -like 'jobs\*') {
        $activeJobs = ' class="active"'
    } elseif ($relPath -like 'info\sinmungo*') {
        $activeSinmungo = ' class="active"'
    } elseif ($relPath -like 'info\*' -or $relPath -like 'policy\*') {
        $activeInfo = ' class="active"'
    }
    # partners/* -> no active
    
    # Build canonical header
    $header = @"
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
      <li${activeAbout}><a href="../about/intro.html">협회소개</a></li>
      <li${activeInfo}>
        <a href="../info/index.html">정보교류</a>
        <div class="gnb-dropdown">
          <a href="../policy/law.html">법규·정책</a>
          <a href="../info/videos.html">영상 자료실</a>
          <a href="../info/columns.html">시설업체 칼럼</a>
        </div>
      </li>
      <li${activeForum}><a href="../info/forum.html">정책토론</a></li>
      <li${activeJobs}><a href="../jobs/list.html">구인구직</a></li>
      <li${activeSinmungo}><a href="../info/sinmungo.html">정책신문고</a></li>
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
"@
    
    # Find the start of util-bar block
    $utilBarPattern = [regex]'<!-- [①\?]+ UTIL BAR -->[\r\n]+<div class="util-bar"'
    $utilBarMatch = $utilBarPattern.Match($content)
    if (-not $utilBarMatch.Success) {
        # Try without comment
        $utilBarPattern2 = [regex]'<div class="util-bar"'
        $utilBarMatch = $utilBarPattern2.Match($content)
    }
    
    if (-not $utilBarMatch.Success) {
        Write-Host "  ${relPath}: SKIPPED (no util-bar found)"
        continue
    }
    
    $startIdx = $utilBarMatch.Index
    
    # Find end of mobile-menu block - look for </div></div></div> pattern after mobile-menu
    # The mobile-menu structure is:
    # <div id="mobile-menu"...>
    #   <div class="mobile-menu-inner">
    #     <div class="mobile-menu-header">...</div>
    #     <ul>...</ul>
    #     <div class="mobile-cta-area">...</div>
    #   </div>
    # </div>
    # 
    # Find the mobile-menu div closing
    $mobileMenuStart = $content.IndexOf('<div id="mobile-menu"', $startIdx)
    if ($mobileMenuStart -lt 0) {
        Write-Host "  ${relPath}: SKIPPED (no mobile-menu found)"
        continue
    }
    
    # Find the end - look for </div> after mobile-cta-area close
    # Mobile menu ends with </div>\n</div>\n</div>
    # We need to find the position after these 3 closing divs
    $mobileCtaEnd = $content.IndexOf('</div>', $content.IndexOf('mobile-cta-area', $mobileMenuStart))
    $afterCta = $mobileCtaEnd + 6  # after </div>
    
    # Now skip whitespace/newlines and find next </div> (mobile-menu-inner close) and </div> (mobile-menu close)
    $p = $afterCta
    # skip whitespace
    while ($p -lt $content.Length -and ($content[$p] -eq "`n" -or $content[$p] -eq "`r" -or $content[$p] -eq " ")) { $p++ }
    if ($content.Substring($p, 6) -eq '</div>') {
        $p += 6
    }
    # skip whitespace again
    while ($p -lt $content.Length -and ($content[$p] -eq "`n" -or $content[$p] -eq "`r" -or $content[$p] -eq " ")) { $p++ }
    if ($content.Substring($p, 6) -eq '</div>') {
        $p += 6
    }
    # skip newline
    while ($p -lt $content.Length -and ($content[$p] -eq "`n" -or $content[$p] -eq "`r")) { $p++ }
    
    $endIdx = $p
    
    # Replace
    $newContent = $content.Substring(0, $startIdx) + $header + "`n" + $content.Substring($endIdx)
    
    # Write back as UTF-8 without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
    
    Write-Host "  ${relPath}: OK"
}

Write-Host "`nDone."
