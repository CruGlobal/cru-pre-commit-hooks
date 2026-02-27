# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

## [v1.4.1] - 2026-2-27
### Fixed
- `tf_validate_config` always runs (version check fires even when no `.tf` files changed)
- File checks now discover changed `.tf` files via `PRE_COMMIT_FROM_REF`/`PRE_COMMIT_TO_REF` (CI) or `git diff --cached` (local) instead of scanning the entire repo
- Hook also checks `terraform.tf` in directories with staged changes, even when `terraform.tf` itself wasn't staged

## [v1.4.0] - 2026-2-25
### Added
- New `tf_validate_config` hook: enforces terraform version matches `.tool-versions`, replaces `dynamodb_table` with `use_lockfile` in S3 backends, and updates `required_version` constraints

### Changed
- Rewrite `s3_backend_key` from Ruby to Bash (removes Ruby dependency)

### Fixed
- `tf_validate_config` now only checks files passed by pre-commit instead of the entire repo

## [v1.2.0] - 2022-1-24
- Add support for darwin_amd64

[unreleased]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.4.1...master
[v1.4.1]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.4.0...v1.4.1
[v1.4.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.2.0...v1.4.0
[v1.2.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.1.1...v1.2.0
[v1.1.1]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.0.0...v1.1.0

