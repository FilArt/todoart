from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def read_root() -> dict[str, str]:
    return {
        "message": "TodoArt API is running",
        "status": "ok",
    }


@router.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}
