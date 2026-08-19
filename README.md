# Sparsa's Blog

Personal website and blog built with [Jekyll](https://jekyllrb.com/) using the [Chirpy](https://chirpy.cotes.page/) theme, hosted on [GitHub Pages](https://pages.github.com/).

## Structure

```
.
├── _config.yml            # Site configuration (Chirpy options, defaults, plugins)
├── _data/                 # Contact, share, and localization data
├── _plugins/              # Custom Jekyll plugins (e.g. Lean syntax highlighting)
├── _tabs/                 # Top-level nav pages (about, cv, archives, categories, tags)
├── _posts/                # Blog posts (markdown)
├── _bibliography/         # BibTeX sources for jekyll-scholar
├── assets/img/favicons/   # Site favicons
├── images/                # Avatar and other images
├── index.html             # Home page (recent posts, paginated)
├── flake.nix              # Nix dev shell
└── .github/workflows/     # GitHub Actions build & deploy
```

## How to add a post

1. Create a file in `_posts/` named `YYYY-MM-DD-slug.md` (e.g. `2026-08-19-lean4-typeclassopedia.md`).
2. Add YAML front matter at the top:

   ```yaml
   ---
   title: "My Post Title"
   date: 2026-08-19
   description: "Short summary for SEO / feeds."
   categories: [example]
   tags: [tag1, tag2]
   ---
   ```

   `layout: post` and `toc: true` are applied automatically via `_config.yml` defaults — you only need them explicitly to override.

3. Write the body in Markdown below the front matter.

### Optional front matter

- `toc: false` — hide the table of contents for this post.
- `mermaid: true` — enable Mermaid diagram rendering.
- `categories` / `tags` — feed the Categories/Tags archive pages.
- `image` — featured image for the post card and SEO.
- `pin: true` — pin the post to the top of the home page.

## Features

- **Table of contents** — a sticky TOC column on the right of each post, with scroll-spy highlighting (built into Chirpy).
- **Mermaid diagrams** — enable with `mermaid: true` in the front matter, then wrap a diagram in a `mermaid` code block:

  ````markdown
  ```mermaid
  graph TD
    A --> B
  ```
  ````

- **Lean syntax highlighting** — a custom Rouge lexer (`_plugins/lean.rb`) handles Lean 4's Unicode vocabulary (`∀`, `∘`, Greek letters, subscripts) without rendering error tokens.
- **Figures** — `{% figure caption:"..." %}...{% endfigure %}` for captioned figures (via jekyll-figure).
- **Citations** — use `{% cite key %}` and `{% bibliography --cited %}` with entries in `_bibliography/references.bib` (via jekyll-scholar).
- **Dark mode**, PWA support, and SEO/sitemap/feed are built in.

## Avatar and favicon

- The sidebar avatar is `images/me.jpg` (set via `avatar:` in `_config.yml`).
- Favicons live in `assets/img/favicons/` and at the repo root (`favicon.ico`, `apple-touch-icon.png`). Regenerate them from the avatar with ImageMagick:

  ```bash
  convert images/me.jpg -resize 256x256 -background white -alpha remove -alpha off /tmp/me.png
  convert /tmp/me.png -define icon:auto-resize=16,32,48,64 favicon.ico
  convert /tmp/me.png -resize 180x180 apple-touch-icon.png
  ```

## Local development

### With Nix (recommended)

A [flake](flake.nix) provides a dev shell with Ruby, Bundler, and the native build tools:

```bash
nix develop
bundle exec jekyll serve
```

`nix develop` automatically installs the gems in `vendor/bundle`. Then open <http://127.0.0.1:4000>.

### Without Nix

```bash
bundle install
bundle exec jekyll serve
```

Then open <http://127.0.0.1:4000>.

## Deployment

The site builds and deploys via GitHub Actions (`.github/workflows/pages.yml`), using the Chirpy starter's approach:

- The `build` job runs `bundle exec jekyll build` with `JEKYLL_ENV=production`.
- The `deploy` job publishes the result with `actions/deploy-pages`.

Make sure the Pages source in Settings → Pages is set to **GitHub Actions**.