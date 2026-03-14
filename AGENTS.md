# Supervisor Agent

You are the coordinating agent for this repository.

## Team shape
- `frontend developer`: owns `app/**`
- `backend developer`: owns `api/**`
- `supervisor`: owns root-level coordination, shared contracts, and cross-cutting files such as `devenv.nix`, `.gitignore`, docs, and handoff notes

## Primary job
- Break work into frontend-only, backend-only, and shared tasks.
- Assign `app/**` work to the frontend developer and `api/**` work to the backend developer.
- Keep the API contract stable and explicit before parallel work starts.
- Run the final verification step after the specialists finish.

## Ownership rules
- Do not let the frontend developer edit `api/**` unless you explicitly reassign that work.
- Do not let the backend developer edit `app/**` unless you explicitly reassign that work.
- Keep shared files at the repo root under supervisor ownership unless a task clearly belongs elsewhere.

## Coordination workflow
1. Write down the task split in terms of file ownership.
2. State the HTTP contract before parallelizing app/backend work.
3. Let the backend land schema and routes first when the contract changes.
4. Let the frontend adapt to the contract without changing backend files.
5. Re-run affected suites directly with `cd app && flutter test` or `cd api && uv sync && uv run pytest`, then run `devenv test` before closing the task.

## Project commands
- `cd app && flutter test`
- `cd api && uv sync && uv run pytest`
- `devenv test`
- `cd app && flutter run -d linux`
- `cd api && uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000`
- `devenv up`

## Shared API contract

This section is the source of truth for the todo API contract. Role-specific `AGENTS.md` files should reference this section instead of copying it.

- `GET /todos`
- `POST /todos` with `{ "title": string, "description"?: string }`
- `GET /todos/{id}`
- `PATCH /todos/{id}` with `{ "title"?: string, "description"?: string, "done"?: bool }`
- `DELETE /todos/{id}`
- `POST /releases/android` as `multipart/form-data` with fields `version` (string), `build_number` (int), optional `notes` (string), and `apk` (file)
- `GET /releases/android/latest`
- `GET /releases/android/download/{filename}`

Responses use the todo shape:

```json
{ "id": 1, "title": "Buy oat milk", "description": "Barista blend only", "done": false }
```

Android release upload auth uses header `X-Release-Token` and the server env var `TODOART_RELEASE_UPLOAD_TOKEN`.

`GET /releases/android/latest` returns:

```json
{
  "version": "1.0.1",
  "build_number": 2,
  "notes": "Fixes sync issues",
  "download_url": "https://example.com/releases/android/download/todoart-1.0.1+2.apk",
  "published_at": "2026-03-14T12:00:00Z"
}
```
