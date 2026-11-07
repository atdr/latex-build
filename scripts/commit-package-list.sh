#!/usr/bin/env bash
# Commits a changed package list and pushes it to the branch the run built.
#
# Saving the list must not stop the PDF publishing, so every way out is a
# warning, never a failure.
#
# A push can be refused for two reasons, handled differently:
#   - the branch moved during the build: a commit pushed meanwhile, or another
#     run's package list (a manual update_packages run and a push run can
#     overlap). The commit is replayed onto it, up to three times.
#   - a ruleset or branch protection forbids pushing to it directly (main in a
#     repo whose changes land through pull requests). The commit goes to a new
#     branch instead, with a link to open the pull request.
set -euo pipefail

git add "$PACKAGE_LIST"
git diff --cached --quiet && exit 0
bot='github-actions[bot]'
git config user.name "$bot"
git config user.email "41898282+$bot@users.noreply.github.com"
git commit --quiet -m "chore: update TeX Live package list"

remote="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
warn() { echo "::warning title=Package list not committed::$1"; }

err="$RUNNER_TEMP/package-list-push.err"
push() {
  git push "$remote" "$1" 2> "$err" && return 0
  cat "$err" >&2
  return 1
}

# GitHub names a rule refusal in the push's output: GH013 for a ruleset, GH006
# for classic branch protection. A branch that merely moved is a plain
# non-fast-forward, which neither code appears in.
refused_by_rule() {
  grep -E 'GH013|GH006' "$err" > /dev/null
}

# A new branch for each run attempt, so a rerun never collides with the last,
# and for each package list: a caller that builds several documents calls this
# workflow once per document, all within one run, and each list needs a branch
# of its own.
push_to_new_branch() {
  local list
  list=$(printf '%s' "$PACKAGE_LIST" | git hash-object --stdin | cut -c1-7)
  local branch="chore/update-texlive-packages-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}-$list"
  if ! push "HEAD:refs/heads/$branch"; then
    warn "${GITHUB_REF_NAME} does not accept direct pushes, and pushing the package list to a new branch, $branch, failed too."
    return
  fi
  local url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/compare/${GITHUB_REF_NAME}...${branch}?expand=1"
  echo "::warning title=Package list on a new branch::${GITHUB_REF_NAME} does not accept direct pushes, so the package list was pushed to $branch. Open a pull request to merge it: $url"
  {
    echo "### Package list"
    echo
    echo "\`${GITHUB_REF_NAME}\` does not accept direct pushes, so the new" \
      "\`${PACKAGE_LIST}\` was pushed to \`$branch\`." \
      "[Open a pull request]($url) to merge it."
  } >> "$GITHUB_STEP_SUMMARY"
}

for _ in 1 2 3; do
  push "HEAD:${GITHUB_REF_NAME}" && exit 0
  if refused_by_rule; then
    push_to_new_branch
    exit 0
  fi
  git fetch --quiet "$remote" "$GITHUB_REF_NAME" || {
    warn "Could not fetch ${GITHUB_REF_NAME} to replay the package list commit."
    exit 0
  }
  # Compared with the list this commit started from, not merged: two
  # different lists can merge cleanly into one neither run compiled with. A
  # list changed upstream is kept as it is.
  if ! git diff --quiet HEAD~1 FETCH_HEAD -- "$PACKAGE_LIST"; then
    warn "${GITHUB_REF_NAME} gained its own ${PACKAGE_LIST} change during this build, so that one is kept. Run with update_packages if it is missing a package."
    exit 0
  fi
  # Upstream left the list alone, so this replays cleanly. A rebase that
  # never started (a dirty tracked build output, say) has nothing to abort,
  # so the abort is best effort.
  git rebase --quiet FETCH_HEAD || {
    git rebase --abort 2> /dev/null || true
    warn "Could not replay the package list commit onto ${GITHUB_REF_NAME}."
    exit 0
  }
done
warn "${GITHUB_REF_NAME} kept moving; gave up pushing the package list after 3 tries."
