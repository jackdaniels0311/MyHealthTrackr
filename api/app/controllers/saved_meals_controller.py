from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, selectinload

from ..core.api_docs import AUTHENTICATED_RESPONSES
from ..core.auth import get_current_user
from ..database.session import get_db
from ..dependencies import (
    enforce_user_scope,
    normalize_meal_item_serving_fields,
    require_saved_meal,
)
from ..models import FoodLog, MealItem, MealLog, SavedMeal, SavedMealItem, User
from ..schemas import (
    SavedMealCreate,
    SavedMealItemCreate,
    SavedMealLogRequest,
    SavedMealLogResult,
    SavedMealOut,
    SavedMealUpdate,
)
from ..services.food_logs import find_or_create_food_log_for_datetime
from ..services.user_food_history import UserFoodHistoryService

router = APIRouter(tags=["Saved Meals"], responses=AUTHENTICATED_RESPONSES)
_food_history_service = UserFoodHistoryService()


@router.get("/users/{user_id}/saved-meals", response_model=list[SavedMealOut])
def list_saved_meals(
    user_id: int,
    meal_type: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    normalized_meal_type = _normalize_saved_meal_type(meal_type)
    query = (
        select(SavedMeal)
        .options(selectinload(SavedMeal.items))
        .where(SavedMeal.user_id == user_id)
        .order_by(SavedMeal.updated_at.desc(), SavedMeal.saved_meal_id.desc())
    )
    if normalized_meal_type is not None:
        query = query.where(
            or_(
                SavedMeal.meal_type == normalized_meal_type,
                SavedMeal.meal_type.is_(None),
            )
        )
    return db.execute(query).scalars().all()


@router.post(
    "/users/{user_id}/saved-meals",
    response_model=SavedMealOut,
    status_code=status.HTTP_201_CREATED,
)
def create_saved_meal(
    user_id: int,
    payload: SavedMealCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    saved_meal = SavedMeal(
        user_id=user_id,
        name=payload.name.strip(),
        meal_type=_normalize_saved_meal_type(payload.meal_type, required=True),
    )
    db.add(saved_meal)
    db.flush()

    saved_meal.items = _build_saved_meal_items(payload.items)
    db.commit()
    return _get_saved_meal_with_items(db, user_id=user_id, saved_meal_id=saved_meal.saved_meal_id)


@router.get("/users/{user_id}/saved-meals/{saved_meal_id}", response_model=SavedMealOut)
def get_saved_meal(
    user_id: int,
    saved_meal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return _get_saved_meal_with_items(db, user_id=user_id, saved_meal_id=saved_meal_id)


@router.put("/users/{user_id}/saved-meals/{saved_meal_id}", response_model=SavedMealOut)
def update_saved_meal(
    user_id: int,
    saved_meal_id: int,
    payload: SavedMealUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    saved_meal = _get_saved_meal_with_items(db, user_id=user_id, saved_meal_id=saved_meal_id)

    if payload.name is not None:
        saved_meal.name = payload.name.strip()

    if payload.meal_type is not None:
        saved_meal.meal_type = _normalize_saved_meal_type(
            payload.meal_type,
            required=True,
        )

    if payload.items is not None:
        saved_meal.items = _build_saved_meal_items(payload.items)

    db.commit()
    return _get_saved_meal_with_items(db, user_id=user_id, saved_meal_id=saved_meal_id)


@router.delete(
    "/users/{user_id}/saved-meals/{saved_meal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_saved_meal(
    user_id: int,
    saved_meal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    saved_meal = require_saved_meal(db, user_id, saved_meal_id)
    db.delete(saved_meal)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/users/{user_id}/saved-meals/{saved_meal_id}/log",
    response_model=SavedMealLogResult,
    status_code=status.HTTP_201_CREATED,
)
def log_saved_meal(
    user_id: int,
    saved_meal_id: int,
    payload: SavedMealLogRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    saved_meal = _get_saved_meal_with_items(db, user_id=user_id, saved_meal_id=saved_meal_id)

    target_date = payload.log_date
    meal_type = payload.meal_type.strip()
    items_payload = payload.items or [
        SavedMealItemCreate(
            meal_name=item.meal_name,
            serving_size=item.serving_size,
            quantity=float(item.quantity) if item.quantity is not None else None,
            calories=float(item.calories) if item.calories is not None else None,
            protein=float(item.protein) if item.protein is not None else None,
            carbs=float(item.carbs) if item.carbs is not None else None,
            fat=float(item.fat) if item.fat is not None else None,
            fibre=float(item.fibre) if item.fibre is not None else None,
            sugar=float(item.sugar) if item.sugar is not None else None,
        )
        for item in saved_meal.items
    ]

    food_log = _find_or_create_food_log(
        db,
        user_id=user_id,
        target_date=target_date,
    )
    meal_log = _find_or_create_meal_log(
        db,
        food_log_id=food_log.food_log_id,
        meal_type=meal_type,
        meal_logged_at=target_date,
    )

    names: set[str] = set()
    meal_group_id = str(uuid4())
    meal_group_name = saved_meal.name.strip()
    for item_payload in items_payload:
        data = _normalized_item_data(item_payload)
        meal_item = MealItem(
            meal_log_id=meal_log.meal_log_id,
            meal_group_id=meal_group_id,
            meal_group_name=meal_group_name,
            meal_logged_at=target_date,
            **data,
        )
        names.add(meal_item.meal_name)
        db.add(meal_item)

    db.flush()
    _food_history_service.sync_history_entries(
        db,
        user_id=user_id,
        names=names,
        meal_type=meal_type,
    )
    db.commit()

    return SavedMealLogResult(
        food_log_id=food_log.food_log_id,
        meal_log_id=meal_log.meal_log_id,
        items_created=len(items_payload),
    )


def _get_saved_meal_with_items(db: Session, *, user_id: int, saved_meal_id: int) -> SavedMeal:
    query = (
        select(SavedMeal)
        .options(selectinload(SavedMeal.items))
        .where(
            SavedMeal.user_id == user_id,
            SavedMeal.saved_meal_id == saved_meal_id,
        )
    )
    saved_meal = db.execute(query).scalar_one_or_none()
    if saved_meal is None:
        require_saved_meal(db, user_id, saved_meal_id)
        saved_meal = db.execute(query).scalar_one()
    return saved_meal


def _build_saved_meal_items(items: list[SavedMealItemCreate]) -> list[SavedMealItem]:
    return [SavedMealItem(**_normalized_item_data(item)) for item in items]


def _normalize_saved_meal_type(
    meal_type: str | None,
    *,
    required: bool = False,
) -> str | None:
    if meal_type is None:
        if required:
            raise HTTPException(status_code=400, detail="Saved meal type is required")
        return None
    normalized = meal_type.strip().lower()
    if not normalized:
        if required:
            raise HTTPException(status_code=400, detail="Saved meal type is required")
        return None
    if normalized == "snack":
        return "Snacks"
    allowed = {
        "breakfast": "Breakfast",
        "lunch": "Lunch",
        "dinner": "Dinner",
        "snacks": "Snacks",
    }
    resolved = allowed.get(normalized)
    if resolved is None:
        raise HTTPException(status_code=400, detail="Invalid saved meal type")
    return resolved


def _normalized_item_data(item: SavedMealItemCreate) -> dict[str, object]:
    serving_size, quantity = normalize_meal_item_serving_fields(
        item.serving_size,
        item.quantity,
    )
    return {
        "meal_name": item.meal_name.strip(),
        "serving_size": serving_size,
        "quantity": quantity,
        "calories": item.calories,
        "protein": item.protein,
        "carbs": item.carbs,
        "fat": item.fat,
        "fibre": item.fibre,
        "sugar": item.sugar,
    }


def _find_or_create_food_log(
    db: Session,
    *,
    user_id: int,
    target_date: datetime,
) -> FoodLog:
    food_log, _ = find_or_create_food_log_for_datetime(
        db,
        user_id=user_id,
        log_date=target_date,
    )
    return food_log


def _find_or_create_meal_log(
    db: Session,
    *,
    food_log_id: int,
    meal_type: str,
    meal_logged_at: datetime,
) -> MealLog:
    meal_logs = db.execute(
        select(MealLog).where(MealLog.food_log_id == food_log_id)
    ).scalars().all()
    normalized_type = meal_type.lower()

    for meal_log in meal_logs:
        if meal_log.meal_type.strip().lower() == normalized_type:
            return meal_log

    meal_log = MealLog(
        food_log_id=food_log_id,
        meal_type=meal_type,
        meal_logged_at=meal_logged_at,
    )
    db.add(meal_log)
    db.flush()
    return meal_log
