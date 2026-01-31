# WokeLang.org Website

Official website for WokeLang programming language.

## Structure

```
site/
├── config.yaml         # Site configuration
├── content/            # Markdown content
│   ├── index.md       # Homepage
│   └── docs/          # Documentation
├── templates/          # HTML templates
│   ├── base.html
│   ├── page.html
│   └── index.html
├── static/             # Static assets
│   └── css/
└── public/             # Generated output (not in git)
```

## Building

Uses the general-purpose [wokelang-ssg](https://github.com/hyperpolymath/wokelang-ssg) tool:

```bash
# From wokelang/site/ directory
wokelang-ssg build

# Or using the SSG from parent repo
cd ..
wokelang-ssg/ssg/main.woke
```

## Deployment

- **Production**: wokelang.org (Cloudflare Pages)
- **Playground**: playground.wokelang.org (Cloudflare Pages subdomain)

## Content

- Homepage: Features, quick start
- Docs: Language guide, API reference
- Examples: Sample programs
- Playground: Interactive REPL (future)
