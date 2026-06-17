#!/usr/bin/env python3
"""
sync_headers.py
Replaces the header block (util-bar through mobile-menu closing div) in every
sub-page HTML file, then re-applies the correct active class to the GNB <li>.

NOTE: No standalone Python interpreter is available on this machine.
The actual replacement was performed by sync_headers.ps1 (PowerShell).
This Python script is kept as documentation and can be run if Python is installed.
"""

import os
import re

# ── Canonical header (no active class yet; added per-file below) ───────────
CANONICAL_HEADER = '''\
<!-- UTIL BAR -->
<div class="util-bar">
  <div class="inner">
    <div class="util-left">
      <a href="https://cafe.naver.com/kcbma114" target="_blank" rel="noopener" class="util-cafe">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M16.273 12.845L7.376 0H0v24h7.727V11.155L16.624 24H24V0h-7.727z"/></svg>
        \ub124\uc774\ubc84\uce74\ud398
      </a>
      <span class="util-divider"></span>
      <a href="#" data-open-modal="login">\ub85c\uadf8\uc778</a>
      <a href="#" data-open-modal="signup">\ud68c\uc6d0\uac00\uc785</a>
    </div>
    <div class="util-right">
    </div>
  </div>
</div>

<!-- HEADER -->
<header id="site-header">
  <div class="header-inner">
    <a href="../index.html" class="brand">
      <img src="../assets/img/logo-shield.jpg" alt="KCBMA \uc5e0\ube14\ub835" class="brand-mark" />
      <div class="brand-text">
        <span class="brand-name-ko">\ub300\ud55c\uc9d1\ud569\uac74\ubb3c\uad00\ub9ac\uc778\ud611\ud68c</span>
        <span class="brand-name-en">Korea Collective Building Managers Association</span>
      </div>
    </a>
    <nav class="gnb" aria-label="\uc8fc\uc694\uba54\ub274">
      <li><a href="../about/intro.html">\ud611\ud68c\uc18c\uac1c</a></li>
      <li>
        <a href="../info/index.html">\uc815\ubcf4\uad50\ub958</a>
        <div class="gnb-dropdown">
          <a href="../policy/law.html">\ubc95\uaddc\xb7\uc815\uccb5</a>
          <a href="../info/videos.html">\uc601\uc0c1 \uc790\ub8cc\uc2e4</a>
          <a href="../info/columns.html">\uc2dc\uc124\uc5c5\uccb4 \uce7c\ub7fc</a>
        </div>
      </li>
      <li><a href="../info/forum.html">\uc815\ucc45\ud1a0\ub860</a></li>
      <li><a href="../jobs/list.html">\uad6c\uc778\uad6c\uc9c1</a></li>
      <li><a href="../info/sinmungo.html">\uc815\ucc45\uc2e0\ubb38\uace0</a></li>
    </nav>
    <div class="header-cta">
      <a href="../partners/apply.html" class="btn-adv">\uad11\uace0 \ubb38\uc758</a>
    </div>
    <button class="mobile-menu-btn" id="mobile-menu-btn" aria-label="\uba54\ub274\uc5f4\uae30">
      <span></span><span></span><span></span>
    </button>
  </div>
</header>

<!-- MOBILE MENU -->
<div id="mobile-menu" role="dialog" aria-modal="true" aria-label="\ubaa8\ubc14\uc77c \uba54\ub274">
  <div class="mobile-menu-inner">
    <div class="mobile-menu-header">
      <img src="../assets/img/logo-horizontal.png" alt="KCBMA" />
      <button class="mobile-close" id="mobile-close" aria-label="\uba54\ub274\ub2eb\uae30">\u2715</button>
    </div>
    <ul>
      <li><a href="../about/intro.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">\ud611\ud68c\uc18c\uac1c</a></li>
      <li class="mobile-nav-group">
        <details>
          <summary>\uc815\ubcf4\uad50\ub958</summary>
          <div class="mobile-nav-sub">
            <a href="../policy/law.html">\ubc95\uaddc\xb7\uc815\uccb5</a>
            <a href="../info/videos.html">\uc601\uc0c1 \uc790\ub8cc\uc2e4</a>
            <a href="../info/columns.html">\uc2dc\uc124\uc5c5\uccb4 \uce7c\ub7fc</a>
          </div>
        </details>
      </li>
      <li><a href="../info/forum.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">\uc815\ucc45\ud1a0\ub860</a></li>
      <li><a href="../jobs/list.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">\uad6c\uc778\uad6c\uc9c1</a></li>
      <li><a href="../info/sinmungo.html" class="mobile-nav-group" style="display:flex;align-items:center;justify-content:space-between;padding:14px 4px;color:#fff;font-size:1rem;font-weight:700;border-bottom:1px solid rgba(255,255,255,.1);">\uc815\ucc45\uc2e0\ubb38\uace0</a></li>
    </ul>
    <div class="mobile-cta-area">
      <a href="../partners/apply.html">\uad11\uace0 \ubb38\uc758</a>
      <a href="https://cafe.naver.com/kcbma114" target="_blank" style="background:rgba(255,255,255,.08);">\ub124\uc774\ubc84\uce74\ud398 \ubc14\ub85c\uac00\uae30</a>
    </div>
  </div>
</div>'''

# ── Active-class injection rules ───────────────────────────────────────────
ACTIVE_RULES = [
    # about/*  -> 협회소개
    (r'^about/', r'(<li>)(<a href="\.\./about/intro\.html">)'),
    # info/forum* -> 정책토론
    (r'^info/forum', r'(<li>)(<a href="\.\./info/forum\.html">)'),
    # jobs/* -> 구인구직
    (r'^jobs/', r'(<li>)(<a href="\.\./jobs/list\.html">)'),
    # info/sinmungo* -> 정책신문고
    (r'^info/sinmungo', r'(<li>)(<a href="\.\./info/sinmungo\.html">)'),
    # info/* and policy/* -> 정보교류 (the <li> with dropdown)
    (r'^(info|policy)/', r'(<li>)(\s*<a href="\.\./info/index\.html">)'),
    # partners/* -> no active class
]


def get_active_replacement(rel_path):
    for path_pat, li_pat in ACTIVE_RULES:
        if re.search(path_pat, rel_path):
            return li_pat, r'\1 class="active"\2'
    return None


def process_file(filepath, project_root):
    rel_path = os.path.relpath(filepath, project_root).replace(os.sep, '/')

    with open(filepath, 'r', encoding='utf-8-sig') as fh:
        original = fh.read()

    # Normalise to LF
    content = original.replace('\r\n', '\n').replace('\r', '\n')

    # Find start: locate util-bar div
    util_bar_match = re.search(r'[ \t]*<div class="util-bar"', content)
    if not util_bar_match:
        print(f'  {rel_path}: SKIPPED (no util-bar found)')
        return False

    start_pos = util_bar_match.start()

    # Walk backwards over preceding HTML comment lines
    comment_pat = re.compile(r'([ \t]*<!--[^\n]*-->\n)$')
    while True:
        prefix = content[:start_pos]
        cm = comment_pat.search(prefix)
        if cm:
            start_pos -= len(cm.group(1))
        else:
            break

    # Find id="mobile-menu" after startPos
    mobile_pos = content.find('id="mobile-menu"', start_pos)
    if mobile_pos < 0:
        print(f'  {rel_path}: SKIPPED (no mobile-menu found)')
        return False

    # Find triple closing </div> tags after mobile-menu
    triple_close = re.search(r'</div>\s*</div>\s*</div>', content[mobile_pos:], re.DOTALL)
    if not triple_close:
        print(f'  {rel_path}: SKIPPED (cannot find mobile-menu closing divs)')
        return False

    end_pos = mobile_pos + triple_close.end()

    # Consume trailing newlines
    while end_pos < len(content) and content[end_pos] == '\n':
        end_pos += 1

    # Build replacement with active class
    header_text = CANONICAL_HEADER
    result = get_active_replacement(rel_path)
    if result is not None:
        li_pat, replacement = result
        new_header, n_subs = re.subn(li_pat, replacement, header_text)
        if n_subs == 0:
            print(f'  WARNING: active-class pattern did not match for {rel_path}')
        else:
            header_text = new_header

    new_content = content[:start_pos] + header_text + '\n\n' + content[end_pos:]

    if new_content == content:
        print(f'  {rel_path}: SKIPPED (already up-to-date)')
        return False

    with open(filepath, 'w', encoding='utf-8') as fh:
        fh.write(new_content)

    print(f'  {rel_path}: OK')
    return True


def main():
    project_root = os.path.dirname(os.path.abspath(__file__))
    sub_dirs = ['about', 'info', 'jobs', 'partners', 'policy']

    html_files = []
    for sub in sub_dirs:
        sub_path = os.path.join(project_root, sub)
        if not os.path.isdir(sub_path):
            continue
        for fname in sorted(os.listdir(sub_path)):
            if fname.lower().endswith('.html'):
                html_files.append(os.path.join(sub_path, fname))

    print(f'Found {len(html_files)} sub-page HTML files.\n')

    changed = 0
    for fp in html_files:
        if process_file(fp, project_root):
            changed += 1

    print(f'\nDone. {changed}/{len(html_files)} files updated.')


if __name__ == '__main__':
    main()
