# Cru `pre-commit` hooks
A collection of [pre-commit](https://pre-commit.com/) hooks used by Cru projects.

### Requirements
This project is written in ruby and requires ruby to be available in order to execute the hooks.

### Installation
Create or update `.pre-commit-config.yaml`:
```yaml
- repo: git://github.com/CruGlobal/cru-pre-commit-hooks
  rev: v1.0.0
  hooks:
    - id: s3_backend_key
```

## Hooks
- [`s3_backend_key`](#s3_backend_key) - Enforce the `key` property of `backend "s3"` to match folder paths for terraform files.

## Details
#### s3_backend_key
This hook enforces that the `key` property of any `backend "s3"` matches the folder paths of the terraform file. This
catches accidental copy/paste errors or typos on the remote state key. Files are modified in place with the correct key
path. If `terraform init` had already been run with the incorrect path, it will need to be re-run to copy/move the
state to the correct key path.
