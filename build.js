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
        fs.writeFileSync(outPath, content, 'utf8');
        console.log(`✔ ${path.relative(ROOT, srcPath)} → ${path.relative(ROOT, outPath)}`);
        count++;
    }

    console.log(`\n총 ${count}개 페이지 빌드 완료.`);
}

build();
