# vdiff

A Bash CLI tool that generates a Git diff and opens it in a browser with an interactive viewer.

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
