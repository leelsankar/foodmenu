// Service worker — cache-first for app shell, network-first for JSON data
const CACHE = 'family-menu-v1';
const APP_SHELL = ['/foodmenu/', '/foodmenu/index.html', '/foodmenu/menus.json', '/foodmenu/ingredients.json'];

self.addEventListener('install', e => {
    e.waitUntil(
        caches.open(CACHE).then(c => c.addAll(APP_SHELL)).then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', e => {
    e.waitUntil(
        caches.keys().then(keys =>
            Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
        ).then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', e => {
    const url = new URL(e.request.url);
    // Network-first for JSON (keeps data fresh)
    if (url.pathname.endsWith('.json')) {
        e.respondWith(
            fetch(e.request)
                .then(r => { const c = r.clone(); caches.open(CACHE).then(cache => cache.put(e.request, c)); return r; })
                .catch(() => caches.match(e.request))
        );
        return;
    }
    // Cache-first for everything else
    e.respondWith(
        caches.match(e.request).then(cached => cached || fetch(e.request).then(r => {
            if (r.ok) caches.open(CACHE).then(c => c.put(e.request, r.clone()));
            return r;
        }))
    );
});
