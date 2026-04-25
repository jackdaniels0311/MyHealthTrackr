from __future__ import annotations

import sys
from pathlib import Path

from sqlalchemy import delete, func, select

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import SessionLocal
from app.models import FoodLog, MealItem, MealLog, UserFoodItem
from app.services.user_food_history import UserFoodHistoryService


def main() -> None:
    service = UserFoodHistoryService()
    db = SessionLocal()

    try:
        db.execute(delete(UserFoodItem))

        history_keys = db.execute(
            select(
                FoodLog.user_id,
                func.lower(func.trim(MealItem.meal_name)),
                MealLog.meal_type,
            )
            .join(MealLog, MealItem.meal_log_id == MealLog.meal_log_id)
            .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
            .where(
                func.trim(MealItem.meal_name) != "",
                func.lower(func.trim(MealItem.meal_name)) != "water",
            )
            .distinct()
            .order_by(FoodLog.user_id, MealLog.meal_type, func.lower(func.trim(MealItem.meal_name)))
        ).all()

        for user_id, normalized_name, meal_type in history_keys:
            service.sync_history_entry(
                db,
                user_id=user_id,
                normalized_name=normalized_name,
                meal_type=meal_type,
            )

        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    print(
        "Backfill complete: "
        f"history_entries_rebuilt={len(history_keys)}"
    )


if __name__ == "__main__":
    main()
