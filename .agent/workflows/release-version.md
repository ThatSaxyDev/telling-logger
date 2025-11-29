---
description: Release a New Version of telling_logger
---

# Release Version Workflow

This document outlines the step-by-step process for releasing a new version of the `telling_logger` package.

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR** (x.0.0): Breaking changes
- **MINOR** (1.x.0): New features, backward compatible
- **PATCH** (1.1.x): Bug fixes, backward compatible

## Pre-Release Checklist

- [ ] All intended changes are committed
- [ ] Tests pass locally
- [ ] Code is on the appropriate branch (`main` or feature branch)
- [ ] Changes are documented/tested

## Release Steps

### 1. Update Version Files

Update the version in three files:

**pubspec.yaml:**
```yaml
version: 1.x.x  # Update this line
```

**README.md:**
```yaml
dependencies:
  telling_logger: ^1.x.x  # Update this line
```

**CHANGELOG.md:**
Add a new entry at the top:
```markdown
## 1.x.x - YYYY-MM-DD

### Added
- New features

### Changed
- Modifications

### Fixed
- Bug fixes
```

### 2. Commit and Tag

// turbo
```bash
git add .
git commit -m "Release v1.x.x: Brief description"
git tag v1.x.x
```

### 3. Push to GitHub

// turbo
```bash
git push origin [branch-name]
git push origin v1.x.x
```

### 4. Dry Run Publish

// turbo
```bash
dart pub publish --dry-run
```

Verify:
- Package has 0 warnings
- All expected files are included
- Package size is reasonable

### 5. Publish to pub.dev

```bash
dart pub publish
```

- Confirm with `y` when prompted
- Wait for "Successfully uploaded" confirmation

### 6. Verify Publication

- Check https://pub.dev/packages/telling_logger
- Verify new version appears (may take up to 10 minutes)
- Test installation in a sample project

## Quick Reference

**Patch Release (bug fix):**
```
1.1.0 → 1.1.1
```

**Minor Release (new feature):**
```
1.1.1 → 1.2.0
```

**Major Release (breaking change):**
```
1.2.0 → 2.0.0
```

## Troubleshooting

**Publish fails with "already exists":**
- Version numbers cannot be reused
- Increment to the next version

**Dry run shows warnings:**
- Address warnings before publishing
- Common: unused dependencies, missing documentation

**Git push rejected:**
- Ensure branch is up-to-date: `git pull origin [branch]`
- Resolve any conflicts

## Notes

- Releases are **permanent** and cannot be unpublished
- Always run dry-run before publishing
- Keep CHANGELOG.md updated with meaningful descriptions
- Tag format: `v1.x.x` (with 'v' prefix)
