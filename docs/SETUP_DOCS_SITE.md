# Docs Site Setup (MkDocs + Material)

This repo now includes a simple docs website setup.

## Why this choice

- Fast to set up
- Markdown-native
- Great search/navigation with Material theme
- Easy local preview and static build

## 1) Install tools

```bash
python3 -m pip install --user mkdocs mkdocs-material pymdown-extensions
```

## 2) Serve docs locally

```bash
scripts/docs.sh serve
```

Open: `http://127.0.0.1:8000`

Access from another device on same network:

```bash
scripts/docs.sh serve-lan
```

Then open on phone/tablet/browser:
`http://<your-mac-local-ip>:8000`

## 3) Build static site

```bash
scripts/docs.sh build
```

Generated output: `site/`

## Quick Command Wrapper

Use:

```bash
scripts/docs.sh help
```

Supported:
- `scripts/docs.sh serve`
- `scripts/docs.sh serve-lan`
- `scripts/docs.sh build`
- `scripts/docs.sh clean`

## 4) Optional deploy targets

- GitHub Pages (recommended, automated via Actions in this repo)
- Netlify/Vercel (deploy `site/`)
- Your own domain (e.g., `docs.peciulevicius.com`)

## GitHub Pages (already wired)

Workflow file:

- `.github/workflows/docs-pages.yml`

To enable once in GitHub UI:

1. Open repo `Settings -> Pages`
2. Set `Build and deployment -> Source` to `GitHub Actions`
3. Push to `main` (or run workflow manually from Actions tab)
4. Docs will publish to your Pages URL

Typical URL pattern:

- `https://<username>.github.io/<repo>/`

Example for this repo:

- `https://peciulevicius.github.io/.dotfiles/`

## Important: Custom Domain Format

Do not put a full URL/path in the Custom domain field.

Wrong:
- `peciulevicius.github.io/.dotfiles`

Right:
- leave custom domain empty (for default GitHub Pages URL), or
- set an actual domain/subdomain you own, e.g. `docs.peciulevicius.com`

## Alternative: Deploy from Branch

Yes, you can use branch-based deployment if you prefer.

Options in `Settings -> Pages`:
- `Deploy from a branch`
- Branch: `main`
- Folder: `/docs` (only works if static site files are in `docs/`)

Important:
- Current setup uses MkDocs source files in `docs/` and builds output to `site/`.
- So branch mode `/docs` will not render styled MkDocs site unless you commit built HTML there.
- Recommended approach is current `GitHub Actions` workflow, which builds and deploys `site/` automatically.

## Key pages

- [Start Here](./START_HERE.md)
- [macOS Setup](./MAC_SETUP.md)
- [Mac mini Setup](./HOME_SERVER.md)
- [Claude Code Guide](./CLAUDE_CODE_GUIDE.md)
