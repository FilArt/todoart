# TodoArt

TodoArt is a small full-stack todo app with a Flutter frontend and a FastAPI backend.

## Repo

- `app/` Flutter client for Linux and Android
- `api/` FastAPI API backed by SQLite
- `devenv.nix` local dev shell and test setup

## Run It

```bash
devenv shell
devenv up
cd app && flutter run -d linux
```

The API runs on `http://127.0.0.1:8000` locally. On the Android emulator, the app uses `http://10.0.2.2:8000` by default.

## Test It

```bash
cd app && flutter test
cd api && uv sync && uv run pytest
devenv test
```

If you need a custom API URL, pass `--dart-define=TODO_API_BASE_URL=http://host:8000` to `flutter run`.
