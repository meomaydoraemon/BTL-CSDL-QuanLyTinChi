/* Tiện ích dùng chung: toast thông báo và gửi POST kèm CSRF token */

function toast(ok, message, title) {
    let wrap = document.querySelector('.toast-wrap');
    if (!wrap) {
        wrap = document.createElement('div');
        wrap.className = 'toast-wrap';
        document.body.appendChild(wrap);
    }
    const el = document.createElement('div');
    el.className = 'toast-x' + (ok ? '' : ' loi');
    el.setAttribute('role', ok ? 'status' : 'alert');
    el.innerHTML =
        '<i class="t-icon bi ' + (ok ? 'bi-check-circle-fill' : 'bi-x-circle-fill') + '"></i>' +
        '<div><div class="t-title"></div><div class="t-msg"></div></div>' +
        '<button type="button" class="btn-close" aria-label="Đóng"></button>';
    el.querySelector('.t-title').textContent = title || (ok ? 'Thành công' : 'Không thực hiện được');
    el.querySelector('.t-msg').textContent = message;
    const close = () => { el.classList.add('hide'); setTimeout(() => el.remove(), 300); };
    el.querySelector('.btn-close').addEventListener('click', close);
    wrap.appendChild(el);
    setTimeout(close, ok ? 3500 : 6000);
}

async function postForm(url, data) {
    const token = document.querySelector('meta[name="_csrf"]').content;
    const header = document.querySelector('meta[name="_csrf_header"]').content;
    const res = await fetch(url, {
        method: 'POST',
        headers: { [header]: token, 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams(data)
    });
    if (!res.ok) {
        return { ok: false, message: 'Lỗi máy chủ (' + res.status + '). Vui lòng tải lại trang.' };
    }
    return res.json();
}

/* Tải lại các vùng [data-refresh] của trang hiện tại mà không reload toàn trang */
async function refreshRegions() {
    const res = await fetch(location.href);
    const doc = new DOMParser().parseFromString(await res.text(), 'text/html');
    document.querySelectorAll('[data-refresh]').forEach(el => {
        const moi = doc.querySelector('[data-refresh="' + el.dataset.refresh + '"]');
        if (moi) el.replaceWith(moi);
    });
    document.dispatchEvent(new Event('regions-refreshed'));
}

/* Toast từ server (flash attribute) */
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-toast]').forEach(el => toast(el.dataset.toast === 'ok', el.textContent));
});
