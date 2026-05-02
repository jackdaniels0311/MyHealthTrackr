from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..core.api_docs import AUTHENTICATED_RESPONSES
from ..core.auth import get_current_user
from ..database.session import get_db
from ..deps import enforce_user_scope
from ..models import User
from ..schemas import NutritionTargetsOut
from ..services.nutrition_targets import NutritionTargetCalculator

router = APIRouter(tags=["Nutrition Targets"], responses=AUTHENTICATED_RESPONSES)

_calculator = NutritionTargetCalculator()


@router.get("/users/me/nutrition-targets", response_model=NutritionTargetsOut)
def get_my_nutrition_targets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        nutrition_target = _calculator.get_stored_for_user(db, current_user.id)
        if nutrition_target is None or _needs_nutrition_target_refresh(nutrition_target):
            nutrition_target = _calculator.sync_for_user(db, current_user.id)
            db.commit()
            db.refresh(nutrition_target)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return nutrition_target


@router.get("/users/{user_id}/nutrition-targets", response_model=NutritionTargetsOut)
def get_nutrition_targets(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)

    try:
        nutrition_target = _calculator.get_stored_for_user(db, user_id)
        if nutrition_target is None or _needs_nutrition_target_refresh(nutrition_target):
            nutrition_target = _calculator.sync_for_user(db, user_id)
            db.commit()
            db.refresh(nutrition_target)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return nutrition_target


def _needs_nutrition_target_refresh(nutrition_target: object) -> bool:
    recommended_water_ml = getattr(nutrition_target, "recommended_water_ml", None)
    if recommended_water_ml is None:
        return True

    try:
        return float(recommended_water_ml) <= 0
    except (TypeError, ValueError):
        return True
