from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import get_current_user
from ..db import get_db
from ..deps import enforce_user_scope, get_profile_by_user_id
from ..models import User
from ..schemas import MealPlanGenerateRequest, MealPlanOut
from ..services.gemini_meal_plans import (
    GeminiMealPlanConfigError,
    GeminiMealPlanError,
    GeminiMealPlanService,
)
from ..services.nutrition_targets import NutritionTargetCalculator

router = APIRouter(tags=["Meal Plans"])

_nutrition_target_calculator = NutritionTargetCalculator()
_meal_plan_service = GeminiMealPlanService()


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
