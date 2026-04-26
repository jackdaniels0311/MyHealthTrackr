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
        auth = importlib.import_module("app.auth")
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

    def test_meal_plan_rejects_explicit_allergy_in_ingredients(self):
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
            gemini_meal_plans._validate_model_result_safety(
                model_result,
                profile=profile,
                preferences=None,
            )


if __name__ == "__main__":
    unittest.main()
