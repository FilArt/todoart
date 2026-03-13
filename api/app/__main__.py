from collections.abc import Sequence
import argparse
import os

import uvicorn


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="todoart-api",
        description="Run the TodoArt FastAPI backend with uvicorn.",
    )
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument(
        "--db-path",
        default=None,
        help="Override TODOART_DB_PATH for the process.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.db_path is not None:
        os.environ["TODOART_DB_PATH"] = args.db_path

    uvicorn.run(
        "app.main:app",
        host=args.host,
        port=args.port,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
