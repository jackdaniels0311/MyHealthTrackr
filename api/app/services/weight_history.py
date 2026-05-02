from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from ..dependencies import require_weight_entry
from ..models import UserProfile, WeightEntry
from .nutrition_targets import NutritionTargetCalculator


class WeightHistoryService:
    def __init__(self) -> None:
        self._nutrition_target_calculator = NutritionTargetCalculator()

    def list_entries(self, db: Session, *, user_id: int) -> list[WeightEntry]:
        statement = (
            select(WeightEntry)
            .where(WeightEntry.user_id == user_id)
            .order_by(WeightEntry.recorded_at.asc(), WeightEntry.weight_entry_id.asc())
        )
        return db.execute(statement).scalars().all()

    def create_entry_and_sync_profile(
        self,
        db: Session,
        *,
        user_id: int,
        weight_kg: float,
        recorded_at: datetime | None = None,
    ) -> WeightEntry:
        normalized_weight = _normalize_weight(weight_kg)
        if normalized_weight is None:
            raise ValueError("A valid weight is required.")

        profile = db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        ).scalar_one_or_none()
        if profile is None:
            profile = UserProfile(user_id=user_id)
            db.add(profile)

        profile.weight_kg = normalized_weight

        weight_entry = WeightEntry(
            user_id=user_id,
            weight_kg=normalized_weight,
            recorded_at=(
                _normalize_recorded_at(recorded_at)
                if recorded_at is not None
                else datetime.now(timezone.utc)
            ),
        )
        db.add(weight_entry)
        db.flush()
        self._sync_profile_to_latest_entry(db, user_id=user_id)
        return weight_entry

    def update_entry_and_sync_profile(
        self,
        db: Session,
        *,
        user_id: int,
        weight_entry_id: int,
        weight_kg: float,
        recorded_at: datetime | None = None,
    ) -> WeightEntry:
        normalized_weight = _normalize_weight(weight_kg)
        if normalized_weight is None:
            raise ValueError("A valid weight is required.")

        weight_entry = require_weight_entry(db, user_id, weight_entry_id)
        weight_entry.weight_kg = normalized_weight
        if recorded_at is not None:
            weight_entry.recorded_at = _normalize_recorded_at(recorded_at)
        db.flush()
        self._sync_profile_to_latest_entry(db, user_id=user_id)
        return weight_entry

    def delete_entry_and_sync_profile(
        self,
        db: Session,
        *,
        user_id: int,
        weight_entry_id: int,
    ) -> None:
        weight_entry = require_weight_entry(db, user_id, weight_entry_id)
        db.delete(weight_entry)
        db.flush()
        self._sync_profile_to_latest_entry(db, user_id=user_id)

    def sync_entry_for_profile_weight(
        self,
        db: Session,
        *,
        user_id: int,
        previous_weight: float | None,
        new_weight: float | None,
    ) -> None:
        normalized_new_weight = _normalize_weight(new_weight)
        if normalized_new_weight is None:
            return

        normalized_previous_weight = _normalize_weight(previous_weight)
        if (
            normalized_previous_weight is not None
            and abs(normalized_previous_weight - normalized_new_weight) < 0.005
        ):
            return

        latest_entry = db.execute(
            select(WeightEntry)
            .where(WeightEntry.user_id == user_id)
            .order_by(desc(WeightEntry.recorded_at), desc(WeightEntry.weight_entry_id))
            .limit(1)
        ).scalar_one_or_none()

        if latest_entry is not None:
            latest_weight = _normalize_weight(latest_entry.weight_kg)
            if latest_weight is not None and abs(latest_weight - normalized_new_weight) < 0.005:
                return

        db.add(
            WeightEntry(
                user_id=user_id,
                weight_kg=normalized_new_weight,
                recorded_at=datetime.now(timezone.utc),
            )
        )

    def _sync_profile_to_latest_entry(self, db: Session, *, user_id: int) -> None:
        profile = db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        ).scalar_one_or_none()
        latest_entry = db.execute(
            select(WeightEntry)
            .where(WeightEntry.user_id == user_id)
            .order_by(desc(WeightEntry.recorded_at), desc(WeightEntry.weight_entry_id))
            .limit(1)
        ).scalar_one_or_none()

        if profile is None and latest_entry is None:
            return

        if profile is None:
            profile = UserProfile(user_id=user_id)
            db.add(profile)

        profile.weight_kg = (
            _normalize_weight(latest_entry.weight_kg) if latest_entry is not None else None
        )
        db.flush()
        self._nutrition_target_calculator.sync_or_clear_for_user(db, user_id)
        db.flush()


def _normalize_weight(value: float | None) -> float | None:
    if value is None:
        return None
    return round(float(value), 2)


def _normalize_recorded_at(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
