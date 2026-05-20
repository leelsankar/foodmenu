// Service Worker — network-first for HTML so updates land immediately,
// cache-first with background refresh for static assets (fonts/icons),
// network-first for JSON data.
const CACHE = 'family-menu-v5';
const OFFLINE_SHELL = ['/foodmenu/index.html', '/foodmenu/menus.json', '/foodmenu/ingredients.json'];

// ── Install: pre-cache the shell so the app works fully offline ──────────────
self.addEventListener('install', e => {
    e.waitUntil(
        caches.open(CACHE)
            .then(c => c.addAll(OFFLINE_SHELL))
            .then(() => self.skipWaiting())  // activate immediately, don't wait
    );
});

// ── Activate: delete every old cache version ─────────────────────────────────
self.addEventListener('activate', e => {
    e.waitUntil(
        caches.keys()
            .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
            .then(() => self.clients.claim())  // take control of all open tabs now
    );
});

// ── Fetch strategy ────────────────────────────────────────────────────────────
self.addEventListener('fetch', e => {
    const { request } = e;
    const url = new URL(request.url);

    // Only handle same-origin requests under /foodmenu/
    if (!url.pathname.startsWith('/foodmenu')) return;

    // ① HTML — always try network first so new deploys are visible immediately.
    //    Fall back to cache only when offline.
    if (request.mode === 'navigate' || url.pathname.endsWith('.html') || url.pathname === '/foodmenu/') {
        e.respondWith(
            fetch(request)
                .then(res => {
                    const copy = res.clone();
                    caches.open(CACHE).then(c => c.put(request, copy));
                    return res;
                })
                .catch(() => caches.match('/foodmenu/index.html'))
        );
        return;
    }

    // ② JSON data — network first, cache as fallback.
    if (url.pathname.endsWith('.json')) {
        e.respondWith(
            fetch(request)
                .then(res => {
                    const copy = res.clone();
                    caches.open(CACHE).then(c => c.put(request, copy));
                    return res;
                })
                .catch(() => caches.match(request))
        );
        return;
    }

    // ③ Everything else (fonts, icons, CDN scripts) — cache first, but update
    //    in the background so next visit is always fresh.
    e.respondWith(
        caches.open(CACHE).then(cache =>
            cache.match(request).then(cached => {
                const networkFetch = fetch(request).then(res => {
                    if (res.ok) cache.put(request, res.clone());
                    return res;
                });
                return cached || networkFetch;
            })
        )
    );
});
