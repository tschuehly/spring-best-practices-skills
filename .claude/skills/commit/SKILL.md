# Commit Skill

Group uncommitted changes into logical feature commits.

## Steps

1. Run `git status` and `git diff` (staged + unstaged) to understand all changes
2. Analyze all changed files and group them by logical feature/intent (e.g. "DB migration", "auth refactor", "UI fixes")
3. For each logical group, stage only the files belonging to that group and commit with a concise, action-oriented message (e.g. "Add X", "Fix Y", "Refactor Z"). No conventional commit prefixes. Use a HEREDOC to pass the message:
   ```bash
   git commit -m "$(cat <<'EOF'
   Add user authentication

   Login endpoint, JWT handling, middleware

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```
4. Repeat step 3 until all changes are committed
5. Run `git log --oneline -n <number-of-new-commits>` to show the resulting commits
6. Report the resulting commits
