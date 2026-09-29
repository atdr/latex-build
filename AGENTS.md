# AGENTS.md

A reusable GitHub Actions workflow that compiles a repository's LaTeX document to PDF and publishes it as a release. It installs only the TeX Live packages the document needs, and works out that list itself when needed. Documents call it from a short workflow of their own; `atdr/latex-boilerplate` has the example.

## Layout

| Path | Purpose |
|---|---|
| `.github/workflows/build.yml` | The reusable workflow (`on: workflow_call`) |
| `scripts/select-texlive.sh` | Picks the TeX Live repository for a release year (the frozen historic archive for past years) |
| `scripts/install-ms-fonts.sh` | Installs Microsoft's core fonts (Arial etc.) on the runner, for `fontspec` names TeX Live does not ship |
| `scripts/setup-fonts.sh` | Registers TeX Live's own fonts with fontconfig, so `fontspec` can load them by name |
| `scripts/compile.sh` | Compiles; names the TeX Live package providing each missing file, or publishes anyway if a PDF still came out |
| `scripts/list-packages.sh` | Runs in a full TeX Live image; rewrites the package list from what the build used |
| `scripts/publish-release.sh` | Attaches the PDF to a `build-<short SHA>` release |
| `tests/` | Test documents, one per failure mode seen in real projects |
| `.github/workflows/test.yml` | Builds every test document on TeX Live 2016 and latest |
| `.github/workflows/release-please.yml` | Release PRs, tags and the changelog |

## How callers use it

```yaml
jobs:
  build:
    uses: atdr/latex-build/.github/workflows/build.yml@v1.0.0 # x-release-please-version
    permissions:
      contents: write
    with:
      root_file: main.tex
      engine: -xelatex
      texlive_version: "2019"
```

Inputs (see `build.yml` for all of them):

- `root_file`: root `.tex` file. It may be in a subdirectory; latexmk still runs from the repository root, as Overleaf does, and writes its outputs (log, PDF) there.
- `engine`: latexmk engine flag: `-pdf` (pdfLaTeX, Overleaf's default), `-xelatex` or `-lualatex`. It overrides any `.latexmkrc`.
- `texlive_version`: TeX Live release year as a string (e.g. `"2017"`), or `latest`. A past year installs from its frozen `tlnet-final` archive on the Utah historic mirror (and the full-install job uses its `TL<year>-historic` image); the current year has neither yet, so it installs from the mirrors like `latest`.
- `texlive_version_override` and `update_packages`: pass through the caller's manual-run inputs. A run with another TeX Live version never commits the package list.

Callers pin an exact version (`@v1.0.0`), and Dependabot (`package-ecosystem: github-actions`) opens a PR in each caller for every new release.

### Where the scripts come from

A called workflow cannot use `./` paths into its own repository: those resolve in the caller's checkout. So each job fetches this repository at `build_ref` into `$RUNNER_TEMP/latex-build` (outside the workspace, where `git clean` and the build cannot touch it) and runs the scripts from there. `build_ref` defaults to the workflow's own release tag; release-please keeps that default in step with each release (the `x-release-please-version` comment). Only the tests override it, to run the commit under test.

## Build flow

Each run has two jobs in sequence:

1. **`build_latex`** (about 10 s once the install is cached)
   - If the package list is missing or `update_packages` is set, it skips compiling and flags `update_packages`.
   - Otherwise it installs the listed packages (`zauguin/install-texlive`, cached per list and release), sets up fonts and compiles:
     - success: publishes the PDF;
     - a missing file that a TeX Live package provides: flags `update_packages`;
     - any other failure with a PDF still produced (e.g. a BibTeX "no citations" error, an xdvipdfmx error, a LaTeX error that does not stop the PDF from being written): publishes the PDF anyway, as Overleaf would, with a warning on the release and the run;
     - a failure with no PDF: the job fails.
2. **`update_packages`** (only when flagged; about 2.5 min)
   - compiles in the full `texlive/texlive` image, where `list-packages.sh` rewrites the package list;
   - deletes that build's outputs, installs only the new list and compiles again, which verifies the list;
   - commits the list if it changed (not on runs with another TeX Live version, nor for a tag, nor when `commit_package_list` is false), then publishes the PDF.

- **Publishing:** on the default branch the PDF is attached to a release tagged `build-<short SHA>`, which does not expire. Rebuilding the same commit replaces the PDF and updates the notes. On other branches, or with `publish_release: false`, the PDF is uploaded as the `pdf` artifact of the run. When a build fails or compiles with errors, its `.log` files are uploaded as the `run-log` artifact.
- **Workflow commits:** the list commit is made with the caller's `GITHUB_TOKEN`, so it does not trigger another run. The run that made it has already built and published the PDF with that list.

## How the package list is generated

`list-packages.sh` compiles in the full TeX Live image for the selected year, then maps everything the build used to the TeX Live package that provides it, using the image's `tlpkg/texlive.tlpdb`:

- files TeX read (`INPUT` lines of latexmk's `.fls` record);
- files found through kpathsea (`KPATHSEA_DEBUG=32`), which covers fonts XeTeX and xdvipdfmx load (these are not in the `.fls`), format builds and `kpsewhich` lookups;
- formats loaded (`execute AddFormat name=…` in the tlpdb);
- programs latexmk ran (its `Run number N of rule '…'` messages) and latexmk itself.

The list is rewritten from scratch, so unused packages are dropped as well as missing ones added. It is tied to `texlive_version`: package names and dependencies differ between releases (e.g. TeX Live 2016 needs `lm` listed, while later releases also need `l3kernel`).

## Changing things

- **Test in Actions:** there is no local equivalent of the runner. Push a branch and open a PR; `test.yml` builds every test document on TeX Live 2016 and latest, since installers, latexmk and log formats differ between years. Add a test document for any new failure mode.
- **Releases:** merge to `main` with Conventional Commit messages; release-please opens a release PR, and merging it tags `vX.Y.Z` and updates `build_ref`'s default in the same commit. Do not hand-edit `CHANGELOG.md`, `version.txt` or the version on the `build_ref` line.
- **Breaking changes** (a renamed or removed input, a changed default): mark the commit `feat!:` or add `BREAKING CHANGE:` to its body, so callers get a major version.

## Conventions

- **Git workflow:** GitHub Flow. Branch off `main`, open a PR, merge once `Test` passes.
- **Line length:** code (YAML, shell) wraps at 80 columns. Markdown is not hard-wrapped: one line per paragraph or list item.
- **Commits and PR titles:** [Conventional Commits](https://www.conventionalcommits.org/). They are the changelog: `fix:` for a build behaviour fix, `feat:` for a new input or capability, `docs:`, `ci:` and `test:` for changes callers do not see. The workflow's own list commits in callers use `chore: update TeX Live package list`.

## Pitfalls

These already caused failures; keep them in mind when changing the scripts:

- **Historic installs over HTTPS:** older installers (e.g. 2016) cannot download over HTTPS, so historic repositories use `http://`. tlmgr still verifies the repository's signature (`(verified)` in the log).
- **Log parsing in `compile.sh`:** TeX wraps log lines at 79 characters; `compile.sh` sets `max_print_line` to stop this. With `-file-line-error`, errors start `./file.tex:N:` rather than `!`, and font errors lose the backslash before the font name, so patterns must accept both forms.
- **Errors that still produce a PDF:** Overleaf runs latexmk with `-f` and serves whatever PDF comes out. Both `compile.sh` and `list-packages.sh` pass `-f` too (without it a XeLaTeX build stops before xdvipdfmx and leaves only an `.xdv`), and both accept a non-zero exit when the PDF exists. latexmk still exits non-zero after `-f`, which is how `compiled_with_errors` is detected.
- **Hyphenation packages in the list:** the TeX Live 2016 image builds formats on first use, and that build reads every language's hyphenation patterns. `list-packages.sh` therefore compiles once untraced before recording.
- **Leftover files from the full build:** its outputs are owned by root, and latexmk could reuse its PDF, so `update_packages` changes their owner and runs `git clean` before verifying the new list.
- **Token exposure:** checkouts use `persist-credentials: false`, so the token is not on disk while TeX and the scripts run. Only the commit step (which pushes with `GH_TOKEN`) and the publish step receive it; keep new steps that way.
- **Failure handling in `build_latex`:** its compile step uses `continue-on-error` so that a missing package can hand over to `update_packages`. Only a failure that leaves no PDF and names no file a TeX Live package provides is re-raised, by the "Fail on other errors" step.
- **Missing programs:** a missing program (e.g. `biber`) is not a missing file, so it does not trigger regeneration; a manual run with `update_packages` does pick it up.
- **Fonts outside TeX Live:** `install-ms-fonts.sh` installs Microsoft's core fonts (`ttf-mscorefonts-installer`, EULA pre-accepted via `debconf-set-selections`) for `fontspec` names like Arial that TeX Live does not ship. They are not part of TeX Live, so `list-packages.sh` cannot list them; they are installed unconditionally instead. It runs on the Ubuntu runner only: the full TeX Live image's Debian has the package only in `contrib`, which is not enabled (and old historic images have no live apt repositories at all), so `update_packages` mounts the runner's `/usr/share/fonts/truetype/msttcorefonts` into the container read-only.
- **Fonts TeX Live does ship (Inconsolata, Fira Sans, EB Garamond, etc.):** they sit as files under the TeX Live tree, which fontconfig does not search until told to. `setup-fonts.sh` registers `texmf-dist/fonts/{opentype,truetype,type1}` with fontconfig, both on the runner and at the start of `list-packages.sh` in the full image. It writes only a fontconfig file, so it needs no package manager.
- **Executable bit:** the workflow runs each script directly, so every file in `scripts/` must be committed as `100755` (`git ls-files -s scripts`).
- **A hung compile:** the compile and package-listing steps have a `timeout-minutes` well above their normal duration, so a compile that hangs (rather than erroring) fails the job instead of running until the runner's own limit.
