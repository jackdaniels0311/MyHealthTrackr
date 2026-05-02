from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..api_docs import AUTHENTICATED_RESPONSES
from ..auth import get_current_user
from ..db import get_db
from ..deps import apply_updates, enforce_user_scope, require_goal
from ..models import User, UserGoal
from ..schemas import UserGoalCreate, UserGoalOut, UserGoalUpdate
from ..services.nutrition_targets import NutritionTargetCalculator

router = APIRouter(tags=["User Goals"], responses=AUTHENTICATED_RESPONSES)

_nutrition_target_calculator = NutritionTargetCalculator()


@router.get("/users/{user_id}/goals", response_model=list[UserGoalOut])
def list_goals(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return db.execute(
        select(UserGoal)
        .where(UserGoal.user_id == user_id)
        .order_by(UserGoal.goal_id)
    ).scalars().all()


@router.post(
    "/users/{user_id}/goals",
    response_model=UserGoalOut,
    status_code=status.HTTP_201_CREATED,
)
def create_goal(
    user_id: int,
    payload: UserGoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    goal = UserGoal(user_id=user_id, **payload.model_dump())
    db.add(goal)
    db.flush()
    # Goal changes affect calorie adjustments and macro splits, so resync here.
    _nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
    db.commit()
    db.refresh(goal)
    return goal


@router.get("/users/{user_id}/goals/{goal_id}", response_model=UserGoalOut)
def get_goal(
    user_id: int,
    goal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_goal(db, user_id, goal_id)


@router.put("/users/{user_id}/goals/{goal_id}", response_model=UserGoalOut)
def update_goal(
    user_id: int,
    goal_id: int,
    payload: UserGoalUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    goal = require_goal(db, user_id, goal_id)
    apply_updates(goal, payload.model_dump(exclude_unset=True))
    db.flush()
    # Persist a refreshed recommendation after editing the current goal inputs.
    _nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
    db.commit()
    db.refresh(goal)
    return goal


@router.delete("/users/{user_id}/goals/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_goal(
    user_id: int,
    goal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    goal = require_goal(db, user_id, goal_id)
    db.delete(goal)
    db.flush()
    # Deleting a goal falls back to a maintain-weight recommendation if possible.
    _nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
