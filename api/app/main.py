from fastapi import FastAPI


def create_app() -> FastAPI:
    app = FastAPI(title="TodoArt API")

    @app.get("/")
    def read_root() -> dict[str, str]:
        return {
            "message": "TodoArt API is running",
            "status": "ok",
        }

    @app.get("/health")
    def healthcheck() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
