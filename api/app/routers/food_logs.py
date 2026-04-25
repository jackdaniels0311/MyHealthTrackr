from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..auth import get_current_user
from ..db import get_db
from ..deps import apply_updates, enforce_user_scope, require_food_log
from ..models import FoodLog, User
from ..schemas import FoodLogCreate, FoodLogOut, FoodLogUpdate

router = APIRouter(tags=["Food Logs"])


@router.get("/users/{user_id}/food-logs", response_model=list[FoodLogOut])
def list_food_logs(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return db.execute(
        select(FoodLog)
        .where(FoodLog.user_id == user_id)
        .order_by(FoodLog.food_log_id)
    ).scalars().all()


@router.post(
    "/users/{user_id}/food-logs",
    response_model=FoodLogOut,
    status_code=status.HTTP_201_CREATED,
)
def create_food_log(
    user_id: int,
    payload: FoodLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    food_log = FoodLog(user_id=user_id, **payload.model_dump())
    db.add(food_log)
    db.commit()
    db.refresh(food_log)
    return food_log


@router.get("/users/{user_id}/food-logs/{food_log_id}", response_model=FoodLogOut)
def get_food_log(
    user_id: int,
    food_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_food_log(db, user_id, food_log_id)


@router.put("/users/{user_id}/food-logs/{food_log_id}", response_model=FoodLogOut)
def update_food_log(
    user_id: int,
    food_log_id: int,
    payload: FoodLogUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    food_log = require_food_log(db, user_id, food_log_id)
    apply_updates(food_log, payload.model_dump(exclude_unset=True))
    db.commit()
    db.refresh(food_log)
    return food_log


@router.delete(
    "/users/{user_id}/food-logs/{food_log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_food_log(
    user_id: int,
    food_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    food_log = require_food_log(db, user_id, food_log_id)
    db.delete(food_log)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
