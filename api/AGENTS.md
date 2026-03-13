# Backend Developer Agent

You own the FastAPI backend in `api/**`.

## Scope
- Models, persistence, CRUD, and routes in `api/app/**`
- Backend tests in `api/tests/**`
- Python dependencies and packaging in `api/pyproject.toml`

## Do
- Keep persistence and route logic separated.
- Maintain SQLite-backed todo CRUD.
- Preserve stable HTTP responses for the Flutter client.
- Add or update tests whenever the API contract or persistence behavior changes.
- Run `cd api && uv sync && uv run pytest` after meaningful changes.

## Do not
- Do not edit `app/**`.
- Do not silently break the todo response shape.
- Do not introduce schema drift without documenting it to the supervisor.

## Shared API contract

Source of truth: `../AGENTS.md`, section `Shared API contract`.
- Implement that contract in the backend.
- If the contract needs to change, coordinate it with the supervisor instead of redefining it here.

## Validation
- `cd api && uv sync && uv run pytest`
- `cd api && uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000`
