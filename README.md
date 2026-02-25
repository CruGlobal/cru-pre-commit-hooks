# Cru `pre-commit` hooks
A collection of [pre-commit](https://pre-commit.com/) hooks used by Cru projects.

### Requirements
- Bash
- Terraform CLI
- [asdf](https://asdf-vm.com/) (for automatic terraform version installation)

### Installation
Create or update `.pre-commit-config.yaml`:
```yaml
- repo: git://github.com/CruGlobal/cru-pre-commit-hooks
  rev: v1.0.0
  hooks:
    - id: s3_backend_key
    - id: tf_provider_lock
    - id: tf_validate_config
```

## Hooks
- [`s3_backend_key`](#s3_backend_key) - Enforce the `key` property of `backend "s3"` to match folder paths for terraform files.
- [`tf_provider_lock`](#tf_provider_lock) - Add MacOS and Linux provider hashes to dependency lock file.
- [`tf_validate_config`](#tf_validate_config) - Enforce terraform version, backend lockfile, and required_version constraints.

## Details
#### s3_backend_key
This hook enforces that the `key` property of any `backend "s3"` matches the folder paths of the terraform file. This
catches accidental copy/paste errors or typos on the remote state key. Files are modified in place with the correct key
path. If `terraform init` had already been run with the incorrect path, it will need to be re-run to copy/move the
state to the correct key path.

#### tf_provider_lock
This hook ensures `.terraform.lock.hcl` files exist with provider hashes for both `darwin_arm64` (macOS) and
`linux_amd64` (CI/Atlantis). If a lock file is missing, it runs `terraform init` and `terraform providers lock` to
generate one.

#### tf_validate_config
This hook auto-corrects three terraform configuration issues:
- **Terraform version**: Enforces the installed version matches `.tool-versions`, installing the correct version via asdf if needed.
- **Backend lockfile**: Replaces `dynamodb_table = "terraform-state-lock"` with `use_lockfile = true` in S3 backend blocks.
- **required_version**: Updates the `required_version` constraint in the `terraform {}` block to `"~> <version>"` from `.tool-versions`.

Modified files are automatically formatted with `terraform fmt`.
