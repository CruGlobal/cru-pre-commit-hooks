# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

## [v1.3.0] - 2026-2-25
### Added
- New `tf_validate_config` hook: enforces terraform version matches `.tool-versions`, replaces `dynamodb_table` with `use_lockfile` in S3 backends, and updates `required_version` constraints

### Changed
- Rewrite `s3_backend_key` from Ruby to Bash (removes Ruby dependency)

## [v1.2.0] - 2022-1-24
- Add support for darwin_amd64

[unreleased]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.3.0...master
[v1.3.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.1.1...v1.2.0
[v1.1.1]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/CruGlobal/cru-pre-commit-hooks/compare/v1.0.0...v1.1.0

