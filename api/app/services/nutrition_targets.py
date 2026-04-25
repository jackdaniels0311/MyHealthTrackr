from __future__ import annotations

from dataclasses import dataclass
from datetime import date
import math

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import UserGoal, UserNutritionTarget, UserProfile

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

_WATER_ACTIVITY_BONUSES_ML = {
    "Not Active": 0.0,
    "Lightly Active": 250.0,
    "Active": 500.0,
    "Very Active": 750.0,
}

_MACRO_RATIOS = {
    "Lose Weight": {"protein": 0.30, "fat": 0.25, "carbs": 0.45},
    "Maintain Weight": {"protein": 0.25, "fat": 0.30, "carbs": 0.45},
    "Gain Weight": {"protein": 0.25, "fat": 0.25, "carbs": 0.50},
}

_CALORIES_PER_KG_PER_WEEK = 7700 / 7


@dataclass(frozen=True)
class NutritionTargetCalculation:
    user_id: int
    profile_id: int
    goal_id: int | None
    age_years: int
    weight_kg: float
    height_cm: float
    activity_level: str
    activity_multiplier: float
    goal_type: str
    weekly_goal_kg: float
    bmr_kcal: float
    tdee_kcal: float
    calorie_adjustment_kcal: float
    recommended_calories_kcal: float
    recommended_protein_g: float
    recommended_carbs_g: float
    recommended_fat_g: float
    recommended_fibre_g: float
    recommended_sugar_g_max: float
    recommended_water_ml: float


@dataclass(frozen=True)
class NutritionTargetBackfillSummary:
    total_profiles_seen: int
    targets_synced: int
    targets_cleared: int


class NutritionTargetCalculator:
    def calculate_for_user(self, db: Session, user_id: int) -> NutritionTargetCalculation:
        profile = db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        ).scalar_one_or_none()
        if profile is None:
            raise ValueError("A health profile is required before nutrition targets can be calculated.")

        self._validate_profile(profile)

        goal = db.execute(
            select(UserGoal)
            .where(UserGoal.user_id == user_id)
            .order_by(UserGoal.goal_start_date.desc(), UserGoal.goal_id.desc())
        ).scalars().first()

        age_years = _calculate_age(profile.date_of_birth)
        weight_kg = float(profile.weight_kg)
        height_cm = float(profile.height_cm)
        activity_level = str(profile.activity_level)
        activity_multiplier = _ACTIVITY_MULTIPLIERS[activity_level]

        bmr_kcal = _calculate_bmr(
            weight_kg=weight_kg,
            height_cm=height_cm,
            age_years=age_years,
            gender=profile.gender,
        )
        tdee_kcal = bmr_kcal * activity_multiplier

        goal_type = goal.goal_type if goal is not None else "Maintain Weight"
        weekly_goal_kg = (
            float(goal.weekly_goal)
            if goal is not None and goal.weekly_goal is not None
            else _GOAL_WEEKLY_DEFAULTS[goal_type]
        )
        calorie_adjustment_kcal = weekly_goal_kg * _CALORIES_PER_KG_PER_WEEK
        recommended_calories_kcal = _apply_calorie_floor(
            tdee_kcal + calorie_adjustment_kcal,
            gender=profile.gender,
        )

        macro_ratios = _MACRO_RATIOS[goal_type]
        recommended_protein_g = recommended_calories_kcal * macro_ratios["protein"] / 4
        recommended_carbs_g = recommended_calories_kcal * macro_ratios["carbs"] / 4
        recommended_fat_g = recommended_calories_kcal * macro_ratios["fat"] / 9
        recommended_fibre_g = recommended_calories_kcal / 1000 * 14
        recommended_sugar_g_max = recommended_calories_kcal * 0.10 / 4
        recommended_water_ml = _calculate_recommended_water_ml(
            weight_kg=weight_kg,
            activity_level=activity_level,
        )

        return NutritionTargetCalculation(
            user_id=user_id,
            profile_id=profile.profile_id,
            goal_id=goal.goal_id if goal is not None else None,
            age_years=age_years,
            weight_kg=round(weight_kg, 1),
            height_cm=round(height_cm, 1),
            activity_level=activity_level,
            activity_multiplier=round(activity_multiplier, 3),
            goal_type=goal_type,
            weekly_goal_kg=round(weekly_goal_kg, 2),
            bmr_kcal=round(bmr_kcal, 1),
            tdee_kcal=round(tdee_kcal, 1),
            calorie_adjustment_kcal=round(calorie_adjustment_kcal, 1),
            recommended_calories_kcal=round(recommended_calories_kcal, 1),
            recommended_protein_g=round(recommended_protein_g, 1),
            recommended_carbs_g=round(recommended_carbs_g, 1),
            recommended_fat_g=round(recommended_fat_g, 1),
            recommended_fibre_g=round(recommended_fibre_g, 1),
            recommended_sugar_g_max=round(recommended_sugar_g_max, 1),
            recommended_water_ml=round(recommended_water_ml, 1),
        )

    def get_stored_for_user(self, db: Session, user_id: int) -> UserNutritionTarget | None:
        return db.execute(
            select(UserNutritionTarget).where(UserNutritionTarget.user_id == user_id)
        ).scalar_one_or_none()

    def sync_for_user(self, db: Session, user_id: int) -> UserNutritionTarget:
        calculation = self.calculate_for_user(db, user_id)
        nutrition_target = self.get_stored_for_user(db, user_id)

        if nutrition_target is None:
            # Store one current recommendation row per user and overwrite it
            # whenever their profile or active goal changes.
            nutrition_target = UserNutritionTarget(user_id=user_id)
            db.add(nutrition_target)

        nutrition_target.profile_id = calculation.profile_id
        nutrition_target.goal_id = calculation.goal_id
        nutrition_target.age_years = calculation.age_years
        nutrition_target.weight_kg = calculation.weight_kg
        nutrition_target.height_cm = calculation.height_cm
        nutrition_target.activity_level = calculation.activity_level
        nutrition_target.activity_multiplier = calculation.activity_multiplier
        nutrition_target.goal_type = calculation.goal_type
        nutrition_target.weekly_goal_kg = calculation.weekly_goal_kg
        nutrition_target.bmr_kcal = calculation.bmr_kcal
        nutrition_target.tdee_kcal = calculation.tdee_kcal
        nutrition_target.calorie_adjustment_kcal = calculation.calorie_adjustment_kcal
        nutrition_target.recommended_calories_kcal = (
            calculation.recommended_calories_kcal
        )
        nutrition_target.recommended_protein_g = calculation.recommended_protein_g
        nutrition_target.recommended_carbs_g = calculation.recommended_carbs_g
        nutrition_target.recommended_fat_g = calculation.recommended_fat_g
        nutrition_target.recommended_fibre_g = calculation.recommended_fibre_g
        nutrition_target.recommended_sugar_g_max = calculation.recommended_sugar_g_max
        nutrition_target.recommended_water_ml = calculation.recommended_water_ml

        db.flush()
        return nutrition_target

    def sync_or_clear_for_user(self, db: Session, user_id: int) -> UserNutritionTarget | None:
        try:
            return self.sync_for_user(db, user_id)
        except ValueError:
            # If the profile is no longer complete enough to calculate targets,
            # remove the stale derived row rather than serving outdated numbers.
            nutrition_target = self.get_stored_for_user(db, user_id)
            if nutrition_target is not None:
                db.delete(nutrition_target)
                db.flush()
            return None

    def sync_all_users(self, db: Session) -> NutritionTargetBackfillSummary:
        user_ids = db.execute(
            select(UserProfile.user_id)
            .distinct()
            .order_by(UserProfile.user_id)
        ).scalars().all()

        synced = 0
        cleared = 0
        for user_id in user_ids:
            nutrition_target = self.sync_or_clear_for_user(db, user_id)
            if nutrition_target is None:
                cleared += 1
            else:
                synced += 1

        return NutritionTargetBackfillSummary(
            total_profiles_seen=len(user_ids),
            targets_synced=synced,
            targets_cleared=cleared,
        )

    def _validate_profile(self, profile: UserProfile) -> None:
        missing_fields = []
        if profile.date_of_birth is None:
            missing_fields.append("date_of_birth")
        if profile.height_cm is None:
            missing_fields.append("height_cm")
        if profile.weight_kg is None:
            missing_fields.append("weight_kg")
        if profile.activity_level is None:
            missing_fields.append("activity_level")

        if missing_fields:
            fields = ", ".join(missing_fields)
            raise ValueError(
                "Nutrition targets require a complete health profile. Missing: "
                f"{fields}."
            )


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


def _calculate_recommended_water_ml(
    *,
    weight_kg: float,
    activity_level: str,
) -> float:
    baseline_ml = weight_kg * 35.0
    activity_bonus_ml = _WATER_ACTIVITY_BONUSES_ML.get(activity_level, 0.0)
    return _round_to_nearest(baseline_ml + activity_bonus_ml, increment=50.0)


def _round_to_nearest(value: float, *, increment: float) -> float:
    if increment <= 0:
        return value
    return math.floor((value + (increment / 2)) / increment) * increment
