/* =====================================================================
   지식컨설팅 게시판 공통 스크립트 (consulting-board.js)
   - 현장경험(FIELD) / 무보상 질문(FREE) / 내공 질문(PAID)
   - DB: consult_posts, consult_answers (consulting_setup.sql)
   - 페이지에서 supabase-js + supabase-config.js 를 먼저 불러와야 합니다.
   ===================================================================== */
(function () {
    'use strict';

    const TYPES = {
        FIELD: { name: '현장경험', list: 'consulting-field.html', write: 'consulting-field-write.html', detail: 'consulting-field-detail.html', answerWord: '댓글' },
        FREE:  { name: '무보상 질문', list: 'consulting-free.html',  write: 'consulting-free-write.html',  detail: 'consulting-free-detail.html',  answerWord: '답변' },
        PAID:  { name: '내공 질문', list: 'consulting-paid.html',  write: 'consulting-paid-write.html',  detail: 'consulting-paid-detail.html',  answerWord: '답변' }
    };

    // ---------- 공통 유틸 ----------
    function esc(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    function client() {
        if (window.sb) return window.sb;
        if (window.supabase && typeof SUPABASE_URL !== 'undefined') {
            window.sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
            return window.sb;
        }
        return null;
    }

    async function getUser() {
        const sb = client();
        if (!sb) return null;
        const { data } = await sb.auth.getSession();
        return data && data.session ? data.session.user : null;
    }

    function isAdminUser(user) {
        return !!(user && user.app_metadata && user.app_metadata.role === 'admin');
    }

    function goLogin(message) {
        alert(message || '로그인이 필요합니다.');
        try { localStorage.setItem('returnUrl', location.pathname + location.search); } catch (e) {}
        location.href = '/login.html';
    }

    function qs(name) {
        return new URLSearchParams(location.search).get(name);
    }

    function pad(n) { return String(n).padStart(2, '0'); }

    function fmtDateTime(iso) {
        const d = new Date(iso);
        if (isNaN(d)) return '';
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
    }

    function errMsg(error) {
        if (!error) return '알 수 없는 오류';
        return error.message || error.details || String(error);
    }

    // ---------- 목록 ----------
    // 현장경험 목록에는 '답변완료된 무보상 질문'도 함께 보여줍니다(작성 화면 안내 문구대로).
    async function fetchList(type) {
        const sb = client();
        if (!sb) throw new Error('데이터베이스 연결에 실패했습니다.');

        let query = sb.from('consult_posts')
            .select('id, post_type, category, region, title, author_name, reward_points, status, view_count, like_count, created_at')
            .order('created_at', { ascending: false });

        if (type === 'FIELD') {
            query = query.or('post_type.eq.FIELD,and(post_type.eq.FREE,status.eq.DONE)');
        } else {
            query = query.eq('post_type', type);
        }

        const { data, error } = await query;
        if (error) throw error;

        return (data || []).map(row => ({
            id: row.id,
            type: row.post_type,
            category: row.category || '기타',
            region: row.region || '',
            title: row.title,
            author: row.author_name || '',
            bounty: row.reward_points || 0,
            answered: row.status === 'DONE',
            views: row.view_count || 0,
            likes: row.like_count || 0,
            created_at: row.created_at
        }));
    }

    function listRowHtml(item, number) {
        let badges = '';
        if (item.type === 'FREE') {
            badges += '<span class="qna-badge badge-free">무료</span>';
        } else if (item.type === 'PAID') {
            badges += `<span class="qna-badge badge-paid">💰 ${Number(item.bounty).toLocaleString()}P</span>`;
        }
        if (item.type !== 'FIELD') {
            badges += item.answered
                ? '<span class="qna-badge badge-answered">답변완료</span>'
                : '<span class="qna-badge badge-waiting">답변대기</span>';
        }

        let shortDate = '';
        const d = new Date(item.created_at);
        if (!isNaN(d)) shortDate = `${d.getMonth() + 1}/${d.getDate()}`;

        const detailUrl = TYPES[item.type].detail + '?id=' + encodeURIComponent(item.id);

        return `
            <tr class="cursor-pointer" onclick="location.href='${detailUrl}'">
                <td class="text-center">${number}</td>
                <td class="text-left pl-4 max-w-0">
                    <div class="flex items-center w-full">
                        <div class="shrink-0 flex items-center">${badges}</div>
                        <span class="font-bold text-[#0B2A5B] hover:underline truncate block w-full text-left">${esc(item.title)}</span>
                    </div>
                </td>
                <td class="text-center text-[13px] text-gray-500">${esc(item.region || '-')}</td>
                <td class="text-center text-[13px]">${esc(item.category)}</td>
                <td class="text-center text-[13px]">${shortDate}</td>
                <td class="text-center">${Number(item.views).toLocaleString()}</td>
            </tr>`;
    }

    async function goWrite(type) {
        const user = await getUser();
        if (!user) { goLogin('글을 쓰려면 로그인이 필요합니다.'); return; }
        location.href = TYPES[type].write;
    }

    // ---------- 글쓰기 / 수정 ----------
    function fillRegionSelects(majorSel, minorSel, value) {
        const regionList = (typeof regions !== 'undefined') ? regions : [];
        const subs = (typeof subRegionData !== 'undefined') ? subRegionData : {};

        majorSel.innerHTML = '<option value="">시/도 선택</option>' +
            regionList.map(r => `<option value="${esc(r)}">${esc(r === '전국' ? '전국(지역무관)' : r)}</option>`).join('');

        function fillMinor(major, selected) {
            const list = (subs[major] || []).filter(m => m.replace(/\s/g, '') !== `${major}전체` && m !== '전국전체');
            minorSel.innerHTML = '<option value="">시/군/구 (선택)</option>' +
                list.map(m => `<option value="${esc(m)}">${esc(m)}</option>`).join('');
            minorSel.disabled = !major || major === '전국' || list.length === 0;
            if (selected) minorSel.value = selected;
        }

        majorSel.addEventListener('change', () => fillMinor(majorSel.value, ''));

        if (value) {
            const parts = value.split(' ');
            const major = parts[0] === '전국' ? '전국' : parts[0];
            majorSel.value = major;
            fillMinor(major, parts.slice(1).join(' '));
        } else {
            fillMinor('', '');
        }
    }

    function readRegion(majorSel, minorSel) {
        const major = majorSel.value;
        if (!major) return '';
        if (major === '전국') return '전국';
        return minorSel.value ? `${major} ${minorSel.value}` : major;
    }

    async function initWrite(type) {
        const info = TYPES[type];
        const form = document.getElementById('consult-write-form');
        const els = {
            category: document.getElementById('f-category'),
            major: document.getElementById('f-region-major'),
            minor: document.getElementById('f-region-minor'),
            title: document.getElementById('f-title'),
            content: document.getElementById('f-content'),
            reward: document.getElementById('reward-points'),
            agree: document.getElementById('agree-share'),
            points: document.getElementById('current-points'),
            heading: document.getElementById('write-heading'),
            submit: document.getElementById('write-submit-btn'),
            pointSection: document.getElementById('point-section')
        };

        const user = await getUser();
        if (!user) { goLogin('글을 쓰려면 로그인이 필요합니다.'); return; }

        const sb = client();
        const editId = qs('id');
        let editing = null;

        if (editId) {
            const { data, error } = await sb.from('consult_posts').select('*').eq('id', editId).maybeSingle();
            if (error || !data) { alert('글을 찾을 수 없습니다.'); location.href = info.list; return; }
            if (data.user_id !== user.id && !isAdminUser(user)) {
                alert('본인이 작성한 글만 수정할 수 있습니다.');
                location.href = info.detail + '?id=' + encodeURIComponent(editId);
                return;
            }
            editing = data;
        }

        fillRegionSelects(els.major, els.minor, editing ? editing.region : '');

        if (editing) {
            els.category.value = editing.category || '';
            els.title.value = editing.title || '';
            els.content.value = editing.content || '';
            if (els.heading) els.heading.textContent = info.name + ' 수정하기';
            if (els.submit) els.submit.textContent = '수정 완료';
            if (els.pointSection) els.pointSection.style.display = 'none';
            if (els.agree) els.agree.disabled = true;
        } else if (type === 'PAID' && els.points) {
            const { data: pts } = await sb.rpc('consult_my_points');
            els.points.textContent = Number(pts || 0).toLocaleString();
        }

        let busy = false;
        async function submit() {
            if (busy) return;
            const category = els.category.value;
            const region = readRegion(els.major, els.minor);
            const title = els.title.value.trim();
            const content = els.content.value.trim();

            if (!category) { alert('분류를 선택해 주세요.'); els.category.focus(); return; }
            if (!title) { alert('제목을 입력해 주세요.'); els.title.focus(); return; }
            if (title.length > 100) { alert('제목은 100자 이내로 입력해 주세요.'); els.title.focus(); return; }
            if (!content) { alert('내용을 입력해 주세요.'); els.content.focus(); return; }

            busy = true;
            const originalText = els.submit ? els.submit.textContent : '';
            if (els.submit) els.submit.textContent = '처리 중...';

            try {
                let postId;
                if (editing) {
                    const { data, error } = await sb.from('consult_posts')
                        .update({ category, region, title, content })
                        .eq('id', editing.id)
                        .select('id');
                    if (error) throw error;
                    if (!data || data.length === 0) throw new Error('수정 권한이 없습니다.');
                    postId = editing.id;
                    alert('수정되었습니다.');
                } else if (type === 'PAID') {
                    const reward = parseInt(els.reward.value, 10);
                    if (isNaN(reward) || reward <= 0) {
                        alert('걸고자 하는 내공 포인트를 1P 이상 입력해 주세요.');
                        els.reward.focus();
                        busy = false;
                        if (els.submit) els.submit.textContent = originalText;
                        return;
                    }
                    if (!confirm(`${reward.toLocaleString()}P를 걸고 질문을 등록합니다.\n(채택 시 답변자에게 지급, 답변 없이 삭제하면 환불)`)) {
                        busy = false;
                        if (els.submit) els.submit.textContent = originalText;
                        return;
                    }
                    const { data, error } = await sb.rpc('consult_create_paid_post', {
                        p_category: category, p_region: region, p_title: title, p_content: content,
                        p_reward: reward, p_share_agreed: !!(els.agree && els.agree.checked)
                    });
                    if (error) throw error;
                    postId = data;
                    alert('내공 질문이 등록되었습니다.');
                } else {
                    const { data, error } = await sb.from('consult_posts')
                        .insert([{ post_type: type, category, region, title, content, share_agreed: type === 'FREE' }])
                        .select('id')
                        .single();
                    if (error) throw error;
                    postId = data.id;
                    alert('등록되었습니다.');
                }
                location.href = info.detail + '?id=' + encodeURIComponent(postId);
            } catch (error) {
                console.error('등록 오류:', error);
                alert('처리 중 문제가 발생했습니다: ' + errMsg(error));
                busy = false;
                if (els.submit) els.submit.textContent = originalText;
            }
        }

        window.submitForm = submit;
        if (form) form.addEventListener('submit', (e) => { e.preventDefault(); submit(); });
    }

    // ---------- 상세 ----------
    async function initDetail(type) {
        const info = TYPES[type];
        const sb = client();
        const id = qs('id');
        const $ = (sel) => document.getElementById(sel);

        if (!id || !sb) { alert('잘못된 접근입니다.'); location.href = info.list; return; }

        const user = await getUser();
        const admin = isAdminUser(user);

        const { data: post, error } = await sb.from('consult_posts').select('*').eq('id', id).maybeSingle();
        if (error || !post) { alert('글을 찾을 수 없습니다.'); location.href = info.list; return; }

        // 다른 게시판 글이면 맞는 상세 화면으로 이동 (현장경험 목록의 무보상 질문 등)
        if (post.post_type !== type) {
            location.replace(TYPES[post.post_type].detail + '?id=' + encodeURIComponent(id));
            return;
        }

        // 조회수 (같은 브라우저에서 하루 1회)
        try {
            const key = 'consult_viewed_' + id;
            const today = new Date().toDateString();
            if (localStorage.getItem(key) !== today) {
                localStorage.setItem(key, today);
                sb.rpc('consult_increment_view', { p_id: Number(id) }).then(() => {});
                post.view_count = (post.view_count || 0) + 1;
            }
        } catch (e) {}

        // 머리말
        function renderBadges() {
            let badges = '';
            if (type === 'FREE') badges += '<span class="qna-badge badge-free">무료</span>';
            if (type === 'PAID') badges += `<span class="qna-badge badge-paid">💰 내공 ${Number(post.reward_points).toLocaleString()}P</span>`;
            if (type !== 'FIELD') {
                badges += post.status === 'DONE'
                    ? '<span class="qna-badge badge-answered">답변완료</span>'
                    : '<span class="qna-badge badge-waiting">답변대기</span>';
            }
            $('d-badges').innerHTML = badges;
        }
        renderBadges();
        $('d-meta').textContent = [post.category, post.region].filter(Boolean).join(' / ');
        $('d-title').textContent = post.title;
        $('d-author').textContent = post.author_name || '회원';
        $('d-date').textContent = fmtDateTime(post.created_at);
        $('d-views').textContent = Number(post.view_count || 0).toLocaleString();
        $('d-likes').textContent = Number(post.like_count || 0).toLocaleString();
        $('d-content').textContent = post.content;
        document.title = post.title + ' | 지식컨설팅';

        // 관심(하트)
        const likeKey = 'consult_liked_' + id;
        const likeBtn = $('d-like-btn');
        const markLiked = () => { if (likeBtn) likeBtn.style.color = '#ef4444'; };
        try { if (localStorage.getItem(likeKey)) markLiked(); } catch (e) {}
        if (likeBtn) {
            likeBtn.addEventListener('click', async () => {
                try { if (localStorage.getItem(likeKey)) { alert('이미 관심을 표시한 글입니다.'); return; } } catch (e) {}
                const { data, error: likeErr } = await sb.rpc('consult_like', { p_id: Number(id) });
                if (likeErr) { alert('처리 중 오류가 발생했습니다.'); return; }
                try { localStorage.setItem(likeKey, '1'); } catch (e) {}
                $('d-likes').textContent = Number(data || 0).toLocaleString();
                markLiked();
            });
        }

        // 수정/삭제 버튼
        const isOwner = !!(user && post.user_id && post.user_id === user.id);
        const editBtn = $('d-edit-btn');
        const delBtn = $('d-delete-btn');
        if (editBtn) {
            editBtn.style.display = (isOwner || admin) ? '' : 'none';
            editBtn.addEventListener('click', () => { location.href = info.write + '?id=' + encodeURIComponent(id); });
        }
        if (delBtn) {
            delBtn.style.display = (isOwner || admin) ? '' : 'none';
            delBtn.addEventListener('click', async () => {
                let msg = '정말로 이 글을 삭제하시겠습니까?';
                if (type === 'PAID' && !post.accepted_answer_id) msg += `\n(걸어둔 내공 ${Number(post.reward_points).toLocaleString()}P는 환불됩니다)`;
                if (!confirm(msg)) return;
                const { error: delErr } = await sb.rpc('consult_delete_post', { p_id: Number(id) });
                if (delErr) { alert(errMsg(delErr)); return; }
                alert('삭제되었습니다.');
                location.href = info.list;
            });
        }

        // 답변/댓글
        async function loadAnswers() {
            const { data: answers, error: ansErr } = await sb.from('consult_answers')
                .select('id, user_id, author_name, content, is_accepted, created_at')
                .eq('post_id', id)
                .order('created_at', { ascending: true });
            if (ansErr) { console.error(ansErr); return; }

            const list = answers || [];
            $('d-answer-count').textContent = list.length;
            const canAccept = type === 'PAID' && isOwner && !post.accepted_answer_id;

            if (list.length === 0) {
                $('d-answers').innerHTML = `<div class="bg-white border border-gray-200 rounded p-6 mb-4 shadow-sm text-[14.5px] text-gray-500 text-center">아직 등록된 ${info.answerWord}이 없습니다.</div>`;
                return;
            }

            $('d-answers').innerHTML = list.map(a => {
                const initial = esc((a.author_name || '회').charAt(0));
                const accepted = a.is_accepted
                    ? '<span class="qna-badge badge-answered">✔ 채택된 답변</span>' : '';
                const acceptBtn = (canAccept && a.user_id && a.user_id !== post.user_id)
                    ? `<button type="button" data-accept="${a.id}" class="text-[13px] font-bold border border-[#0B2A5B] text-[#0B2A5B] px-4 py-1.5 rounded hover:bg-blue-50 transition-colors">내공 채택하기</button>` : '';
                const delAnswerBtn = (user && ((a.user_id === user.id && !a.is_accepted) || admin))
                    ? `<button type="button" data-del-answer="${a.id}" class="text-[13px] font-bold border border-red-300 text-red-500 px-4 py-1.5 rounded hover:bg-red-50 transition-colors">삭제</button>` : '';
                return `
                <div class="bg-white border border-gray-200 rounded p-6 mb-4 shadow-sm">
                    <div class="flex flex-wrap justify-between items-start mb-4 border-b border-gray-100 pb-4">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center font-bold text-lg">${initial}</div>
                            <div>
                                <div class="font-bold text-gray-800 text-[15px]">${esc(a.author_name || '회원')} ${accepted}</div>
                                <div class="text-[12.5px] text-gray-400 mt-0.5">${fmtDateTime(a.created_at)}</div>
                            </div>
                        </div>
                        <div class="flex gap-2">${acceptBtn}${delAnswerBtn}</div>
                    </div>
                    <div class="text-[14.5px] text-gray-700 leading-loose whitespace-pre-line" data-answer-body="${a.id}"></div>
                </div>`;
            }).join('');

            list.forEach(a => {
                const body = document.querySelector(`[data-answer-body="${a.id}"]`);
                if (body) body.textContent = a.content;
            });

            document.querySelectorAll('[data-accept]').forEach(btn => {
                btn.addEventListener('click', async () => {
                    if (!confirm(`이 답변을 채택하고 내공 ${Number(post.reward_points).toLocaleString()}P를 지급하시겠습니까?\n채택은 취소할 수 없습니다.`)) return;
                    const { error: accErr } = await sb.rpc('consult_accept_answer', { p_answer_id: Number(btn.dataset.accept) });
                    if (accErr) { alert(errMsg(accErr)); return; }
                    alert('채택되었습니다. 답변자에게 내공이 지급되었습니다.');
                    location.reload();
                });
            });

            document.querySelectorAll('[data-del-answer]').forEach(btn => {
                btn.addEventListener('click', async () => {
                    if (!confirm(`이 ${info.answerWord}을 삭제하시겠습니까?`)) return;
                    const { data: deleted, error: dErr } = await sb.from('consult_answers')
                        .delete().eq('id', btn.dataset.delAnswer).select('id');
                    if (dErr || !deleted || deleted.length === 0) { alert('삭제할 수 없습니다.'); return; }
                    loadAnswers();
                });
            });
        }

        await loadAnswers();

        // 답변/댓글 등록
        const answerInput = $('d-answer-input');
        const answerBtn = $('d-answer-submit');
        if (answerInput && !user) {
            answerInput.placeholder = `${info.answerWord}을 쓰려면 로그인이 필요합니다. (클릭하면 로그인 화면으로 이동)`;
            answerInput.readOnly = true;
            answerInput.addEventListener('click', () => goLogin(`${info.answerWord}을 쓰려면 로그인이 필요합니다.`));
        }
        if (answerBtn) {
            let sending = false;
            answerBtn.addEventListener('click', async () => {
                if (!user) { goLogin(`${info.answerWord}을 쓰려면 로그인이 필요합니다.`); return; }
                const text = answerInput.value.trim();
                if (!text) { alert(`${info.answerWord} 내용을 입력해 주세요.`); answerInput.focus(); return; }
                if (sending) return;
                sending = true;
                const { error: insErr } = await sb.from('consult_answers').insert([{ post_id: Number(id), content: text }]);
                sending = false;
                if (insErr) { alert('등록 중 오류가 발생했습니다: ' + errMsg(insErr)); return; }
                answerInput.value = '';
                if (type === 'FREE') { post.status = 'DONE'; renderBadges(); }
                loadAnswers();
            });
        }
    }

    window.ConsultBoard = { TYPES, esc, fetchList, listRowHtml, goWrite, initWrite, initDetail };
})();
