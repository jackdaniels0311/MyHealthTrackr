from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.api_docs import MEAL_PLAN_RESPONSES
from ..core.auth import get_current_user
from ..database.session import get_db
from ..deps import enforce_user_scope, get_profile_by_user_id
from ..models import User, UserMealRecommendationPreference
from ..schemas import MealPlanGenerateRequest, MealPlanOut, MealPlanPreferencesOut
from ..services.gemini_meal_plans import (
    GeminiMealPlanConfigError,
    GeminiMealPlanError,
    GeminiMealPlanService,
)
from ..services.nutrition_targets import NutritionTargetCalculator

router = APIRouter(tags=["Meal Plans"], responses=MEAL_PLAN_RESPONSES)

_nutrition_target_calculator = NutritionTargetCalculator()
_meal_plan_service = GeminiMealPlanService()


@router.get(
    "/users/{user_id}/meal-plans/preferences",
    response_model=MealPlanPreferencesOut,
)
def get_meal_plan_preferences(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    preferences = _get_preferences(db, user_id)
    return _preferences_out(preferences)


@router.put(
    "/users/{user_id}/meal-plans/preferences",
    response_model=MealPlanPreferencesOut,
)
def update_meal_plan_preferences(
    user_id: int,
    payload: MealPlanGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    preferences = _upsert_preferences(db, user_id=user_id, payload=payload)
    db.commit()
    db.refresh(preferences)
    return _preferences_out(preferences)


@router.post("/users/{user_id}/meal-plans/generate", response_model=MealPlanOut)
def generate_meal_plan(
    user_id: int,
    payload: MealPlanGenerateRequest | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    profile = get_profile_by_user_id(db, user_id)
    if profile is None:
        raise HTTPException(
            status_code=400,
            detail="A health profile is required before a meal plan can be generated.",
        )

    try:
        nutrition_target = _nutrition_target_calculator.get_stored_for_user(db, user_id)
        if nutrition_target is None:
            nutrition_target = _nutrition_target_calculator.sync_for_user(db, user_id)
            db.commit()
            db.refresh(nutrition_target)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    if payload is not None:
        _upsert_preferences(db, user_id=user_id, payload=payload)
        db.commit()

    try:
        return _meal_plan_service.generate(
            profile=profile,
            nutrition_target=nutrition_target,
            preferences=payload,
        )
    except GeminiMealPlanConfigError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except GeminiMealPlanError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


def _get_preferences(
    db: Session,
    user_id: int,
) -> UserMealRecommendationPreference | None:
    return db.execute(
        select(UserMealRecommendationPreference).where(
            UserMealRecommendationPreference.user_id == user_id,
        )
    ).scalar_one_or_none()


def _upsert_preferences(
    db: Session,
    *,
    user_id: int,
    payload: MealPlanGenerateRequest,
) -> UserMealRecommendationPreference:
    preferences = _get_preferences(db, user_id)
    if preferences is None:
        preferences = UserMealRecommendationPreference(user_id=user_id)
        db.add(preferences)

    preferences.goal_type = payload.goal_type
    preferences.allergies = _clean_text(payload.allergies)
    preferences.dietary_preferences = _clean_text(payload.dietary_preferences)
    preferences.diet_plan_type = _clean_text(payload.diet_plan_type)
    preferences.meal_types = _clean_list(payload.meal_types)
    preferences.diet_targets = _clean_list(payload.diet_targets)
    preferences.disliked_foods = _clean_text(payload.disliked_foods)
    preferences.liked_cuisines = _clean_text(payload.liked_cuisines)
    preferences.disliked_cuisines = _clean_text(payload.disliked_cuisines)
    return preferences


def _preferences_out(
    preferences: UserMealRecommendationPreference | None,
) -> MealPlanPreferencesOut:
    if preferences is None:
        return MealPlanPreferencesOut(has_saved_preferences=False)

    return MealPlanPreferencesOut(
        has_saved_preferences=True,
        goal_type=preferences.goal_type,
        allergies=preferences.allergies,
        dietary_preferences=preferences.dietary_preferences,
        diet_plan_type=preferences.diet_plan_type,
        meal_types=_clean_list(preferences.meal_types or []),
        diet_targets=_clean_list(preferences.diet_targets or []),
        disliked_foods=preferences.disliked_foods,
        liked_cuisines=preferences.liked_cuisines,
        disliked_cuisines=preferences.disliked_cuisines,
    )


def _clean_text(value: str | None) -> str | None:
    trimmed = value.strip() if value is not None else None
    return trimmed or None


def _clean_list(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    for value in values:
        trimmed = value.strip()
        if trimmed and trimmed not in cleaned:
            cleaned.append(trimmed)
    return cleaned
