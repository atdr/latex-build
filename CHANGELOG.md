# Changelog

## [1.2.0](https://github.com/atdr/latex-build/compare/v1.1.3...v1.2.0) (2026-09-29)


### Features

* add an optional tex-fmt format check ([#15](https://github.com/atdr/latex-build/issues/15)) ([750fe4c](https://github.com/atdr/latex-build/commit/750fe4c9bcdcc1accd0ee48c85270aaca7639d63))
* annotate chktex findings and LaTeX log warnings ([#14](https://github.com/atdr/latex-build/issues/14)) ([bfa2977](https://github.com/atdr/latex-build/commit/bfa2977eb15ac315df1d51798123daa0a1c59906))


### Bug Fixes

* regenerate the package list when overriding the TeX Live version ([#18](https://github.com/atdr/latex-build/issues/18)) ([666f1b9](https://github.com/atdr/latex-build/commit/666f1b9616e97e5ed7263b4be63492e27f0971b2))

## [1.1.3](https://github.com/atdr/latex-build/compare/v1.1.2...v1.1.3) (2026-09-29)


### Bug Fixes

* install Ghostscript on the runner for EPS figures ([#12](https://github.com/atdr/latex-build/issues/12)) ([78c7c6d](https://github.com/atdr/latex-build/commit/78c7c6de977160cc6f017c3a337ba31c2df2c500))

## [1.1.2](https://github.com/atdr/latex-build/compare/v1.1.1...v1.1.2) (2026-09-29)


### Bug Fixes

* stop registering TeX Live's Type 1 fonts with fontconfig ([#10](https://github.com/atdr/latex-build/issues/10)) ([ae2a4be](https://github.com/atdr/latex-build/commit/ae2a4be3c2b4daa50d33a3d9162196e587395c0d))

## [1.1.1](https://github.com/atdr/latex-build/compare/v1.1.0...v1.1.1) (2026-09-29)


### Bug Fixes

* provide Ubuntu's Inconsolata, as Overleaf does ([#8](https://github.com/atdr/latex-build/issues/8)) ([fc692bd](https://github.com/atdr/latex-build/commit/fc692bd36b816187663594f86fe4fe590012d23f))

## [1.1.0](https://github.com/atdr/latex-build/compare/v1.0.0...v1.1.0) (2026-09-29)


### Features

* publish a moving major version tag for callers ([#5](https://github.com/atdr/latex-build/issues/5)) ([30348ee](https://github.com/atdr/latex-build/commit/30348eef7052e4b67d220729ef0a6c56f847c1b5))


### Bug Fixes

* fetch scripts at the workflow's own commit ([#6](https://github.com/atdr/latex-build/issues/6)) ([8dc1680](https://github.com/atdr/latex-build/commit/8dc16801c1fa894863cb4da90b2b4648ad6e2297))

## 1.0.0 (2026-09-29)


### Features

* reusable workflow to build LaTeX documents ([a9ab33f](https://github.com/atdr/latex-build/commit/a9ab33fb57bf477219cf35804645c47bb585b04d))


### Bug Fixes

* install Microsoft's core fonts on the runner, not in the container ([#3](https://github.com/atdr/latex-build/issues/3)) ([1bf0021](https://github.com/atdr/latex-build/commit/1bf00216afbff4cecf26a70e2d53e6d7a937ce42))
