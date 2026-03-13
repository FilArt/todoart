# Multi-Agent Workflow

This repo is configured for three agent roles:

- `supervisor`: coordinates work, owns repo-root files, defines task splits
- `frontend developer`: owns `app/**`
- `backend developer`: owns `api/**`

## Ownership map

- `AGENTS.md`: supervisor instructions
- `app/AGENTS.md`: frontend instructions
- `api/AGENTS.md`: backend instructions

## Recommended split

Use the frontend developer for:
- Flutter widgets
- local UI state
- API client integration
- widget tests

Use the backend developer for:
- FastAPI routes
- SQLite schema and CRUD
- Pydantic models
- API tests

Use the supervisor for:
- decomposing work
- keeping the HTTP contract stable
- resolving shared config changes
- final verification

## Commands

- `agent-supervisor-brief`
- `agent-frontend-brief`
- `agent-backend-brief`
- `agent-workflow`
- `cd app && flutter test`
- `cd api && uv sync && uv run pytest`
- `devenv test`
- `devenv up`

## Validation flow

- Use `cd app && flutter test` for frontend-only changes.
- Use `cd api && uv sync && uv run pytest` for backend-only changes.
- Use `devenv test` as the final combined verification after the affected direct suite checks pass.
