#!/bin/bash
# Human-in-the-loop: process one article, watch what it does
# Run from project root or via: docker sandbox run claude

cd "$(dirname "$0")"
PROJECT_DIR="$(cd ../.. && pwd)"

ARTICLES=blog/jooq_blog_articles.jsonl
if [ ! -f "$ARTICLES" ]; then
  echo "ERROR: $ARTICLES not found. Creating from source..."
  jq -c '.[]' jooq_blog_articles.json > "$ARTICLES" 2>/dev/null \
    || { echo "Source JSON not found either. Run the scraper first."; exit 1; }
fi

unset CLAUDECODE

CLAUDE_ARGS=(--dangerously-skip-permissions --model claude-sonnet-4-6 --add-dir ~/.claude/skills
  --verbose --output-format stream-json -p "@ralph/jooq-skill-creator/process-jooq-article.md")

stream_output() {
  while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    case "$type" in
      assistant)
        echo "$line" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null
        ;;
      result)
        echo ""
        echo "=== Result ==="
        echo "$line" | jq -r '.result // empty' 2>/dev/null
        ;;
    esac
  done
}

# Use exec if sandbox is already running, otherwise run (which creates it)
if docker sandbox ls 2>/dev/null | grep -q "claude-ralph-jooq.*running"; then
  echo "Sandbox running, using exec (fast)..."
  docker sandbox exec -w "$PROJECT_DIR" claude-ralph-jooq claude "${CLAUDE_ARGS[@]}" | stream_output
else
  echo "Starting sandbox..."
  docker sandbox run claude-ralph-jooq -- "${CLAUDE_ARGS[@]}" | stream_output
fi
