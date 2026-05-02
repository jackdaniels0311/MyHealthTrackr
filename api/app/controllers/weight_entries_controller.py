from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from ..api_docs import AUTHENTICATED_RESPONSES
from ..auth import get_current_user
from ..db import get_db
from ..deps import enforce_user_scope
from ..models import User
from ..schemas import WeightEntryCreate, WeightEntryOut, WeightEntryUpdate
from ..services.weight_history import WeightHistoryService

router = APIRouter(tags=["Weight Entries"], responses=AUTHENTICATED_RESPONSES)
_weight_history_service = WeightHistoryService()


@router.get("/users/{user_id}/weight-entries", response_model=list[WeightEntryOut])
def list_weight_entries(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return _weight_history_service.list_entries(db, user_id=user_id)


@router.post(
    "/users/{user_id}/weight-entries",
    response_model=WeightEntryOut,
    status_code=status.HTTP_201_CREATED,
)
def create_weight_entry(
    user_id: int,
    payload: WeightEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    weight_entry = _weight_history_service.create_entry_and_sync_profile(
        db,
        user_id=user_id,
        weight_kg=payload.weight_kg,
        recorded_at=payload.recorded_at,
    )
    db.commit()
    db.refresh(weight_entry)
    return weight_entry


@router.put("/users/{user_id}/weight-entries/{weight_entry_id}", response_model=WeightEntryOut)
def update_weight_entry(
    user_id: int,
    weight_entry_id: int,
    payload: WeightEntryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    weight_entry = _weight_history_service.update_entry_and_sync_profile(
        db,
        user_id=user_id,
        weight_entry_id=weight_entry_id,
        weight_kg=payload.weight_kg,
        recorded_at=payload.recorded_at,
    )
    db.commit()
    db.refresh(weight_entry)
    return weight_entry


@router.delete(
    "/users/{user_id}/weight-entries/{weight_entry_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_weight_entry(
    user_id: int,
    weight_entry_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    _weight_history_service.delete_entry_and_sync_profile(
        db,
        user_id=user_id,
        weight_entry_id=weight_entry_id,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
