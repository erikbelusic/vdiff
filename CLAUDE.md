# CLAUDE.md

## Project Overview

vdiff is a standalone Bash CLI tool that opens Git diffs in a browser with an interactive viewer.

## Architecture

- `vdiff.sh` — Single Bash script handling CLI args, diff capture, HTML generation, ephemeral server, and cleanup
- `viewer.html` — Self-contained HTML/CSS/JS diff viewer with custom diff parser, commenting, and export

## Key Decisions

- Python 3 is used for two things: injecting the diff into a temp HTML copy (via `json.dumps` for safe escaping), and running an ephemeral HTTP server. No pip dependencies.
- The diff is inlined into a temp copy of viewer.html as a JS variable (`INLINE_DIFF`), avoiding CORS issues and eliminating the need for symlinks.
- The server monitors its own requests and auto-shuts down ~1s after serving the page. A 10s fallback timeout ensures cleanup if the browser never loads.
- `</` sequences in the diff are escaped to `<\/` to prevent the browser from interpreting `</script>` inside the injected script tag.
- Ports are dynamically allocated starting at 8000 with `SO_REUSEADDR` to avoid port conflicts.
- Syntax highlighting uses highlight.js from CDN (github-dark theme). If offline, highlighting is skipped but everything else works.
- The custom diff parser and renderer replaced diff2html to eliminate the 1MB dependency and gain full visual control.
- Multiline comments use click+drag and shift+click selection, matching GitHub's UX.

## Development Notes

- All logic lives in `vdiff.sh` and `viewer.html` — no build step, no package manager, no vendored files.
- The viewer uses vanilla JS (no framework). Comments are stored in a JS array in memory (ephemeral per session).
- Export format uses concise `- file:line` style designed for pasting to an AI.
- The `splitHighlightedHtml` function handles splitting highlight.js output back into individual lines while preserving open span tags across line boundaries.
