from fastapi import APIRouter, Response, status

from app import crud
from app.db import Db
from app.models import Todo, TodoCreate, TodoUpdate

router = APIRouter()


@router.get("/todos", response_model=list[Todo])
def list_todo_items(db: Db) -> list[Todo]:
    return crud.list_todos(db)


@router.post("/todos", response_model=Todo, status_code=status.HTTP_201_CREATED)
def create_todo_item(db: Db, payload: TodoCreate) -> Todo:
    return crud.create_todo(db, payload)


@router.get("/todos/{todo_id}", response_model=Todo)
def get_todo_item(db: Db, todo_id: int) -> Todo:
    return crud.get_todo(db, todo_id)


@router.patch("/todos/{todo_id}", response_model=Todo)
def update_todo_item(db: Db, todo_id: int, payload: TodoUpdate) -> Todo:
    return crud.update_todo(db, todo_id, payload)


@router.delete("/todos/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_todo_item(db: Db, todo_id: int) -> Response:
    crud.delete_todo(db, todo_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
