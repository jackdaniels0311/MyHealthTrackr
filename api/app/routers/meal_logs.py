from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..auth import get_current_user
from ..db import get_db
from ..deps import (
    apply_updates,
    enforce_user_scope,
    require_food_log,
    require_meal_log,
)
from ..models import FoodLog, MealLog, User
from ..schemas import MealLogCreate, MealLogOut, MealLogUpdate
from ..services.user_food_history import UserFoodHistoryService

router = APIRouter(tags=["Meal Logs"])
_food_history_service = UserFoodHistoryService()


@router.get("/users/{user_id}/meal-logs", response_model=list[MealLogOut])
def list_meal_logs(
    user_id: int,
    food_log_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    query = (
        select(MealLog)
        .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
        .where(FoodLog.user_id == user_id)
        .order_by(MealLog.meal_log_id)
    )

    if food_log_id is not None:
        query = query.where(MealLog.food_log_id == food_log_id)

    return db.execute(query).scalars().all()


@router.post(
    "/users/{user_id}/meal-logs",
    response_model=MealLogOut,
    status_code=status.HTTP_201_CREATED,
)
def create_meal_log(
    user_id: int,
    payload: MealLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    require_food_log(db, user_id, payload.food_log_id)

    meal_log = MealLog(**payload.model_dump())
    db.add(meal_log)
    db.commit()
    db.refresh(meal_log)
    return meal_log


@router.get("/users/{user_id}/meal-logs/{meal_log_id}", response_model=MealLogOut)
def get_meal_log(
    user_id: int,
    meal_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_meal_log(db, user_id, meal_log_id)


@router.put("/users/{user_id}/meal-logs/{meal_log_id}", response_model=MealLogOut)
def update_meal_log(
    user_id: int,
    meal_log_id: int,
    payload: MealLogUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    meal_log = require_meal_log(db, user_id, meal_log_id)
    old_meal_type = meal_log.meal_type
    affected_names = {
        item.meal_name for item in meal_log.meal_items if item.meal_name.strip()
    }

    data = payload.model_dump(exclude_unset=True)
    new_food_log_id = data.get("food_log_id")
    if new_food_log_id is not None:
        require_food_log(db, user_id, new_food_log_id)

    apply_updates(meal_log, data)
    db.flush()
    if meal_log.meal_type != old_meal_type:
        _food_history_service.sync_history_entries(
            db,
            user_id=user_id,
            names=affected_names,
            meal_type=old_meal_type,
        )
        _food_history_service.sync_history_entries(
            db,
            user_id=user_id,
            names=affected_names,
            meal_type=meal_log.meal_type,
        )
    db.commit()
    db.refresh(meal_log)
    return meal_log


@router.delete(
    "/users/{user_id}/meal-logs/{meal_log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_meal_log(
    user_id: int,
    meal_log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    meal_log = require_meal_log(db, user_id, meal_log_id)
    old_meal_type = meal_log.meal_type
    affected_names = {
        item.meal_name for item in meal_log.meal_items if item.meal_name.strip()
    }
    db.delete(meal_log)
    db.flush()
    _food_history_service.sync_history_entries(
        db,
        user_id=user_id,
        names=affected_names,
        meal_type=old_meal_type,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
