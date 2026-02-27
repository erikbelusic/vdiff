#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory where this script lives (follows symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")" && pwd)"

# --- Cleanup ---
SERVER_PID=""
TEMP_HTML=""
DIFF_FILE=""

cleanup() {
    [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null && wait "$SERVER_PID" 2>/dev/null
    [ -n "$TEMP_HTML" ] && rm -f "$TEMP_HTML"
    [ -n "$DIFF_FILE" ] && rm -f "$DIFF_FILE"
}
trap cleanup EXIT INT TERM HUP

# --- Validate environment ---
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a git repository." >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required but not found." >&2
    echo "" >&2
    echo "Install it via:" >&2
    echo "  macOS:   xcode-select --install  (or: brew install python3)" >&2
    echo "  Linux:   sudo apt install python3  (or your distro's package manager)" >&2
    echo "  Windows: https://www.python.org/downloads/" >&2
    exit 1
fi

# --- Parse arguments ---
DIFF_CMD="git diff"
DIFF_LABEL="unstaged changes"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --staged)
            DIFF_CMD="git diff --staged"
            DIFF_LABEL="staged changes"
            shift
            ;;
        --last)
            DIFF_CMD="git diff HEAD~1 HEAD"
            DIFF_LABEL="last commit"
            shift
            ;;
        --branch)
            BASE="${2:-}"
            if [ -z "$BASE" ]; then
                # Auto-detect default branch
                if git rev-parse --verify main &>/dev/null; then
                    BASE="main"
                elif git rev-parse --verify master &>/dev/null; then
                    BASE="master"
                else
                    echo "Error: No base branch specified and neither 'main' nor 'master' exists." >&2
                    exit 1
                fi
            else
                shift
            fi
            DIFF_CMD="git diff ${BASE}...HEAD"
            DIFF_LABEL="branch changes vs ${BASE}"
            shift
            ;;
        -h|--help)
            echo "Usage: vdiff [OPTIONS]"
            echo ""
            echo "Opens a git diff in the browser with an interactive viewer."
            echo ""
            echo "Options:"
            echo "  (none)          Show unstaged changes"
            echo "  --staged        Show staged changes"
            echo "  --last          Show last commit diff"
            echo "  --branch [base] Show all changes on current branch (default base: main)"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run 'vdiff --help' for usage." >&2
            exit 1
            ;;
    esac
done

# --- Capture diff ---
DIFF_FILE="/tmp/vdiff_${RANDOM}_$$.diff"
eval "$DIFF_CMD" > "$DIFF_FILE"

if [ ! -s "$DIFF_FILE" ]; then
    echo "No diff output (no ${DIFF_LABEL})."
    rm -f "$DIFF_FILE"
    DIFF_FILE=""
    exit 0
fi

# --- Build temp HTML with inlined diff ---
TEMP_HTML="/tmp/vdiff_${RANDOM}_$$.html"

python3 -c "
import json, sys

with open(sys.argv[1]) as f:
    viewer = f.read()

with open(sys.argv[2]) as f:
    diff = f.read()

# Inject diff as a JSON-encoded string in a script tag before </head>
# Escape </ to prevent browser from interpreting </script> inside the string
safe_diff = json.dumps(diff).replace('</', '<' + r'\/')
inject = '<script>var INLINE_DIFF = ' + safe_diff + ';</script>'
result = viewer.replace('</head>', inject + '</head>')

with open(sys.argv[3], 'w') as f:
    f.write(result)
" "$SCRIPT_DIR/viewer.html" "$DIFF_FILE" "$TEMP_HTML"

# --- Find an open port starting at 8000 ---
find_open_port() {
    local port=8000
    while [ "$port" -lt 9000 ]; do
        if ! lsof -iTCP:"$port" -sTCP:LISTEN &>/dev/null 2>&1; then
            echo "$port"
            return
        fi
        port=$((port + 1))
    done
    echo "Error: Could not find an open port between 8000-8999." >&2
    exit 1
}

PORT="$(find_open_port)"
TEMP_DIR="$(dirname "$TEMP_HTML")"
TEMP_NAME="$(basename "$TEMP_HTML")"

# --- Start a self-stopping server ---
# The server shuts itself down after serving the HTML file
python3 -c "
import http.server, socketserver, threading, sys, os

port = int(sys.argv[1])
directory = sys.argv[2]
target_file = sys.argv[3]

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def log_message(self, format, *args):
        pass  # suppress logging

    def do_GET(self):
        super().do_GET()
        # After serving the HTML file, schedule shutdown
        if self.path == '/' + target_file:
            threading.Timer(1.0, lambda: os._exit(0)).start()

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('127.0.0.1', port), Handler) as httpd:
    httpd.serve_forever()
" "$PORT" "$TEMP_DIR" "$TEMP_NAME" &
SERVER_PID=$!

# Give the server a moment to start
sleep 0.3

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Error: Failed to start HTTP server." >&2
    exit 1
fi

# --- Open browser ---
URL="http://localhost:${PORT}/${TEMP_NAME}"

if command -v open &>/dev/null; then
    open "$URL"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$URL"
elif command -v start &>/dev/null; then
    start "$URL"
else
    echo "Could not detect a way to open your browser. Please visit:" >&2
    echo "  $URL" >&2
fi

echo "Opened diff (${DIFF_LABEL}) in browser. Press Ctrl+C if it doesn't close automatically."

# Wait for the server to stop itself, with a 10s fallback timeout
WAIT_COUNT=0
while kill -0 "$SERVER_PID" 2>/dev/null && [ "$WAIT_COUNT" -lt 10 ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done
# Cleanup happens via trap on EXIT
