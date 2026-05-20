# Food Menu - Hosting Instructions

## Option 1: GitHub Pages (Free, Recommended)

1. Create a GitHub account at https://github.com
2. Create a new repository (make it public)
3. Upload these files to the repository:
   - `Food_Menu.html` (rename to `index.html`)
   - `menu_data.csv`
   - `update_html.py`
4. Go to repository Settings → Pages
5. Select source branch (usually `main` or `master`)
6. Your site will be available at: `https://yourusername.github.io/repository-name`

## Option 2: Netlify Drop (Easiest)

1. Go to https://app.netlify.com/drop
2. Drag and drop the `Food_Menu.html` file
3. Get instant URL - no account needed!

## Option 3: Local Server (For testing)

Run this command in the terminal:
```bash
python3 -m http.server 8000
```
Then open: http://localhost:8000/Food_Menu.html

## Option 4: Simple Python Server Script

Run `start_server.py` to start a local server.




