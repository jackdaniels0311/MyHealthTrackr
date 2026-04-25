from __future__ import annotations

import json
import os
import socket
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any
from urllib import error, request

from pydantic import ValidationError

from ..models import UserNutritionTarget, UserProfile
from ..schemas import (
    MealPlanModelResult,
    MealPlanOut,
    MealPlanTargets,
    MealPlanTotals,
)

_GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"
_DEFAULT_MODEL = "gemini-2.5-flash"
_ESTIMATE_NOTICE = (
    "Nutrition values are AI-generated estimates and should be used as guidance only."
)


class GeminiMealPlanConfigError(Exception):
    """Raised when the Gemini meal plan integration is not configured."""


class GeminiMealPlanError(Exception):
    """Raised when Gemini cannot generate a usable meal plan."""


@dataclass(frozen=True)
class GeminiMealPlanConfig:
    api_key: str | None = os.getenv("GEMINI_API_KEY")
    model: str = os.getenv("GEMINI_MODEL", _DEFAULT_MODEL)
    api_base_url: str = os.getenv("GEMINI_API_BASE_URL", _GEMINI_API_BASE)
    timeout_seconds: float = float(os.getenv("GEMINI_TIMEOUT_SECONDS", "25"))


class GeminiMealPlanService:
    def __init__(self, config: GeminiMealPlanConfig | None = None):
        self._config = config or GeminiMealPlanConfig()

    def generate(
        self,
        *,
        profile: UserProfile,
        nutrition_target: UserNutritionTarget,
    ) -> MealPlanOut:
        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": self._build_prompt(
                                profile=profile,
                                nutrition_target=nutrition_target,
                            )
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.55,
                "responseMimeType": "application/json",
                "responseSchema": _response_schema(),
            },
        }
        response_json = self._post_generate_content(payload)
        model_result = self._parse_model_result(response_json)

        return MealPlanOut(
            generated_at=datetime.now(timezone.utc),
            goal_type=nutrition_target.goal_type,
            dietary_preferences=_blank_to_none(profile.dietary_preferences),
            allergies=_blank_to_none(profile.allergies),
            targets=MealPlanTargets(
                calories=float(nutrition_target.recommended_calories_kcal),
                protein=float(nutrition_target.recommended_protein_g),
                carbs=float(nutrition_target.recommended_carbs_g),
                fat=float(nutrition_target.recommended_fat_g),
            ),
            totals=_sum_totals(model_result),
            summary=model_result.summary,
            estimate_notice=_ESTIMATE_NOTICE,
            meals=model_result.meals,
        )

    def _post_generate_content(self, payload: dict[str, Any]) -> dict[str, Any]:
        api_key = (self._config.api_key or "").strip()
        if not api_key:
            raise GeminiMealPlanConfigError(
                "Gemini meal plan generation is not configured. Set GEMINI_API_KEY."
            )

        url = (
            f"{self._config.api_base_url.rstrip('/')}/models/"
            f"{self._config.model}:generateContent"
        )
        body = json.dumps(payload).encode("utf-8")
        req = request.Request(
            url,
            data=body,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            },
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=self._config.timeout_seconds) as response:
                raw_body = response.read().decode("utf-8")
        except error.HTTPError as exc:
            detail = _read_http_error_detail(exc)
            raise GeminiMealPlanError(detail) from exc
        except (error.URLError, TimeoutError, socket.timeout) as exc:
            raise GeminiMealPlanError("Gemini could not be reached.") from exc

        try:
            decoded = json.loads(raw_body)
        except json.JSONDecodeError as exc:
            raise GeminiMealPlanError("Gemini returned invalid JSON.") from exc

        if not isinstance(decoded, dict):
            raise GeminiMealPlanError("Gemini returned an unexpected response shape.")
        return decoded

    def _parse_model_result(self, response_json: dict[str, Any]) -> MealPlanModelResult:
        try:
            text = response_json["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError, TypeError) as exc:
            raise GeminiMealPlanError("Gemini did not return a meal plan.") from exc

        if not isinstance(text, str) or not text.strip():
            raise GeminiMealPlanError("Gemini returned an empty meal plan.")

        try:
            payload = json.loads(text)
        except json.JSONDecodeError as exc:
            raise GeminiMealPlanError("Gemini returned a meal plan that was not JSON.") from exc

        try:
            return MealPlanModelResult.model_validate(payload)
        except ValidationError as exc:
            raise GeminiMealPlanError("Gemini returned an invalid meal plan shape.") from exc

    def _build_prompt(
        self,
        *,
        profile: UserProfile,
        nutrition_target: UserNutritionTarget,
    ) -> str:
        dietary_preferences = _blank_to_none(profile.dietary_preferences) or "None"
        allergies = _blank_to_none(profile.allergies) or "None"

        return f"""
You are the meal planning model inside MyHealthTrackr.

Generate one personalised meal plan for one day only. Include Breakfast, Lunch, Dinner, and optionally one Snack.

User data:
- Age: {nutrition_target.age_years}
- Gender: {profile.gender or "Not specified"}
- Weight: {float(nutrition_target.weight_kg):.1f} kg
- Height: {float(nutrition_target.height_cm):.1f} cm
- Activity level: {nutrition_target.activity_level}
- Goal: {nutrition_target.goal_type}
- Weekly goal: {float(nutrition_target.weekly_goal_kg):.2f} kg/week
- Dietary preferences: {dietary_preferences}
- Allergies: {allergies}

Daily targets:
- Calories: {float(nutrition_target.recommended_calories_kcal):.0f} kcal
- Protein: {float(nutrition_target.recommended_protein_g):.0f} g
- Carbs: {float(nutrition_target.recommended_carbs_g):.0f} g
- Fat: {float(nutrition_target.recommended_fat_g):.0f} g

Rules:
- Return JSON only.
- Respect allergies and dietary preferences. Do not include conflicting foods.
- Include exact ingredient quantities and units for every meal.
- Nutrition values can be approximate, but must be realistic.
- Do not include lifestyle suggestions, exercise advice, hydration advice, sleep advice, or medical claims.
- The summary should only explain why the meals fit the user's nutrition target and food preferences.
""".strip()


def _sum_totals(model_result: MealPlanModelResult) -> MealPlanTotals:
    return MealPlanTotals(
        calories=round(sum(meal.calories for meal in model_result.meals), 1),
        protein=round(sum(meal.protein for meal in model_result.meals), 1),
        carbs=round(sum(meal.carbs for meal in model_result.meals), 1),
        fat=round(sum(meal.fat for meal in model_result.meals), 1),
        fibre=round(sum(meal.fibre for meal in model_result.meals), 1),
        sugar=round(sum(meal.sugar for meal in model_result.meals), 1),
    )


def _blank_to_none(value: str | None) -> str | None:
    if value is None:
        return None
    trimmed = value.strip()
    if not trimmed or trimmed.lower() == "none":
        return None
    return trimmed


def _read_http_error_detail(exc: error.HTTPError) -> str:
    try:
        body = exc.read().decode("utf-8")
        payload = json.loads(body)
    except Exception:
        return f"Gemini returned an HTTP {exc.code} response."

    if isinstance(payload, dict):
        error_payload = payload.get("error")
        if isinstance(error_payload, dict):
            message = error_payload.get("message")
            if isinstance(message, str) and message.strip():
                return message.strip()
    return f"Gemini returned an HTTP {exc.code} response."


def _response_schema() -> dict[str, Any]:
    number = {"type": "NUMBER"}
    text = {"type": "STRING"}
    ingredient = {
        "type": "OBJECT",
        "properties": {
            "name": text,
            "quantity": number,
            "unit": text,
        },
        "required": ["name", "quantity", "unit"],
        "propertyOrdering": ["name", "quantity", "unit"],
    }
    meal = {
        "type": "OBJECT",
        "properties": {
            "meal_type": text,
            "name": text,
            "calories": number,
            "protein": number,
            "carbs": number,
            "fat": number,
            "fibre": number,
            "sugar": number,
            "ingredients": {
                "type": "ARRAY",
                "items": ingredient,
                "minItems": 1,
            },
            "match_reason": text,
        },
        "required": [
            "meal_type",
            "name",
            "calories",
            "protein",
            "carbs",
            "fat",
            "fibre",
            "sugar",
            "ingredients",
            "match_reason",
        ],
        "propertyOrdering": [
            "meal_type",
            "name",
            "calories",
            "protein",
            "carbs",
            "fat",
            "fibre",
            "sugar",
            "ingredients",
            "match_reason",
        ],
    }
    return {
        "type": "OBJECT",
        "properties": {
            "summary": text,
            "meals": {
                "type": "ARRAY",
                "items": meal,
                "minItems": 3,
                "maxItems": 5,
            },
        },
        "required": ["summary", "meals"],
        "propertyOrdering": ["summary", "meals"],
    }
