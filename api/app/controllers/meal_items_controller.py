from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.api_docs import AUTHENTICATED_RESPONSES
from ..core.auth import get_current_user
from ..database.session import get_db
from ..dependencies import (
    apply_updates,
    enforce_user_scope,
    normalize_meal_item_serving_fields,
    require_meal_item,
    require_meal_log,
)
from ..models import FoodLog, MealItem, MealLog, User
from ..schemas import MealItemCreate, MealItemOut, MealItemUpdate
from ..services.user_food_history import UserFoodHistoryService

router = APIRouter(tags=["Meal Items"], responses=AUTHENTICATED_RESPONSES)
_food_history_service = UserFoodHistoryService()


@router.get("/users/{user_id}/meal-items", response_model=list[MealItemOut])
def list_meal_items(
    user_id: int,
    meal_log_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    query = (
        select(MealItem)
        .join(MealLog, MealItem.meal_log_id == MealLog.meal_log_id)
        .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
        .where(FoodLog.user_id == user_id)
        .order_by(MealItem.meal_item_id)
    )

    if meal_log_id is not None:
        query = query.where(MealItem.meal_log_id == meal_log_id)

    return db.execute(query).scalars().all()


@router.post(
    "/users/{user_id}/meal-items",
    response_model=MealItemOut,
    status_code=status.HTTP_201_CREATED,
)
def create_meal_item(
    user_id: int,
    payload: MealItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    meal_log = require_meal_log(db, user_id, payload.meal_log_id)

    data = payload.model_dump()
    serving_size, quantity = normalize_meal_item_serving_fields(
        payload.serving_size,
        payload.quantity,
    )
    data["serving_size"] = serving_size
    data["quantity"] = quantity

    meal_item = MealItem(**data)
    db.add(meal_item)
    db.flush()
    _food_history_service.sync_history_entry(
        db,
        user_id=user_id,
        normalized_name=meal_item.meal_name,
        meal_type=meal_log.meal_type,
    )
    db.commit()
    db.refresh(meal_item)
    return meal_item


@router.get("/users/{user_id}/meal-items/{meal_item_id}", response_model=MealItemOut)
def get_meal_item(
    user_id: int,
    meal_item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_meal_item(db, user_id, meal_item_id)


@router.put("/users/{user_id}/meal-items/{meal_item_id}", response_model=MealItemOut)
def update_meal_item(
    user_id: int,
    meal_item_id: int,
    payload: MealItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    meal_item = require_meal_item(db, user_id, meal_item_id)
    old_meal_type = db.scalar(
        select(MealLog.meal_type).where(MealLog.meal_log_id == meal_item.meal_log_id)
    )
    old_name = meal_item.meal_name

    data = payload.model_dump(exclude_unset=True)
    if "serving_size" in data or "quantity" in data:
        serving_size, quantity = normalize_meal_item_serving_fields(
            payload.serving_size if "serving_size" in data else meal_item.serving_size,
            payload.quantity if "quantity" in data else meal_item.quantity,
        )
        if "serving_size" in data:
            data["serving_size"] = serving_size
        if "quantity" in data:
            data["quantity"] = quantity
    new_meal_log_id = data.get("meal_log_id")
    new_meal_log = None
    if new_meal_log_id is not None:
        new_meal_log = require_meal_log(db, user_id, new_meal_log_id)

    apply_updates(meal_item, data)
    db.flush()
    _food_history_service.sync_history_entries(
        db,
        user_id=user_id,
        names={old_name},
        meal_type=old_meal_type,
    )
    _food_history_service.sync_history_entries(
        db,
        user_id=user_id,
        names={meal_item.meal_name},
        meal_type=(new_meal_log.meal_type if new_meal_log is not None else old_meal_type),
    )
    db.commit()
    db.refresh(meal_item)
    return meal_item


@router.delete(
    "/users/{user_id}/meal-items/{meal_item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_meal_item(
    user_id: int,
    meal_item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    meal_item = require_meal_item(db, user_id, meal_item_id)
    old_meal_type = db.scalar(
        select(MealLog.meal_type).where(MealLog.meal_log_id == meal_item.meal_log_id)
    )
    old_name = meal_item.meal_name
    db.delete(meal_item)
    db.flush()
    _food_history_service.sync_history_entries(
        db,
        user_id=user_id,
        names={old_name},
        meal_type=old_meal_type,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
