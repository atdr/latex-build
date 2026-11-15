<!-- Write plainly: short sentences, concrete detail, no filler. A reviewer
should be able to tell what changed and why in under a minute. -->

## What changed

<!-- One or two sentences. The PR title becomes the commit on main (squash
merge), so keep it conventional: type(scope): summary -->

## Why

<!-- The problem this solves. Link the issue: Fixes #123 -->

## Checks

- [ ] `ci gate` passes: every test document builds on TeX Live 2016 and latest
- [ ] README.md and AGENTS.md updated, if this changes an input or what callers see
- [ ] A test document added under `tests/`, if this handles a new failure mode
- [ ] Titled `fix:` or `feat:` only if callers see the change (see AGENTS.md)

## Test plan

<!-- On a draft: what you intend to test, so it can be argued with before you
spend the time. On a PR ready for review: what you tested and what you saw. -->

<!-- This file opens with a comment, not a heading, by design. -->

<!-- markdownlint-configure-file {
  "MD041": false
} -->
