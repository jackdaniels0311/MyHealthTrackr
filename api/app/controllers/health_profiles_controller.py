from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..api_docs import CONFLICT_RESPONSES
from ..auth import get_current_user
from ..db import get_db
from ..deps import (
    apply_updates,
    enforce_user_scope,
    get_profile_by_user_id,
    require_profile,
    require_user,
)
from ..models import User, UserProfile
from ..schemas import UserProfileIn, UserProfileOut
from ..services.nutrition_targets import NutritionTargetCalculator
from ..services.weight_history import WeightHistoryService

router = APIRouter(tags=["Health Profiles"], responses=CONFLICT_RESPONSES)

_nutrition_target_calculator = NutritionTargetCalculator()
_weight_history_service = WeightHistoryService()


@router.get("/users/{user_id}/health-profiles", response_model=list[UserProfileOut])
def list_profiles(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return db.execute(
        select(UserProfile)
        .where(UserProfile.user_id == user_id)
        .order_by(UserProfile.profile_id)
    ).scalars().all()


@router.post(
    "/users/{user_id}/health-profiles",
    response_model=UserProfileOut,
    status_code=status.HTTP_201_CREATED,
)
def create_profile(
    user_id: int,
    payload: UserProfileIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    require_user(db, user_id)

    existing_profile = get_profile_by_user_id(db, user_id)
    if existing_profile:
        raise HTTPException(status_code=409, detail="Profile already exists")

    profile = UserProfile(user_id=user_id)
    previous_weight = None
    apply_updates(profile, payload.model_dump(exclude_unset=True))
    db.add(profile)
    db.flush()
    _weight_history_service.sync_entry_for_profile_weight(
        db,
        user_id=user_id,
        previous_weight=previous_weight,
        new_weight=profile.weight_kg,
    )
    # Recompute the persisted nutrition target immediately after profile writes.
    _nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
    db.commit()
    db.refresh(profile)
    return profile


@router.get("/users/{user_id}/health-profiles/{profile_id}", response_model=UserProfileOut)
def get_profile(
    user_id: int,
    profile_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_profile(db, user_id, profile_id)


@router.put("/users/{user_id}/health-profiles/{profile_id}", response_model=UserProfileOut)
def update_profile(
    user_id: int,
    profile_id: int,
    payload: UserProfileIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    profile = require_profile(db, user_id, profile_id)
    previous_weight = float(profile.weight_kg) if profile.weight_kg is not None else None
    apply_updates(profile, payload.model_dump(exclude_unset=True))
    db.flush()
    _weight_history_service.sync_entry_for_profile_weight(
        db,
        user_id=user_id,
        previous_weight=previous_weight,
        new_weight=profile.weight_kg,
    )
    # Keep the stored target aligned with the latest profile inputs.
    _nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
    db.commit()
    db.refresh(profile)
    return profile


@router.delete(
    "/users/{user_id}/health-profiles/{profile_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_profile(
    user_id: int,
    profile_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    profile = require_profile(db, user_id, profile_id)
    db.delete(profile)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/users/profile", response_model=UserProfileOut, include_in_schema=False)
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = get_profile_by_user_id(db, current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


@router.put("/users/profile", response_model=UserProfileOut, include_in_schema=False)
def upsert_profile(
    payload: UserProfileIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = get_profile_by_user_id(db, current_user.id)
    previous_weight = (
        float(profile.weight_kg)
        if profile is not None and profile.weight_kg is not None
        else None
    )

    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    apply_updates(profile, payload.model_dump(exclude_unset=True))
    db.flush()
    _weight_history_service.sync_entry_for_profile_weight(
        db,
        user_id=current_user.id,
        previous_weight=previous_weight,
        new_weight=profile.weight_kg,
    )
    # Upserts can create or invalidate the derived row depending on completeness.
    _nutrition_target_calculator.sync_or_clear_for_user(db, current_user.id)
    db.commit()
    db.refresh(profile)
    return profile
