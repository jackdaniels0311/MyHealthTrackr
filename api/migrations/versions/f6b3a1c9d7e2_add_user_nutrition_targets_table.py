"""add user nutrition targets table

Revision ID: f6b3a1c9d7e2
Revises: e4a1b6c9d2f3
Create Date: 2026-04-14 18:30:00.000000

"""

from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "f6b3a1c9d7e2"
down_revision: Union[str, None] = "e4a1b6c9d2f3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


_ACTIVITY_MULTIPLIERS = {
    "Not Active": 1.2,
    "Lightly Active": 1.375,
    "Active": 1.55,
    "Very Active": 1.725,
}

_GOAL_WEEKLY_DEFAULTS = {
    "Lose Weight": -0.25,
    "Maintain Weight": 0.0,
    "Gain Weight": 0.25,
}

_MACRO_RATIOS = {
    "Lose Weight": {"protein": 0.30, "fat": 0.25, "carbs": 0.45},
    "Maintain Weight": {"protein": 0.25, "fat": 0.30, "carbs": 0.45},
    "Gain Weight": {"protein": 0.25, "fat": 0.25, "carbs": 0.50},
}

_CALORIES_PER_KG_PER_WEEK = 7700 / 7
_CALCULATION_VERSION = "mifflin_st_jeor_v1"
_CALCULATION_METHOD = (
    "Calories are estimated with Mifflin-St Jeor BMR, scaled by activity "
    "level to TDEE, then adjusted by the user's weekly goal. Macros are "
    "derived from goal-specific calorie ratios, with fibre set to 14g per "
    "1000 kcal and sugar capped at 10% of calories."
)


def upgrade() -> None:
    op.create_table(
        "user_nutrition_targets",
        sa.Column("nutrition_target_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("profile_id", sa.Integer(), nullable=False),
        sa.Column("goal_id", sa.Integer(), nullable=True),
        sa.Column("calculation_version", sa.String(length=50), nullable=False),
        sa.Column("calculation_method", sa.String(length=500), nullable=False),
        sa.Column("age_years", sa.Integer(), nullable=False),
        sa.Column("weight_kg", sa.Numeric(precision=8, scale=2), nullable=False),
        sa.Column("height_cm", sa.Numeric(precision=6, scale=2), nullable=False),
        sa.Column("activity_level", sa.String(length=30), nullable=False),
        sa.Column("activity_multiplier", sa.Numeric(precision=5, scale=3), nullable=False),
        sa.Column("goal_type", sa.String(length=100), nullable=False),
        sa.Column("weekly_goal_kg", sa.Numeric(precision=4, scale=2), nullable=False),
        sa.Column("bmr_kcal", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("tdee_kcal", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("calorie_adjustment_kcal", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_calories_kcal", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_protein_g", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_carbs_g", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_fat_g", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_fibre_g", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("recommended_sugar_g_max", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["profile_id"],
            ["health_profiles.profile_id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(["goal_id"], ["user_goals.goal_id"], ondelete="SET NULL"),
        sa.UniqueConstraint("profile_id", name="uq_user_nutrition_targets_profile_id"),
        sa.UniqueConstraint("goal_id", name="uq_user_nutrition_targets_goal_id"),
    )
    op.create_index(
        "ix_user_nutrition_targets_user_id",
        "user_nutrition_targets",
        ["user_id"],
        unique=True,
    )

    bind = op.get_bind()
    # Backfill only users whose stored profile already has enough data for a
    # deterministic recommendation.
    rows = bind.execute(
        sa.text(
            """
            SELECT
                hp.user_id,
                hp.profile_id,
                hp.date_of_birth,
                hp.gender,
                hp.height_cm,
                hp.weight_kg,
                hp.activity_level,
                goal.goal_id,
                goal.goal_type,
                goal.weekly_goal
            FROM health_profiles AS hp
            LEFT JOIN LATERAL (
                SELECT
                    ug.goal_id,
                    ug.goal_type,
                    ug.weekly_goal
                FROM user_goals AS ug
                WHERE ug.user_id = hp.user_id
                ORDER BY ug.goal_start_date DESC, ug.goal_id DESC
                LIMIT 1
            ) AS goal ON TRUE
            WHERE hp.date_of_birth IS NOT NULL
              AND hp.height_cm IS NOT NULL
              AND hp.weight_kg IS NOT NULL
              AND hp.activity_level IS NOT NULL
            """
        )
    ).mappings()

    payloads = []
    for row in rows:
        payloads.append(_build_target_payload(row))

    if payloads:
        bind.execute(
            sa.table(
                "user_nutrition_targets",
                sa.column("user_id", sa.Integer()),
                sa.column("profile_id", sa.Integer()),
                sa.column("goal_id", sa.Integer()),
                sa.column("calculation_version", sa.String()),
                sa.column("calculation_method", sa.String()),
                sa.column("age_years", sa.Integer()),
                sa.column("weight_kg", sa.Numeric()),
                sa.column("height_cm", sa.Numeric()),
                sa.column("activity_level", sa.String()),
                sa.column("activity_multiplier", sa.Numeric()),
                sa.column("goal_type", sa.String()),
                sa.column("weekly_goal_kg", sa.Numeric()),
                sa.column("bmr_kcal", sa.Numeric()),
                sa.column("tdee_kcal", sa.Numeric()),
                sa.column("calorie_adjustment_kcal", sa.Numeric()),
                sa.column("recommended_calories_kcal", sa.Numeric()),
                sa.column("recommended_protein_g", sa.Numeric()),
                sa.column("recommended_carbs_g", sa.Numeric()),
                sa.column("recommended_fat_g", sa.Numeric()),
                sa.column("recommended_fibre_g", sa.Numeric()),
                sa.column("recommended_sugar_g_max", sa.Numeric()),
            ).insert(),
            payloads,
        )


def downgrade() -> None:
    op.drop_index("ix_user_nutrition_targets_user_id", table_name="user_nutrition_targets")
    op.drop_table("user_nutrition_targets")


def _build_target_payload(row: sa.RowMapping) -> dict[str, object]:
    age_years = _calculate_age(row["date_of_birth"])
    weight_kg = float(row["weight_kg"])
    height_cm = float(row["height_cm"])
    gender = row["gender"]
    activity_level = row["activity_level"]
    activity_multiplier = _ACTIVITY_MULTIPLIERS[activity_level]

    bmr_kcal = _calculate_bmr(
        weight_kg=weight_kg,
        height_cm=height_cm,
        age_years=age_years,
        gender=gender,
    )
    tdee_kcal = bmr_kcal * activity_multiplier

    goal_type = row["goal_type"] or "Maintain Weight"
    weekly_goal_kg = (
        float(row["weekly_goal"])
        if row["weekly_goal"] is not None
        else _GOAL_WEEKLY_DEFAULTS[goal_type]
    )
    calorie_adjustment_kcal = weekly_goal_kg * _CALORIES_PER_KG_PER_WEEK
    recommended_calories_kcal = _apply_calorie_floor(
        tdee_kcal + calorie_adjustment_kcal,
        gender=gender,
    )

    macro_ratios = _MACRO_RATIOS[goal_type]
    recommended_protein_g = recommended_calories_kcal * macro_ratios["protein"] / 4
    recommended_carbs_g = recommended_calories_kcal * macro_ratios["carbs"] / 4
    recommended_fat_g = recommended_calories_kcal * macro_ratios["fat"] / 9
    recommended_fibre_g = recommended_calories_kcal / 1000 * 14
    recommended_sugar_g_max = recommended_calories_kcal * 0.10 / 4

    return {
        "user_id": row["user_id"],
        "profile_id": row["profile_id"],
        "goal_id": row["goal_id"],
        "calculation_version": _CALCULATION_VERSION,
        "calculation_method": _CALCULATION_METHOD,
        "age_years": age_years,
        "weight_kg": _rounded_decimal(weight_kg),
        "height_cm": _rounded_decimal(height_cm),
        "activity_level": activity_level,
        "activity_multiplier": _rounded_decimal(activity_multiplier, places=3),
        "goal_type": goal_type,
        "weekly_goal_kg": _rounded_decimal(weekly_goal_kg),
        "bmr_kcal": _rounded_decimal(bmr_kcal),
        "tdee_kcal": _rounded_decimal(tdee_kcal),
        "calorie_adjustment_kcal": _rounded_decimal(calorie_adjustment_kcal),
        "recommended_calories_kcal": _rounded_decimal(recommended_calories_kcal),
        "recommended_protein_g": _rounded_decimal(recommended_protein_g),
        "recommended_carbs_g": _rounded_decimal(recommended_carbs_g),
        "recommended_fat_g": _rounded_decimal(recommended_fat_g),
        "recommended_fibre_g": _rounded_decimal(recommended_fibre_g),
        "recommended_sugar_g_max": _rounded_decimal(recommended_sugar_g_max),
    }


def _calculate_age(date_of_birth: date) -> int:
    today = date.today()
    return today.year - date_of_birth.year - (
        (today.month, today.day) < (date_of_birth.month, date_of_birth.day)
    )


def _calculate_bmr(
    *,
    weight_kg: float,
    height_cm: float,
    age_years: int,
    gender: str | None,
) -> float:
    normalized_gender = (gender or "").strip().lower()
    gender_offset = 0.0
    if normalized_gender == "male":
        gender_offset = 5.0
    elif normalized_gender == "female":
        gender_offset = -161.0

    return (10 * weight_kg) + (6.25 * height_cm) - (5 * age_years) + gender_offset


def _apply_calorie_floor(calories: float, *, gender: str | None) -> float:
    normalized_gender = (gender or "").strip().lower()
    if normalized_gender == "male":
        floor = 1500.0
    elif normalized_gender == "female":
        floor = 1200.0
    else:
        floor = 1350.0
    return max(calories, floor)


def _rounded_decimal(value: float, *, places: int = 2) -> Decimal:
    return Decimal(f"{value:.{places}f}")
