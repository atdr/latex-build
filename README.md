# latex-build

A reusable GitHub Actions workflow that compiles a LaTeX document to PDF on every push and publishes it as a GitHub release, much as Overleaf would build it.

- Installs only the TeX Live packages the document uses, from any TeX Live release since 2016 or the latest one, and works out that list itself.
- Loads fonts by name through `fontspec`, both those TeX Live ships and Microsoft's core fonts such as Arial.
- Publishes a PDF even when the build reports errors, as Overleaf does, with a warning on the release.

## Usage

Add `.github/workflows/compile.yml` to the document's repository:

```yaml
name: Build LaTeX document

on:
  push:
  workflow_dispatch:
    inputs:
      texlive_version:
        description: TeX Live version (e.g. 2017), for this run only
        required: false
      update_packages:
        description: Regenerate texlive-packages.txt
        type: boolean
        default: false

jobs:
  build:
    uses: atdr/latex-build/.github/workflows/build.yml@v1
    permissions:
      contents: write
    with:
      root_file: main.tex
      engine: -xelatex
      texlive_version: latest
      texlive_version_override: ${{ inputs.texlive_version }}
      update_packages: ${{ inputs.update_packages || false }}
```

`@v1` follows every 1.x release, so fixes arrive without any change in the document's repository. Add `.github/dependabot.yml` too, so a new major version (with breaking changes) arrives as a PR:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    commit-message:
      prefix: ci
```

[`atdr/latex-boilerplate`](https://github.com/atdr/latex-boilerplate) is a template repository with both files in place.

Each build on the default branch is published as a release tagged `build-<short SHA>` with the PDF attached. On other branches the PDF is attached to the workflow run as the `pdf` artifact.

## The package list

The first run generates `texlive-packages.txt` and commits it. After that, the list is regenerated and committed automatically when the compile fails on a missing file that a TeX Live package provides, which covers new packages in the document and a new `root_file`.

Run the workflow manually (Actions tab → the workflow → Run workflow) with its `update_packages` input ticked after changing:

- `engine`: the new engine's program (e.g. `pdftex` for `-pdf`) is not in the list, and a missing program does not trigger regeneration.
- `texlive_version`: package names differ between releases, so installing the old list can fail before anything compiles.

A manual run also drops packages the document no longer uses; automatic regeneration only happens on a failure, so they otherwise stay listed.


Set `lint: true` and `annotate_warnings: true` to have chktex findings and LaTeX log warnings (undefined references, overfull boxes and the like) reported as annotations and in the job summary.

Set `format_check: true` to check, in a separate job, that the document is formatted with [tex-fmt](https://github.com/WGUNDERWOOD/tex-fmt); pair it with tex-fmt's pre-commit hook so files are formatted before they are pushed.

See [AGENTS.md](AGENTS.md) for the inputs, the build flow and how the package list is generated.
