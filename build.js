// build.js
// -----------------------------------------------------------------------
// _partials/ 안의 공통 조각들을 pages/**/*.src.html 안의 <!-- @include 이름 -->
// 표시에 끼워 넣어서, 실제로 배포할 완성된 .html 파일을 만들어냅니다.
//
// ★ 중요: 이 조립은 "브라우저가 페이지를 열 때"가 아니라 "이 스크립트를
//   실행하는 시점"에 전부 끝납니다. 완성된 .html 파일은 그냥 평범한 정적
//   HTML이라서, 사용자가 접속할 때 fetch로 뭔가를 더 받아오지 않습니다.
//   → 시간차로 인한 흰 화면/울렁거림이 구조적으로 생길 수 없습니다.
//
// 사용법:
//   1) _partials/ 안의 파일(header.html, common-css.html 등)을 고친다.
//   2) 터미널에서:  node build.js
//   3) pages/ 아래의 .html 파일들이 전부 최신 상태로 다시 생성된다.
//   4) 생성된 .html 파일들만 서버에 올린다. (.src.html, _partials, build.js는
//      올릴 필요 없음 — 소스 관리용)
// -----------------------------------------------------------------------

const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const PARTIALS_DIR = path.join(ROOT, '_partials');

// ★ v4: pages/ 뿐 아니라 사이트 루트(index.html, login.html 등)도 스캔하도록
//   확장. _partials 폴더는 파샬 원본이라 빌드 대상에서 제외.
function findSrcFiles(dir, results = []) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.name === '_partials' || entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            findSrcFiles(full, results);
        } else if (entry.name.endsWith('.src.html')) {
            results.push(full);
        }
    }
    return results;
}

function loadPartials() {
    const partials = {};
    for (const file of fs.readdirSync(PARTIALS_DIR)) {
        if (file.endsWith('.html')) {
            const name = file.replace(/\.html$/, '');
            partials[name] = fs.readFileSync(path.join(PARTIALS_DIR, file), 'utf8');
        }
    }
    return partials;
}


// -----------------------------------------------------------------------
// ★ 2026-11: 검색 노출(SEO) 태그 자동 삽입
//   - 모든 페이지 <title> 바로 뒤에 설명(description)·카톡/페이스북 미리보기(og)·
//     파비콘을 넣습니다. 페이지에서 직접 고칠 필요 없음 — 여기 표만 고치면 됨.
//   - 관리자·마이페이지·글쓰기 같은 페이지는 검색엔진에 안 나오게(noindex) 처리.
//   - 빌드할 때마다 sitemap.xml(검색엔진용 페이지 목록)도 새로 만듭니다.
// -----------------------------------------------------------------------
const SITE_URL = 'https://www.kcbma.org';
const SITE_NAME = '대한집합건물관리협회';
const DEFAULT_DESC = '대한집합건물관리협회(KCBMA) — 집합건물 관리 전문가와 관리단을 잇는 협회입니다. 구인구직, 견적의뢰, 실무 교육, 관리단 코너, 지식컨설팅, 24시간 긴급 SOS 출동을 한곳에서 이용하세요.';

// 페이지별 설명 (경로: 설명). 여기 없는 페이지는 폴더별 기본 설명 → 사이트 기본 설명 순서로 사용.
const PAGE_DESC = {
    'index.html': DEFAULT_DESC,
    'about/about.html': '대한집합건물관리협회(KCBMA) 소개 — 설립 목적, 주요 사업, 연혁과 오시는 길을 안내합니다.',
    'jobs/job-list.html': '집합건물·아파트·오피스텔 관리소장, 시설·전기·경리·미화 등 건물관리 분야 채용정보를 지역별로 찾아보세요.',
    'jobs/resume-list.html': '건물관리 경력자와 신입 구직자의 이력서를 지역·분야별로 살펴보고 인재를 찾으세요.',
    'bid/bid-list.html': '집합건물 관리·용역·공사 견적의뢰를 지역·분야별로 확인하고 참여하세요.',
    'bid/joint-bid.html': '여러 관리단이 함께 우수업체를 공동 선정해 더 좋은 조건으로 계약하는 공동선정 공고입니다.',
    'bid/company-ads.html': '건물관리·시설·청소·보안 등 협력업체 정보를 한눈에 비교하는 협력업체 홍보관입니다.',
    'board/board-corner.html': '관리단을 위한 위탁관리사 선정 공고 — 공고를 올리면 여러 관리 전문업체와 연결됩니다.',
    'board/evote-list.html': '집합건물 관리단 총회·전자투표 대행 전문가를 찾고 매칭받으세요.',
    'board/fee-list.html': '우리 건물 관리비가 적정한지 전문가에게 비교·평가를 의뢰하세요.',
    'cert/cert-list.html': '현장 실무 중심의 건물관리 교육과정 — 온라인 강의와 시험으로 실력을 증명하세요.',
    'cert/edu-field-list.html': '현장에서 직접 배우는 건물관리 실습 교육 일정을 확인하고 신청하세요.',
    'cert/cert-verify.html': '대한집합건물관리협회에서 발급한 수료증의 진위를 수료증 번호로 확인합니다.',
    'community/notice.html': '대한집합건물관리협회의 새 소식과 공지사항입니다.',
    'community/free-board.html': '건물관리 종사자와 관리단이 자유롭게 소통하는 자유게시판입니다.',
    'community/data-room.html': '건물관리 업무에 필요한 서식과 자료를 내려받으세요.',
    'consulting/consulting-field.html': '건물관리 현장에서 겪은 경험과 해결 노하우를 공유하는 현장경험 게시판입니다.',
    'consulting/consulting-free.html': '건물관리 실무 궁금증을 무료로 묻고 경험자의 답변을 받으세요.',
    'consulting/consulting-paid.html': '내공(포인트)을 걸고 건물관리 전문가에게 깊이 있는 답변을 받으세요.',
    'sos/sos-request.html': '정전·누수·화재경보 등 건물 비상상황 발생 시 24시간 긴급 SOS 호출 — 전화상담, 전문가 조언, 긴급출동을 연결합니다.',
    'sos/sos-partner-apply.html': '긴급 SOS 파트너 전문가로 지원하고 건물 비상상황 출동·상담에 참여하세요.',
    'policy/terms.html': '대한집합건물관리협회 서비스 이용약관 — 회원 가입, 서비스별 이용 조건, 포인트 환불 기준을 안내합니다.',
    'policy/privacy.html': '대한집합건물관리협회 개인정보처리방침 — 수집 항목, 이용 목적, 보유 기간, 위탁·국외 이전, 정보주체의 권리를 안내합니다.',
};
const FOLDER_DESC = {
    'jobs': '건물관리 분야 채용·구직 정보 — 대한집합건물관리협회 구인구직.',
    'bid': '집합건물 관리·용역 견적의뢰와 협력업체 정보 — 대한집합건물관리협회.',
    'board': '관리단을 위한 위탁관리·총회·관리비 평가 전문가 매칭 — 대한집합건물관리협회 관리단 코너.',
    'cert': '건물관리 교육과정과 현장 교육 — 대한집합건물관리협회.',
    'community': '대한집합건물관리협회 커뮤니티 — 공지사항, 자유게시판, 서식/자료실.',
    'consulting': '건물관리 실무 질문과 현장경험 공유 — 대한집합건물관리협회 지식컨설팅.',
    'sos': '24시간 건물 긴급 SOS 호출 — 대한집합건물관리협회.',
};

// 검색엔진에 내보내지 않을 페이지 (회원 전용·관리자·작성 화면 등)
function isNoIndex(rel) {
    if (/^(admin|mypage)\//.test(rel)) return true;
    if (/-(write|edit)\.html$/.test(rel)) return true;
    return [
        'login.html', 'callback.html',
        'sos/sos-room.html', 'sos/sos-standby.html', 'sos/sos-recharge.html', 'sos/sos-company.html',
        'sos/sos-expert-menu.html', 'sos/sos-expert-profile.html', 'sos/sos-expert-scope.html',
        'cert/cert-player.html', 'cert/cert-exam.html', 'cert/cert-enroll.html',
    ].includes(rel);
}
// 상세 페이지(?id= 로 내용이 바뀜): 검색은 허용하되 대표주소(canonical)·사이트맵에서는 제외
function isDetail(rel) { return /-detail\.html$/.test(rel); }

function escAttr(v) { return String(v).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;'); }

function buildSeoTags(rel, html) {
    const t = (html.match(/<title>([^<]*)<\/title>/) || [])[1] || SITE_NAME;
    const title = t.trim();
    const folder = rel.includes('/') ? rel.split('/')[0] : '';
    const desc = PAGE_DESC[rel] || FOLDER_DESC[folder] || DEFAULT_DESC;
    const url = SITE_URL + '/' + (rel === 'index.html' ? '' : rel);
    const noindex = isNoIndex(rel);
    const L = [];
    L.push('    <!-- [SEO] build.js가 자동으로 넣음 — 고치려면 build.js의 PAGE_DESC 표를 고칠 것 -->');
    L.push(`    <meta name="description" content="${escAttr(desc)}">`);
    if (noindex) L.push('    <meta name="robots" content="noindex, nofollow">');
    if (!noindex && !isDetail(rel)) L.push(`    <link rel="canonical" href="${url}">`);
    L.push('    <meta property="og:type" content="website">');
    L.push(`    <meta property="og:site_name" content="${SITE_NAME}">`);
    L.push(`    <meta property="og:title" content="${escAttr(title)}">`);
    L.push(`    <meta property="og:description" content="${escAttr(desc)}">`);
    if (!isDetail(rel)) L.push(`    <meta property="og:url" content="${url}">`);
    L.push(`    <meta property="og:image" content="${SITE_URL}/assets/img/og-image.jpg">`);
    L.push('    <meta property="og:image:width" content="1200">');
    L.push('    <meta property="og:image:height" content="630">');
    L.push('    <meta property="og:locale" content="ko_KR">');
    L.push('    <meta name="twitter:card" content="summary_large_image">');
    L.push('    <meta name="theme-color" content="#12387a">');
    L.push('    <link rel="icon" href="/favicon.ico" sizes="any">');
    L.push('    <link rel="icon" type="image/png" sizes="32x32" href="/assets/img/favicon-32.png">');
    L.push('    <link rel="apple-touch-icon" href="/apple-touch-icon.png">');
    return { tags: L.join('\n'), noindex };
}

function injectSeo(rel, html) {
    if (html.includes('[SEO] build.js')) return { html, noindex: isNoIndex(rel) };
    const { tags, noindex } = buildSeoTags(rel, html);
    // 예전에 404 방지용으로 넣어둔 빈 파비콘은 진짜 파비콘으로 대체되므로 삭제
    html = html.replace(/[ \t]*<link rel="icon" href="data:,">\r?\n?/g, '');
    if (/<\/title>/.test(html)) html = html.replace(/<\/title>/, '</title>\n' + tags);
    else html = html.replace(/<head>/i, '<head>\n' + tags);
    return { html, noindex };
}

function writeSitemap(pages) {
    const today = new Date().toISOString().slice(0, 10);
    const order = p => (p === 'index.html' ? 0 : 1);
    const urls = pages.sort((a, b) => order(a) - order(b) || a.localeCompare(b)).map(rel => {
        const loc = SITE_URL + '/' + (rel === 'index.html' ? '' : rel);
        const pri = rel === 'index.html' ? '1.0' : (/list|board-corner|request|joint-bid\.html|notice\.html|free-board\.html/.test(rel) ? '0.8' : '0.6');
        return `  <url><loc>${loc}</loc><lastmod>${today}</lastmod><priority>${pri}</priority></url>`;
    });
    const xml = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + urls.join('\n') + '\n</urlset>\n';
    fs.writeFileSync(path.join(ROOT, 'sitemap.xml'), xml, 'utf8');
    console.log(`✔ sitemap.xml (${urls.length}개 주소)`);
}

function build() {
    if (!fs.existsSync(PARTIALS_DIR)) {
        console.error(`❌ _partials 폴더를 찾을 수 없습니다: ${PARTIALS_DIR}`);
        process.exit(1);
    }

    const partials = loadPartials();
    const srcFiles = findSrcFiles(ROOT);

    if (srcFiles.length === 0) {
        console.warn('⚠ 빌드할 .src.html 파일이 없습니다.');
        return;
    }

    let count = 0;
    const sitemapPages = [];
    for (const srcPath of srcFiles) {
        let content = fs.readFileSync(srcPath, 'utf8');

        // 1) @var 선언 수집: <!-- @var 이름: 값 -->  (결과물에서는 삭제됨)
        const vars = {};
        content = content.replace(/[ \t]*<!--\s*@var\s+([A-Z0-9_]+)\s*:\s*(.*?)\s*-->\n?/g, (m, key, val) => {
            vars[key] = val;
            return '';
        });

        // 2) @include 치환: <!-- @include 이름 -->
        content = content.replace(/<!--\s*@include\s+([\w-]+)\s*-->/g, (m, name) => {
            if (!(name in partials)) {
                throw new Error(`[${path.relative(ROOT, srcPath)}] "${name}" 파샬을 찾을 수 없습니다. _partials/${name}.html 이 있는지 확인하세요.`);
            }
            return partials[name];
        });

        // 3) {{변수}} 치환
        content = content.replace(/\{\{([A-Z0-9_]+)\}\}/g, (m, key) => {
            if (!(key in vars)) {
                throw new Error(`[${path.relative(ROOT, srcPath)}] {{${key}}} 를 채울 @var ${key} 선언이 없습니다.`);
            }
            return vars[key];
        });

        const outPath = srcPath.replace(/\.src\.html$/, '.html');
        const rel = path.relative(ROOT, outPath).split(path.sep).join('/');
        const seo = injectSeo(rel, content);
        content = seo.html;
        if (!seo.noindex && !isDetail(rel)) sitemapPages.push(rel);
        fs.writeFileSync(outPath, content, 'utf8');
        console.log(`✔ ${path.relative(ROOT, srcPath)} → ${path.relative(ROOT, outPath)}`);
        count++;
    }

    writeSitemap(sitemapPages);
    console.log(`\n총 ${count}개 페이지 빌드 완료.`);
}

build();
