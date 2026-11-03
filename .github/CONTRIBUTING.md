# Contributing Guide

## Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

Every commit message must follow this format:


### Allowed Types

| Type | Use for |
|---|---|
| `feat` | New functionality |
| `fix` | Bug fix |
| `refactor` | Restructuring without behaviour change |
| `test` | Adding or modifying tests |
| `ci` | GitHub Actions and build automation |
| `docs` | Documentation changes |
| `chore` | Dependency updates, config, tooling |
| `security` | Security hardening |
| `build` | Docker, packaging, image changes |

### Rules

- Description must be **imperative mood**: write "add retry logic" not "added retry logic"
- Description must be **under 72 characters**
- Description must **not end with a full stop**
- Scope is optional but encouraged, e.g. `fix(consumer): handle missing field`



## Branch Strategy

- `main` — stable, deployable code. Protected; requires passing CI.
- Feature branches — `feat/<short-name>` or `fix/<short-name>`

## Pull Requests

- Keep PRs focused on one logical change.
- Include a description of what changed and why.
- CI must pass before merge.

## Environment Setup

```bash
# Copy environment template
cp .env.example .env
# Edit .env with your local values — never commit .env

# Install dependencies
pip install -r requirements.txt

# Run linting
ruff check .

# Run tests
pytest


---

### 5. Code Explanation

A few important decisions in this document:

- **Imperative mood** — Git itself uses imperative mood in its auto-generated messages (`Merge branch`, `Revert "..."`) so this is stylistically consistent.
- **The environment setup section** references `ruff`, `pytest`, and `.env.example` — none of which exist yet. That is fine. A CONTRIBUTING guide describes the *intended* workflow, and you'll implement those tools in Phases 1 and 7. This is one case where being slightly aspirational is correct.
- **"What Never Goes in a Commit"** — explicitly naming the sensitive files reinforces the security habit and serves as a checklist before every commit.

---

### 6. Verification

```bash
# Confirm file is in the right place
ls .github/CONTRIBUTING.md

# Confirm it renders correctly — check on GitHub after pushing
# GitHub automatically links CONTRIBUTING.md in the "New Issue" and
# "New Pull Request" sidebars, so it gets visibility.
