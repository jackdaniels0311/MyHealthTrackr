from __future__ import annotations

from datetime import date, datetime
from typing import Literal

from pydantic import AliasChoices, BaseModel, ConfigDict, EmailStr, Field, field_validator


ActivityLevel = Literal[
    "Not Active",
    "Lightly Active",
    "Active",
    "Very Active",
]

GoalType = Literal[
    "Gain Weight",
    "Maintain Weight",
    "Lose Weight",
]

WeeklyGoal = Literal[
    -1.0,
    -0.75,
    -0.5,
    -0.25,
    0.0,
    0.25,
    0.5,
    0.75,
    1.0,
]

FoodSource = Literal["open_food_facts", "user_history"]


class AuthToken(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class UserCreate(BaseModel):
    name: str | None = Field(default=None, max_length=255)
    email: EmailStr = Field(max_length=255)
    password: str = Field(min_length=8, max_length=72)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str | None
    email: EmailStr
    is_active: bool


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=255)


class UserProfileIn(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    date_of_birth: date | None = None

    gender: str | None = Field(
        default=None,
        max_length=20,
        validation_alias=AliasChoices("gender", "sex"),
    )
    height_cm: float | None = Field(default=None, ge=0, le=300)
    weight_kg: float | None = Field(default=None, ge=0, le=700)

    activity_level: ActivityLevel | None = None
    dietary_preferences: str | None = Field(default=None, max_length=255)
    allergies: str | None = Field(default=None, max_length=255)

    @field_validator("date_of_birth")
    @classmethod
    def validate_date_of_birth(cls, value: date | None) -> date | None:
        if value is None:
            return value

        today = date.today()
        age_years = today.year - value.year - (
            (today.month, today.day) < (value.month, value.day)
        )
        if age_years < 0:
            raise ValueError("Date of birth cannot be in the future.")
        if age_years > 150:
            raise ValueError("Date of birth must be within the last 150 years.")
        return value


class UserProfileOut(UserProfileIn):
    model_config = ConfigDict(from_attributes=True)
    profile_id: int
    user_id: int


class WeightEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    weight_entry_id: int
    user_id: int
    weight_kg: float = Field(ge=0, le=1000)
    recorded_at: datetime
    created_at: datetime


class WeightEntryCreate(BaseModel):
    weight_kg: float = Field(ge=0, le=1000)
    recorded_at: datetime | None = None


class WeightEntryUpdate(BaseModel):
    weight_kg: float = Field(ge=0, le=1000)
    recorded_at: datetime | None = None


class UserGoalBase(BaseModel):
    goal_type: GoalType
    goal_start_weight: float = Field(ge=0, le=1000)
    weekly_goal: WeeklyGoal
    goal_weight: float | None = Field(default=None, ge=0, le=1000)
    goal_date: date | None = None


class UserGoalCreate(UserGoalBase):
    pass


class UserGoalUpdate(BaseModel):
    goal_type: GoalType | None = None
    goal_start_weight: float | None = Field(default=None, ge=0, le=1000)
    weekly_goal: WeeklyGoal | None = None
    goal_weight: float | None = Field(default=None, ge=0, le=1000)
    goal_date: date | None = None


class UserGoalOut(UserGoalBase):
    model_config = ConfigDict(from_attributes=True)

    goal_id: int
    user_id: int
    goal_start_date: datetime
    goal_start_weight: float | None = Field(default=None, ge=0, le=1000)
    weekly_goal: WeeklyGoal | None = None


class NutritionTargetsOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    nutrition_target_id: int
    user_id: int
    profile_id: int
    goal_id: int | None = None
    age_years: int = Field(ge=0, le=150)
    weight_kg: float = Field(ge=0, le=1000)
    height_cm: float = Field(ge=0, le=300)
    activity_level: ActivityLevel
    activity_multiplier: float = Field(ge=1.0, le=3.0)
    goal_type: GoalType
    weekly_goal_kg: float = Field(ge=-2.0, le=2.0)
    bmr_kcal: float = Field(ge=0, le=10000)
    tdee_kcal: float = Field(ge=0, le=20000)
    calorie_adjustment_kcal: float = Field(ge=-5000, le=5000)
    recommended_calories_kcal: float = Field(ge=0, le=20000)
    recommended_protein_g: float = Field(ge=0, le=2000)
    recommended_carbs_g: float = Field(ge=0, le=2000)
    recommended_fat_g: float = Field(ge=0, le=1000)
    recommended_fibre_g: float = Field(ge=0, le=500)
    recommended_sugar_g_max: float = Field(ge=0, le=1000)
    recommended_water_ml: float = Field(ge=0, le=10000)


class FoodLogBase(BaseModel):
    # Authoritative diary date for grouping meals on the diary page.
    log_date: datetime
    goal_weight: float | None = Field(default=None, ge=0, le=1000)
    goal_date: date | None = None


class FoodLogCreate(FoodLogBase):
    pass


class FoodLogUpdate(BaseModel):
    log_date: datetime | None = None
    goal_weight: float | None = Field(default=None, ge=0, le=1000)
    goal_date: date | None = None


class FoodLogOut(FoodLogBase):
    model_config = ConfigDict(from_attributes=True)

    food_log_id: int
    user_id: int


class MealLogBase(BaseModel):
    food_log_id: int
    meal_type: str = Field(min_length=1, max_length=100)
    # Effective meal date/time inside the selected diary day. The parent
    # FoodLog.log_date is still the canonical day bucket.
    meal_logged_at: datetime | None = None


class MealLogCreate(MealLogBase):
    pass


class MealLogUpdate(BaseModel):
    food_log_id: int | None = None
    meal_type: str | None = Field(default=None, min_length=1, max_length=100)
    meal_logged_at: datetime | None = None


class MealLogOut(MealLogBase):
    model_config = ConfigDict(from_attributes=True)

    meal_log_id: int


class MealItemBase(BaseModel):
    meal_log_id: int
    meal_name: str = Field(min_length=1, max_length=255)
    serving_size: int | None = Field(default=None, ge=0, le=100000)
    quantity: float | None = Field(default=None, ge=0, le=100000)
    calories: float | None = Field(default=None, ge=0, le=100000)
    protein: float | None = Field(default=None, ge=0, le=100000)
    carbs: float | None = Field(default=None, ge=0, le=100000)
    fat: float | None = Field(default=None, ge=0, le=100000)
    fibre: float | None = Field(default=None, ge=0, le=100000)
    sugar: float | None = Field(default=None, ge=0, le=100000)
    meal_logged_at: datetime | None = None


class MealItemCreate(MealItemBase):
    pass


class MealItemUpdate(BaseModel):
    meal_log_id: int | None = None
    meal_name: str | None = Field(default=None, min_length=1, max_length=255)
    serving_size: int | None = Field(default=None, ge=0, le=100000)
    quantity: float | None = Field(default=None, ge=0, le=100000)
    calories: float | None = Field(default=None, ge=0, le=100000)
    protein: float | None = Field(default=None, ge=0, le=100000)
    carbs: float | None = Field(default=None, ge=0, le=100000)
    fat: float | None = Field(default=None, ge=0, le=100000)
    fibre: float | None = Field(default=None, ge=0, le=100000)
    sugar: float | None = Field(default=None, ge=0, le=100000)
    meal_logged_at: datetime | None = None


class MealItemOut(MealItemBase):
    model_config = ConfigDict(from_attributes=True)

    meal_item_id: int
    meal_group_id: str | None = Field(default=None, max_length=36)
    meal_group_name: str | None = Field(default=None, max_length=255)


class SavedMealItemBase(BaseModel):
    meal_name: str = Field(min_length=1, max_length=255)
    serving_size: int | None = Field(default=None, ge=0, le=100000)
    quantity: float | None = Field(default=None, ge=0, le=100000)
    calories: float | None = Field(default=None, ge=0, le=100000)
    protein: float | None = Field(default=None, ge=0, le=100000)
    carbs: float | None = Field(default=None, ge=0, le=100000)
    fat: float | None = Field(default=None, ge=0, le=100000)
    fibre: float | None = Field(default=None, ge=0, le=100000)
    sugar: float | None = Field(default=None, ge=0, le=100000)


class SavedMealItemCreate(SavedMealItemBase):
    pass


class SavedMealItemOut(SavedMealItemBase):
    model_config = ConfigDict(from_attributes=True)

    saved_meal_item_id: int


class SavedMealCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    meal_type: str = Field(min_length=1, max_length=100)
    items: list[SavedMealItemCreate] = Field(min_length=1)


class SavedMealUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    meal_type: str | None = Field(default=None, min_length=1, max_length=100)
    items: list[SavedMealItemCreate] | None = Field(default=None, min_length=1)


class SavedMealOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    saved_meal_id: int
    user_id: int
    name: str
    meal_type: str | None = None
    created_at: datetime
    updated_at: datetime
    items: list[SavedMealItemOut]


class SavedMealLogRequest(BaseModel):
    meal_type: str = Field(min_length=1, max_length=100)
    log_date: datetime
    items: list[SavedMealItemCreate] | None = Field(default=None, min_length=1)


class SavedMealLogResult(BaseModel):
    food_log_id: int
    meal_log_id: int
    items_created: int = Field(ge=1, le=1000)


class FoodNutrients(BaseModel):
    calories_per_100g: float | None = Field(default=None, ge=0, le=100000)
    protein_per_100g: float | None = Field(default=None, ge=0, le=100000)
    carbs_per_100g: float | None = Field(default=None, ge=0, le=100000)
    fat_per_100g: float | None = Field(default=None, ge=0, le=100000)
    fibre_per_100g: float | None = Field(default=None, ge=0, le=100000)
    sugar_per_100g: float | None = Field(default=None, ge=0, le=100000)
    calories_per_serving: float | None = Field(default=None, ge=0, le=100000)
    protein_per_serving: float | None = Field(default=None, ge=0, le=100000)
    carbs_per_serving: float | None = Field(default=None, ge=0, le=100000)
    fat_per_serving: float | None = Field(default=None, ge=0, le=100000)
    fibre_per_serving: float | None = Field(default=None, ge=0, le=100000)
    sugar_per_serving: float | None = Field(default=None, ge=0, le=100000)


class FoodSearchResult(BaseModel):
    source: FoodSource = "open_food_facts"
    source_id: str = Field(min_length=1, max_length=64)
    barcode: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=255)
    brand: str | None = Field(default=None, max_length=255)
    quantity: str | None = Field(default=None, max_length=100)
    serving_size: str | None = Field(default=None, max_length=100)
    serving_quantity: float | None = Field(default=None, ge=0, le=100000)
    serving_unit: str | None = Field(default=None, max_length=50)
    image_url: str | None = Field(default=None, max_length=2048)
    times_logged: int | None = Field(default=None, ge=1, le=100000)
    last_logged_at: datetime | None = None
    nutrients: FoodNutrients = Field(default_factory=FoodNutrients)


class FoodLookupResult(FoodSearchResult):
    pass


class MealPlanIngredient(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    quantity: float = Field(ge=0, le=100000)
    unit: str = Field(min_length=1, max_length=50)


class MealPlanMeal(BaseModel):
    meal_type: str = Field(min_length=1, max_length=100)
    name: str = Field(min_length=1, max_length=255)
    calories: float = Field(ge=0, le=100000)
    protein: float = Field(ge=0, le=100000)
    carbs: float = Field(ge=0, le=100000)
    fat: float = Field(ge=0, le=100000)
    fibre: float = Field(ge=0, le=100000)
    sugar: float = Field(ge=0, le=100000)
    ingredients: list[MealPlanIngredient] = Field(min_length=1)
    match_reason: str = Field(min_length=1, max_length=500)


class MealPlanTargets(BaseModel):
    calories: float = Field(ge=0, le=20000)
    protein: float = Field(ge=0, le=2000)
    carbs: float = Field(ge=0, le=2000)
    fat: float = Field(ge=0, le=1000)


class MealPlanMealGroup(BaseModel):
    meal_type: str = Field(min_length=1, max_length=100)
    options: list[MealPlanMeal] = Field(min_length=1, max_length=5)


class MealPlanModelResult(BaseModel):
    summary: str = Field(min_length=1, max_length=800)
    meal_groups: list[MealPlanMealGroup] = Field(min_length=1, max_length=6)


class MealPlanGenerateRequest(BaseModel):
    goal_type: GoalType | None = None
    allergies: str | None = Field(default=None, max_length=500)
    dietary_preferences: str | None = Field(default=None, max_length=500)
    diet_plan_type: str | None = Field(default=None, max_length=100)
    meal_types: list[str] = Field(default_factory=list, max_length=6)
    diet_target: str | None = Field(default=None, max_length=100)
    diet_targets: list[str] = Field(default_factory=list, max_length=8)
    disliked_foods: str | None = Field(default=None, max_length=500)
    liked_cuisines: str | None = Field(default=None, max_length=500)
    disliked_cuisines: str | None = Field(default=None, max_length=500)


class MealPlanPreferencesOut(MealPlanGenerateRequest):
    has_saved_preferences: bool = False


class MealPlanOut(BaseModel):
    generated_at: datetime
    goal_type: GoalType
    dietary_preferences: str | None = Field(default=None, max_length=255)
    allergies: str | None = Field(default=None, max_length=255)
    targets: MealPlanTargets
    summary: str = Field(min_length=1, max_length=800)
    estimate_notice: str = Field(min_length=1, max_length=255)
    meal_groups: list[MealPlanMealGroup] = Field(min_length=1, max_length=6)
