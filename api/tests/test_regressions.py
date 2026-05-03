import importlib
import os
import sys
import unittest
from datetime import date

if sys.version_info < (3, 10):
    raise unittest.SkipTest("API tests require Python 3.10+ for PEP 604 annotations.")

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "x" * 32)

try:
    from pydantic import ValidationError

    from app.models import UserProfile
    from app.schemas import MealPlanModelResult, UserProfileIn
    from app.services import gemini_meal_plans
except ModuleNotFoundError as exc:
    raise unittest.SkipTest(f"API test dependency is missing: {exc.name}") from exc


class SecurityRegressionTests(unittest.TestCase):
    def test_jwt_secret_must_be_configured_and_strong(self):
        auth = importlib.import_module("app.core.auth")
        previous_secret = os.environ.get("JWT_SECRET")
        try:
            os.environ["JWT_SECRET"] = "short"
            with self.assertRaises(RuntimeError):
                auth._load_jwt_secret()
        finally:
            if previous_secret is None:
                os.environ.pop("JWT_SECRET", None)
            else:
                os.environ["JWT_SECRET"] = previous_secret

    def test_future_date_of_birth_is_rejected(self):
        next_year = date.today().replace(year=date.today().year + 1)
        with self.assertRaises(ValidationError):
            UserProfileIn(date_of_birth=next_year)

    def test_implausibly_old_date_of_birth_is_rejected(self):
        too_old = date.today().replace(year=date.today().year - 151)
        with self.assertRaises(ValidationError):
            UserProfileIn(date_of_birth=too_old)

    def test_meal_plan_filters_explicit_allergy_in_ingredients(self):
        model_result = MealPlanModelResult.model_validate(
            {
                "summary": "Meals match the target.",
                "meal_groups": [
                    {
                        "meal_type": "Lunch",
                        "options": [
                            {
                                "meal_type": "Lunch",
                                "name": "Peanut noodles",
                                "calories": 500,
                                "protein": 25,
                                "carbs": 65,
                                "fat": 18,
                                "fibre": 8,
                                "sugar": 6,
                                "ingredients": [
                                    {"name": "peanut butter", "quantity": 20, "unit": "g"}
                                ],
                                "match_reason": "Fits the target.",
                            }
                        ],
                    }
                ],
            }
        )
        profile = UserProfile(user_id=1, allergies="peanut")

        with self.assertRaises(gemini_meal_plans.GeminiMealPlanError):
            gemini_meal_plans._filter_model_result_safety(
                model_result,
                profile=profile,
                preferences=None,
            )

    def test_meal_plan_filters_common_allergy_wording(self):
        for user_text, ingredient in (
            ("peanut allergy", "peanut butter"),
            ("allergic to shellfish", "shellfish"),
            ("avoid eggs", "eggs"),
        ):
            with self.subTest(user_text=user_text, ingredient=ingredient):
                self._assert_model_filters_excluded_food(user_text, ingredient)

    def test_meal_plan_returns_safe_options_when_one_option_is_excluded(self):
        model_result = MealPlanModelResult.model_validate(
            {
                "summary": "Meals match the target.",
                "meal_groups": [
                    {
                        "meal_type": "Lunch",
                        "options": [
                            {
                                "meal_type": "Lunch",
                                "name": "Peanut noodles",
                                "calories": 500,
                                "protein": 25,
                                "carbs": 65,
                                "fat": 18,
                                "fibre": 8,
                                "sugar": 6,
                                "ingredients": [
                                    {"name": "peanut butter", "quantity": 20, "unit": "g"}
                                ],
                                "match_reason": "Fits the target.",
                            },
                            {
                                "meal_type": "Lunch",
                                "name": "Chicken rice bowl",
                                "calories": 520,
                                "protein": 38,
                                "carbs": 58,
                                "fat": 14,
                                "fibre": 7,
                                "sugar": 5,
                                "ingredients": [
                                    {"name": "chicken breast", "quantity": 130, "unit": "g"},
                                    {"name": "brown rice", "quantity": 150, "unit": "g"},
                                ],
                                "match_reason": "Fits the target.",
                            },
                        ],
                    }
                ],
            }
        )
        profile = UserProfile(user_id=1, allergies="peanut")

        filtered_result = gemini_meal_plans._filter_model_result_safety(
            model_result,
            profile=profile,
            preferences=None,
        )

        self.assertEqual(len(filtered_result.meal_groups), 1)
        self.assertEqual(len(filtered_result.meal_groups[0].options), 1)
        self.assertEqual(
            filtered_result.meal_groups[0].options[0].name,
            "Chicken rice bowl",
        )

    def _assert_model_filters_excluded_food(
        self,
        user_text: str,
        ingredient: str,
    ) -> None:
        model_result = MealPlanModelResult.model_validate(
            {
                "summary": "Meals match the target.",
                "meal_groups": [
                    {
                        "meal_type": "Lunch",
                        "options": [
                            {
                                "meal_type": "Lunch",
                                "name": "Blocked food meal",
                                "calories": 450,
                                "protein": 30,
                                "carbs": 40,
                                "fat": 15,
                                "fibre": 6,
                                "sugar": 5,
                                "ingredients": [
                                    {"name": ingredient, "quantity": 120, "unit": "g"}
                                ],
                                "match_reason": "Fits the target.",
                            }
                        ],
                    }
                ],
            }
        )
        profile = UserProfile(user_id=1, allergies=user_text)

        with self.assertRaises(gemini_meal_plans.GeminiMealPlanError):
            gemini_meal_plans._filter_model_result_safety(
                model_result,
                profile=profile,
                preferences=None,
            )


if __name__ == "__main__":
    unittest.main()
