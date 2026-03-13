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
- `app-test`
- `api-test`
- `test-all`
