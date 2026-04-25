from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import and_, case, func, select
from sqlalchemy.orm import Session

from ..models import FoodLog, MealItem, MealLog, UserFoodItem
from ..schemas import FoodNutrients, FoodSearchResult


class UserFoodHistoryService:
    def sync_history_entry(
        self,
        db: Session,
        *,
        user_id: int,
        normalized_name: str,
        meal_type: str,
    ) -> None:
        normalized_name = self.normalize_name(normalized_name)
        normalized_meal_type = self.normalize_meal_type(meal_type)
        if not normalized_name or normalized_name == "water" or not normalized_meal_type:
            return

        history_item = db.scalar(
            select(UserFoodItem).where(
                UserFoodItem.user_id == user_id,
                UserFoodItem.normalized_name == normalized_name,
                UserFoodItem.meal_type == normalized_meal_type,
            )
        )

        count_statement = (
            select(func.count(MealItem.meal_item_id))
            .select_from(MealItem)
            .join(MealLog, MealItem.meal_log_id == MealLog.meal_log_id)
            .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
            .where(
                FoodLog.user_id == user_id,
                MealLog.meal_type == normalized_meal_type,
                func.lower(func.trim(MealItem.meal_name)) == normalized_name,
            )
        )
        matching_count = db.scalar(count_statement) or 0

        if matching_count == 0:
            if history_item is not None:
                db.delete(history_item)
            return

        latest_item = db.execute(
            select(MealItem)
            .join(MealLog, MealItem.meal_log_id == MealLog.meal_log_id)
            .join(FoodLog, MealLog.food_log_id == FoodLog.food_log_id)
            .where(
                FoodLog.user_id == user_id,
                MealLog.meal_type == normalized_meal_type,
                func.lower(func.trim(MealItem.meal_name)) == normalized_name,
            )
            .order_by(MealItem.meal_logged_at.desc().nullslast(), MealItem.meal_item_id.desc())
            .limit(1)
        ).scalar_one()

        if history_item is None:
            history_item = UserFoodItem(
                user_id=user_id,
                normalized_name=normalized_name,
                meal_type=normalized_meal_type,
            )
            db.add(history_item)

        history_item.meal_name = latest_item.meal_name.strip()
        history_item.meal_type = normalized_meal_type
        history_item.serving_size = latest_item.serving_size
        history_item.quantity = latest_item.quantity
        history_item.calories = latest_item.calories
        history_item.protein = latest_item.protein
        history_item.carbs = latest_item.carbs
        history_item.fat = latest_item.fat
        history_item.fibre = latest_item.fibre
        history_item.sugar = latest_item.sugar
        history_item.times_logged = matching_count
        history_item.last_logged_at = (
            latest_item.meal_logged_at
            or latest_item.meal_log.meal_logged_at
            or latest_item.meal_log.food_log.log_date
            or datetime.now(timezone.utc)
        )

    def sync_history_entries(
        self,
        db: Session,
        *,
        user_id: int,
        names: set[str],
        meal_type: str | None,
    ) -> None:
        normalized_meal_type = self.normalize_meal_type(meal_type)
        if not normalized_meal_type:
            return

        for name in names:
            normalized_name = self.normalize_name(name)
            if not normalized_name or normalized_name == "water":
                continue
            self.sync_history_entry(
                db,
                user_id=user_id,
                normalized_name=normalized_name,
                meal_type=normalized_meal_type,
            )

    def search_for_user(
        self,
        db: Session,
        *,
        user_id: int,
        query: str,
        limit: int,
        meal_type: str | None = None,
    ) -> list[FoodSearchResult]:
        normalized_query = self.normalize_name(query)
        normalized_meal_type = self.normalize_meal_type(meal_type)
        statement = select(UserFoodItem).where(UserFoodItem.user_id == user_id)

        if normalized_meal_type:
            statement = statement.where(UserFoodItem.meal_type == normalized_meal_type)

        if normalized_query:
            search_tokens = [token for token in normalized_query.split(" ") if token]
            if search_tokens:
                statement = statement.where(
                    and_(
                        *(
                            UserFoodItem.normalized_name.contains(search_token)
                            for search_token in search_tokens
                        )
                    )
                )

        exact_match_rank = case(
            (UserFoodItem.normalized_name == normalized_query, 0),
            else_=1,
        )
        prefix_match_rank = case(
            (UserFoodItem.normalized_name.startswith(normalized_query), 0),
            else_=1,
        )

        statement = statement.order_by(
            exact_match_rank,
            prefix_match_rank,
            UserFoodItem.last_logged_at.desc(),
            UserFoodItem.user_food_item_id.desc(),
        ).limit(limit)

        history_items = db.execute(statement).scalars().all()
        return [self.to_search_result(item) for item in history_items]

    def to_search_result(self, item: UserFoodItem) -> FoodSearchResult:
        serving_size = item.serving_size
        quantity = self._as_float(item.quantity) or 1.0

        return FoodSearchResult(
            source="user_history",
            source_id=str(item.user_food_item_id),
            barcode=f"history-{item.user_food_item_id}",
            name=item.meal_name,
            serving_size=f"{serving_size}g" if serving_size is not None else None,
            serving_quantity=quantity,
            serving_unit="g" if serving_size is not None else None,
            times_logged=item.times_logged,
            last_logged_at=item.last_logged_at,
            nutrients=FoodNutrients(
                calories_per_100g=self._per_100g(item.calories, serving_size, quantity),
                protein_per_100g=self._per_100g(item.protein, serving_size, quantity),
                carbs_per_100g=self._per_100g(item.carbs, serving_size, quantity),
                fat_per_100g=self._per_100g(item.fat, serving_size, quantity),
                fibre_per_100g=self._per_100g(item.fibre, serving_size, quantity),
                sugar_per_100g=self._per_100g(item.sugar, serving_size, quantity),
                calories_per_serving=self._as_float(item.calories),
                protein_per_serving=self._as_float(item.protein),
                carbs_per_serving=self._as_float(item.carbs),
                fat_per_serving=self._as_float(item.fat),
                fibre_per_serving=self._as_float(item.fibre),
                sugar_per_serving=self._as_float(item.sugar),
            ),
        )

    @staticmethod
    def normalize_name(value: str | None) -> str:
        if value is None:
            return ""
        return " ".join(value.strip().lower().split())

    @staticmethod
    def normalize_meal_type(value: str | None) -> str:
        if value is None:
            return ""
        return " ".join(value.strip().split())

    @staticmethod
    def _as_float(value: Decimal | float | int | None) -> float | None:
        if value is None:
            return None
        return float(value)

    def _per_100g(
        self,
        total_value: Decimal | float | int | None,
        serving_size: int | None,
        quantity: float,
    ) -> float | None:
        if total_value is None or serving_size is None or serving_size <= 0 or quantity <= 0:
            return None

        total_grams = serving_size * quantity
        if total_grams <= 0:
            return None

        return self._as_float(total_value) * 100 / total_grams
