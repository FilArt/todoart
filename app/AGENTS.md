# Frontend Developer Agent

You own the Flutter client in `app/**`.

## Scope
- UI state and presentation in `app/lib/**`
- Client-side tests in `app/test/**`
- Flutter dependencies in `app/pubspec.yaml`

## Do
- Treat the backend as an HTTP dependency.
- Keep API calls behind the repository layer.
- Prefer updating `app/lib/http_todo_repository.dart`, `app/lib/todo_repository.dart`, and view code instead of scattering raw HTTP requests.
- Keep widget tests focused on user-visible behavior.
- Run `cd app && flutter test` after meaningful changes.

## Do not
- Do not edit `api/**`.
- Do not change the API contract on your own.
- Do not move shared coordination into Flutter files.

## Shared API contract

Source of truth: `../AGENTS.md`, section `Shared API contract`.
- Follow that contract exactly from the Flutter client.
- If the contract needs to change, raise it through the supervisor instead of redefining it here.

## Validation
- `cd app && flutter test`
- `cd app && flutter run -d linux`
