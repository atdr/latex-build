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

The first run generates `texlive-packages.txt` and commits it. Each build on the default branch is published as a release tagged `build-<short SHA>` with the PDF attached.

Set `lint: true` and `annotate_warnings: true` to have chktex findings and LaTeX log warnings (undefined references, overfull boxes and the like) reported as annotations and in the job summary.

See [AGENTS.md](AGENTS.md) for the inputs, the build flow and how the package list is generated.
