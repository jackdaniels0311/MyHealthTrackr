from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..models import FoodLog


def log_day_from_datetime(value: datetime) -> date:
    local_value = value.astimezone() if value.tzinfo is not None else value
    return local_value.date()


def find_food_log_for_day(db: Session, *, user_id: int, log_day: date) -> FoodLog | None:
    return db.execute(
        select(FoodLog).where(
            FoodLog.user_id == user_id,
            FoodLog.log_day == log_day,
        )
    ).scalar_one_or_none()


def find_or_create_food_log_for_datetime(
    db: Session,
    *,
    user_id: int,
    log_date: datetime,
) -> tuple[FoodLog, bool]:
    log_day = log_day_from_datetime(log_date)
    existing_log = find_food_log_for_day(db, user_id=user_id, log_day=log_day)
    if existing_log is not None:
        return existing_log, False

    food_log = FoodLog(user_id=user_id, log_date=log_date, log_day=log_day)
    db.add(food_log)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        existing_log = find_food_log_for_day(db, user_id=user_id, log_day=log_day)
        if existing_log is not None:
            return existing_log, False
        raise

    return food_log, True
