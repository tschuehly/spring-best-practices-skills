#!/bin/bash
# AFK Ralph loop: process N jOOQ blog articles unattended
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

cd "$(dirname "$0")"
PROJECT_DIR="$(cd ../.. && pwd)"
unset CLAUDECODE

CLAUDE_ARGS=(--dangerously-skip-permissions --model claude-sonnet-4-6 --add-dir ~/.claude/skills \
  --verbose --output-format stream-json -p "@ralph/jooq-skill-creator/process-jooq-article.md")

START_TIME=$(date +%s)
ITERATIONS=0

stream_output() {
  local result_file="$1"
  while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    case "$type" in
      assistant)
        text=$(echo "$line" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
        [ -n "$text" ] && echo "$text"
        ;;
      result)
        result_text=$(echo "$line" | jq -r '.result // empty' 2>/dev/null)
        echo ""
        echo "=== Result ==="
        echo "$result_text"
        echo "$result_text" > "$result_file"
        ;;
    esac
  done
}

run_claude() {
  local result_file="$1"
  if docker sandbox ls 2>/dev/null | grep -q "claude-ralph-jooq.*running"; then
    docker sandbox exec -w "$PROJECT_DIR" claude-ralph-jooq claude "${CLAUDE_ARGS[@]}" | stream_output "$result_file"
  else
    echo "Starting sandbox..."
    docker sandbox run claude-ralph-jooq -- "${CLAUDE_ARGS[@]}" | stream_output "$result_file"
  fi
}

for ((i=1; i<=$1; i++)); do
  ((ITERATIONS++))
  echo "=== Iteration $i/$1 ==="

  RESULT_FILE=$(mktemp)
  run_claude "$RESULT_FILE"
  result=$(cat "$RESULT_FILE" 2>/dev/null)
  rm -f "$RESULT_FILE"

  # Extract article title + action from last table row (ignore summary lines)
  last_row=$(grep '^|' blog/processing-log.md | grep -v '^|[-#]' | tail -1)
  article_title=$(echo "$last_row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
  action=$(echo "$last_row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}' | sed 's/pped$/p/; s/ged$/ge/; s/ed$//')
  commit_msg="jooq-${action:-process}: ${article_title:-iteration $i}"

  # Commit skill changes after each iteration
  git add ../../.claude/skills/jooq-best-practices/ blog/
  if git commit -m "$commit_msg" --no-verify 2>/dev/null; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    # Append commit hash to last table row in processing log
    last_row_num=$(grep -n '^|' blog/processing-log.md | grep -v '^[0-9]*:|[-#]' | tail -1 | cut -d: -f1)
    if [ -n "$last_row_num" ]; then
      sed -i '' "${last_row_num} s/|[[:space:]]*$/| ${COMMIT_HASH} |/" blog/processing-log.md
    fi
    # Stage updated log with hash
    git add blog/processing-log.md
    git commit --amend --no-edit --no-verify 2>/dev/null
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "All articles processed after $ITERATIONS iterations."
    break
  fi

  echo "---"
done

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))

# Capture summary stats for blog post
ARTICLES_FILE=blog/jooq_blog_articles.jsonl
PROCESSED=$(grep -c '"processed":true' "$ARTICLES_FILE" || echo 0)
REMAINING=$(grep -c '"processed":false' "$ARTICLES_FILE" || echo 0)
TOPIC_FILES=$(ls ../../.claude/skills/jooq-best-practices/knowledge/*.md 2>/dev/null | wc -l | tr -d ' ')
UNCERTAINTIES=$(sed -n '/^```/,/^```/!p' ../../.claude/skills/jooq-best-practices/UNCERTAINTIES.md 2>/dev/null | grep -c "^## " || echo 0)

cat >> blog/processing-log.md << EOF

---
**Run summary** ($(date '+%Y-%m-%d %H:%M')):
- Iterations this run: $ITERATIONS
- Duration: ${MINUTES}m ${ELAPSED}s total
- Articles processed so far: $PROCESSED / $(( PROCESSED + REMAINING ))
- Topic files: $TOPIC_FILES
- Open uncertainties: $UNCERTAINTIES
EOF

echo ""
echo "=== Summary ==="
echo "Iterations: $ITERATIONS | Duration: ${MINUTES}m | Processed: $PROCESSED | Remaining: $REMAINING | Topics: $TOPIC_FILES | Uncertainties: $UNCERTAINTIES"
