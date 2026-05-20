# How to host Family Menu

This app is a **static site**: `index.html` plus JSON data files. You need a simple web server (not `file://`) so the browser can load `menus.json` and `ingredients.json`.

## Files to upload (all required)

| File | Purpose |
|------|---------|
| `index.html` | App UI and all logic |
| `menus.json` | All 661 dish lists |
| `ingredients.json` | Ingredients per dish (479 entries) |
| `manifest.json` | PWA install manifest |
| `sw.js` | Service worker for offline support |
| `icon-192.png` | App icon (home screen) |
| `icon-512.png` | App icon (splash screen) |

> Do **not** upload: `scripts/`, `start_server.py`, `update_html.py`, `setup_github_pages.sh`, or any `.xlsx` files.

## Edit menu content

Open **`menus.json`** in any editor. Each dish is `{ "id", "name", "nonveg", "tags" }`. Lists are grouped under `lists` (e.g. `bfSingle`, `luCurry`). Meal picker layout is under `adultMenu` and `babyMenu`.

To regenerate `menus.json` from an old inline HTML backup:

```bash
node scripts/build-menus-json.mjs
```

## Edit ingredients

Open **`ingredients.json`**. Map dish `id` → array of ingredient strings.

Users can also add ingredients per dish in the app (**Shopping → By meal → +** on a dish). Those are stored in the browser (`localStorage`).

## Local testing

```bash
python3 start_server.py
```

Open: http://localhost:8000/

## Host online (recommended)

### Netlify Drop

1. Go to https://app.netlify.com/drop  
2. Drag the folder (or zip with `index.html`, `menus.json`, `ingredients.json`)  
3. Sign up if you need to remove the default password on the drop URL  

### GitHub Pages

1. Create a public repo  
2. Upload `index.html`, `menus.json`, `ingredients.json` at the repo root  
3. Settings → Pages → deploy from `main` / root  

Your site URL: `https://YOUR_USERNAME.github.io/REPO_NAME/`

## Shopping views

- **By meal** — Monday → Breakfast/Lunch/… → dish → ingredients with **Buy** / **At home**; filters: All, To buy, At home  
- **Shop list** — aggregated list for the next shop trip  
- **My pantry** — what you already have at home  
