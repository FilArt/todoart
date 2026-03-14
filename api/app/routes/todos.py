from fastapi import APIRouter, Response, status

from app.db import Db
from app.models import Todo, TodoCreate, TodoUpdate
from app.crud import todos as crud

router = APIRouter()


@router.get("/todos", response_model=list[Todo])
def lst(db: Db) -> list[Todo]:
    return crud.list_todos(db)


@router.post("/todos", response_model=Todo, status_code=status.HTTP_201_CREATED)
def create(db: Db, payload: TodoCreate) -> Todo:
    return crud.create_todo(db, payload)


@router.get("/todos/{todo_id}", response_model=Todo)
def get(db: Db, todo_id: int) -> Todo:
    return crud.get_todo(db, todo_id)


@router.patch("/todos/{todo_id}", response_model=Todo)
def patch(db: Db, todo_id: int, payload: TodoUpdate) -> Todo:
    return crud.update_todo(db, todo_id, payload)


@router.delete("/todos/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(db: Db, todo_id: int) -> Response:
    crud.delete_todo(db, todo_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
