from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .models import (
    FoodLog,
    MealItem,
    MealLog,
    SavedMeal,
    User,
    UserGoal,
    UserProfile,
    WeightEntry,
)


def enforce_user_scope(user_id: int, current_user: User) -> None:
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized for this user")


def apply_updates(instance: object, data: dict[str, object]) -> None:
    for field_name, value in data.items():
        setattr(instance, field_name, value)


def normalize_meal_item_serving_fields(
    serving_size: int | None,
    quantity: float | None,
) -> tuple[int | None, float | None]:
    if serving_size is None or quantity is None:
        return serving_size, quantity

    # Guard against older clients that briefly sent these fields swapped.
    if serving_size <= 5 and quantity >= 10 and quantity.is_integer():
        return int(quantity), float(serving_size)

    return serving_size, quantity


def get_profile_by_user_id(db: Session, user_id: int) -> UserProfile | None:
    return db.execute(
        select(UserProfile).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()


def require_user(db: Session, user_id: int) -> User:
    user = db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def require_profile(db: Session, user_id: int, profile_id: int) -> UserProfile:
    profile = db.execute(
        select(UserProfile).where(
            UserProfile.user_id == user_id,
            UserProfile.profile_id == profile_id,
        )
    ).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


def require_goal(db: Session, user_id: int, goal_id: int) -> UserGoal:
    goal = db.execute(
        select(UserGoal).where(
            UserGoal.user_id == user_id,
            UserGoal.goal_id == goal_id,
        )
    ).scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return goal


def require_food_log(db: Session, user_id: int, food_log_id: int) -> FoodLog:
    food_log = db.execute(
        select(FoodLog).where(
            FoodLog.user_id == user_id,
            FoodLog.food_log_id == food_log_id,
        )
    ).scalar_one_or_none()
    if not food_log:
        raise HTTPException(status_code=404, detail="Food log not found")
    return food_log


def require_meal_log(db: Session, user_id: int, meal_log_id: int) -> MealLog:
    meal_log = db.execute(
        select(MealLog)
        .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
        .where(
            FoodLog.user_id == user_id,
            MealLog.meal_log_id == meal_log_id,
        )
    ).scalar_one_or_none()
    if not meal_log:
        raise HTTPException(status_code=404, detail="Meal log not found")
    return meal_log


def require_meal_item(db: Session, user_id: int, meal_item_id: int) -> MealItem:
    meal_item = db.execute(
        select(MealItem)
        .join(MealLog, MealItem.meal_log_id == MealLog.meal_log_id)
        .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
        .where(
            FoodLog.user_id == user_id,
            MealItem.meal_item_id == meal_item_id,
        )
    ).scalar_one_or_none()
    if not meal_item:
        raise HTTPException(status_code=404, detail="Meal item not found")
    return meal_item


def require_saved_meal(db: Session, user_id: int, saved_meal_id: int) -> SavedMeal:
    saved_meal = db.execute(
        select(SavedMeal).where(
            SavedMeal.user_id == user_id,
            SavedMeal.saved_meal_id == saved_meal_id,
        )
    ).scalar_one_or_none()
    if not saved_meal:
        raise HTTPException(status_code=404, detail="Saved meal not found")
    return saved_meal


def require_weight_entry(db: Session, user_id: int, weight_entry_id: int) -> WeightEntry:
    weight_entry = db.execute(
        select(WeightEntry).where(
            WeightEntry.user_id == user_id,
            WeightEntry.weight_entry_id == weight_entry_id,
        )
    ).scalar_one_or_none()
    if not weight_entry:
        raise HTTPException(status_code=404, detail="Weight entry not found")
    return weight_entry
