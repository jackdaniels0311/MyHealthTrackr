from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..auth import get_current_user
from ..db import get_db
from ..deps import apply_updates, enforce_user_scope, require_food_log
from ..models import FoodLog, User
from ..schemas import FoodLogCreate, FoodLogOut, FoodLogUpdate
from ..services.food_logs import find_or_create_food_log_for_datetime, log_day_from_datetime

router = APIRouter(tags=["Food Logs"])


@router.get("/users/{user_id}/food-logs", response_model=list[FoodLogOut])
def list_food_logs(
    user_id: int,
    log_day: date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    query = (
        select(FoodLog)
        .where(FoodLog.user_id == user_id)
        .order_by(FoodLog.food_log_id)
    )
    if log_day is not None:
        query = query.where(FoodLog.log_day == log_day)
    return db.execute(query).scalars().all()


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
    food_log, created = find_or_create_food_log_for_datetime(
        db,
        user_id=user_id,
        log_date=payload.log_date,
    )
    if created or "goal_weight" in payload.model_fields_set:
        food_log.goal_weight = payload.goal_weight
    if created or "goal_date" in payload.model_fields_set:
        food_log.goal_date = payload.goal_date
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
    data = payload.model_dump(exclude_unset=True)
    if "log_date" in data and data["log_date"] is not None:
        food_log.log_day = log_day_from_datetime(data["log_date"])
    apply_updates(food_log, data)
    try:
        db.flush()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A food log already exists for that day.",
        ) from exc
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
