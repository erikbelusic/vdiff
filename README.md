# vdiff

Review your Git diffs in the browser and leave comments for AI-assisted code review.

`vdiff` opens any Git diff in a GitHub-dark themed viewer where you can annotate lines with review comments, then export everything in a structured format ready to paste into Claude, ChatGPT, or any LLM. It's like having a personal code review UI that feeds directly into your AI workflow.

Inspired by the diff viewer in the [Claude Code playground](https://claude.ai), but without the downsides — the playground is slow to render large diffs and every interaction consumes tokens, eating into your Pro/Max daily quota or costing real dollars on API access. `vdiff` runs locally with zero token cost, works offline, supports any AI tool, and handles stacked branches via [aviator-cli](https://docs.aviator.co/aviator-cli).

## Requirements

- Git
- Python 3 (for the ephemeral HTTP server and diff injection)
- A web browser
- Internet connection (optional, for syntax highlighting via highlight.js)

## Installation

```bash
git clone git@github.com:erikbelusic/vdiff.git
cd vdiff
sudo ./install.sh
```

This creates a symlink in `/usr/local/bin` so you can run `vdiff` from any git repository. To uninstall:

```bash
sudo rm /usr/local/bin/vdiff
```

## Usage

```bash
vdiff              # Unstaged changes
vdiff --staged     # Staged changes
vdiff --last       # Last commit
vdiff --branch     # All changes on current branch vs main
vdiff --branch dev # All changes on current branch vs dev
vdiff --av         # All changes vs parent branch (aviator-cli)
```

The tool opens your browser with the diff viewer and automatically exits. The server shuts itself down after serving the page. Press `Ctrl+C` if it doesn't close automatically.

## Features

- GitHub-dark themed diff viewer with custom diff parser (zero dependencies)
- Syntax highlighting via highlight.js CDN (graceful degradation if offline)
- Collapsible file cards with clickable file summary
- Single and multiline commenting (click, drag, or shift+click to select lines)
- Export comments in a structured format for AI-assisted code review
- Auto-closing server — no manual cleanup needed
- Supports multiple concurrent instances (dynamic port allocation)

## Commenting

1. **Single line**: Click any diff line to add a comment
2. **Multiple lines**: Click and drag, or click a line then shift+click another to select a range
3. Type your comment and press `Cmd/Ctrl+Enter` or click Save
4. Click a comment to edit it, or `x` to delete
5. Commented lines are visually marked; hover a comment to highlight its lines
6. Click "Prompt Output" to view all comments, then "Copy to Clipboard" to export
