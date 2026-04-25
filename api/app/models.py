from datetime import datetime, date

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    JSON,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


ACTIVITY_LEVEL_VALUES = (
    "Not Active",
    "Lightly Active",
    "Active",
    "Very Active",
)

GOAL_TYPE_VALUES = (
    "Gain Weight",
    "Maintain Weight",
    "Lose Weight",
)

WEEKLY_GOAL_VALUES = (
    -1.0,
    -0.75,
    -0.5,
    -0.25,
    0.0,
    0.25,
    0.5,
    0.75,
    1.0,
)


class User(Base):
    __tablename__ = "User"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hashed: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    health_profile: Mapped["UserProfile | None"] = relationship(
        "UserProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    goals: Mapped[list["UserGoal"]] = relationship(
        "UserGoal",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    nutrition_target: Mapped["UserNutritionTarget | None"] = relationship(
        "UserNutritionTarget",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    food_logs: Mapped[list["FoodLog"]] = relationship(
        "FoodLog",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    food_history_items: Mapped[list["UserFoodItem"]] = relationship(
        "UserFoodItem",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    saved_meals: Mapped[list["SavedMeal"]] = relationship(
        "SavedMeal",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    meal_recommendation_preferences: Mapped[
        "UserMealRecommendationPreference | None"
    ] = relationship(
        "UserMealRecommendationPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    weight_entries: Mapped[list["WeightEntry"]] = relationship(
        "WeightEntry",
        back_populates="user",
        cascade="all, delete-orphan",
    )


class UserProfile(Base):
    __tablename__ = "health_profiles"
    __table_args__ = (
        CheckConstraint(
            "activity_level IS NULL OR activity_level IN "
            "('Not Active', 'Lightly Active', 'Active', 'Very Active')",
            name="ck_health_profiles_activity_level_allowed",
        ),
    )

    profile_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    # 1:1: each user can only own one health profile
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)

    gender: Mapped[str | None] = mapped_column(String(20), nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)

    activity_level: Mapped[str | None] = mapped_column(String(30), nullable=True)
    dietary_preferences: Mapped[str | None] = mapped_column(String(255), nullable=True)
    allergies: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship("User", back_populates="health_profile")
    nutrition_target: Mapped["UserNutritionTarget | None"] = relationship(
        "UserNutritionTarget",
        back_populates="profile",
        uselist=False,
    )


class UserGoal(Base):
    __tablename__ = "user_goals"
    __table_args__ = (
        CheckConstraint(
            "goal_type IN ('Gain Weight', 'Maintain Weight', 'Lose Weight')",
            name="ck_user_goals_goal_type_allowed",
        ),
        CheckConstraint(
            "weekly_goal IS NULL OR weekly_goal IN "
            "(-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0)",
            name="ck_user_goals_weekly_goal_allowed",
        ),
    )

    goal_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    goal_type: Mapped[str] = mapped_column(String(100), nullable=False)
    goal_start_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    goal_start_weight: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    weekly_goal: Mapped[float | None] = mapped_column(Numeric(4, 2), nullable=True)
    goal_weight: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    goal_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    user: Mapped[User] = relationship("User", back_populates="goals")
    nutrition_target: Mapped["UserNutritionTarget | None"] = relationship(
        "UserNutritionTarget",
        back_populates="goal",
        uselist=False,
    )


class UserNutritionTarget(Base):
    __tablename__ = "user_nutrition_targets"

    nutrition_target_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    profile_id: Mapped[int] = mapped_column(
        ForeignKey("health_profiles.profile_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    goal_id: Mapped[int | None] = mapped_column(
        ForeignKey("user_goals.goal_id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    age_years: Mapped[int] = mapped_column(Integer, nullable=False)
    weight_kg: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    height_cm: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    activity_level: Mapped[str] = mapped_column(String(30), nullable=False)
    activity_multiplier: Mapped[float] = mapped_column(Numeric(5, 3), nullable=False)
    goal_type: Mapped[str] = mapped_column(String(100), nullable=False)
    weekly_goal_kg: Mapped[float] = mapped_column(Numeric(4, 2), nullable=False)
    bmr_kcal: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    tdee_kcal: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    calorie_adjustment_kcal: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    recommended_calories_kcal: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    recommended_protein_g: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    recommended_carbs_g: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    recommended_fat_g: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    recommended_fibre_g: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    recommended_sugar_g_max: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    recommended_water_ml: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship("User", back_populates="nutrition_target")
    profile: Mapped[UserProfile] = relationship(
        "UserProfile",
        back_populates="nutrition_target",
    )
    goal: Mapped[UserGoal | None] = relationship(
        "UserGoal",
        back_populates="nutrition_target",
    )


class FoodLog(Base):
    __tablename__ = "food_logs"

    food_log_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Canonical diary day bucket. A meal belongs to this log even if it was
    # entered into the app on a different real-world day.
    log_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    goal_weight: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    goal_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    user: Mapped[User] = relationship("User", back_populates="food_logs")
    meal_logs: Mapped[list["MealLog"]] = relationship(
        "MealLog",
        back_populates="food_log",
        cascade="all, delete-orphan",
    )


class WeightEntry(Base):
    __tablename__ = "weight_entries"

    weight_entry_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    weight_kg: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship("User", back_populates="weight_entries")


class MealLog(Base):
    __tablename__ = "meal_logs"

    meal_log_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    food_log_id: Mapped[int] = mapped_column(
        ForeignKey("food_logs.food_log_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    meal_type: Mapped[str] = mapped_column(String(100), nullable=False)
    # Currently used as the effective meal date/time within the selected diary
    # day. The owning FoodLog.log_date remains the authoritative diary date.
    meal_logged_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    food_log: Mapped[FoodLog] = relationship("FoodLog", back_populates="meal_logs")
    meal_items: Mapped[list["MealItem"]] = relationship(
        "MealItem",
        back_populates="meal_log",
        cascade="all, delete-orphan",
    )


class SavedMeal(Base):
    __tablename__ = "saved_meals"

    saved_meal_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    meal_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship("User", back_populates="saved_meals")
    items: Mapped[list["SavedMealItem"]] = relationship(
        "SavedMealItem",
        back_populates="saved_meal",
        cascade="all, delete-orphan",
        order_by="SavedMealItem.saved_meal_item_id",
    )


class UserMealRecommendationPreference(Base):
    __tablename__ = "user_meal_recommendation_preferences"

    meal_recommendation_preference_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    goal_type: Mapped[str | None] = mapped_column(String(30), nullable=True)
    allergies: Mapped[str | None] = mapped_column(String(500), nullable=True)
    dietary_preferences: Mapped[str | None] = mapped_column(String(500), nullable=True)
    diet_plan_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    meal_types: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    diet_targets: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    disliked_foods: Mapped[str | None] = mapped_column(String(500), nullable=True)
    liked_cuisines: Mapped[str | None] = mapped_column(String(500), nullable=True)
    disliked_cuisines: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship(
        "User",
        back_populates="meal_recommendation_preferences",
    )


class UserFoodItem(Base):
    __tablename__ = "user_food_items"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "normalized_name",
            "meal_type",
            name="uq_user_food_items_user_id_normalized_name",
        ),
    )

    user_food_item_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("User.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    meal_name: Mapped[str] = mapped_column(String(255), nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    meal_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    serving_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    quantity: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    calories: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    protein: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    carbs: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fat: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fibre: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    sugar: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    times_logged: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    last_logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship("User", back_populates="food_history_items")


class MealItem(Base):
    __tablename__ = "meal_items"

    meal_item_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    meal_log_id: Mapped[int] = mapped_column(
        ForeignKey("meal_logs.meal_log_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    meal_name: Mapped[str] = mapped_column(String(255), nullable=False)
    meal_group_id: Mapped[str | None] = mapped_column(
        String(36),
        nullable=True,
        index=True,
    )
    meal_group_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    serving_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    quantity: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    calories: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    protein: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    carbs: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fat: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fibre: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    sugar: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    meal_logged_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    meal_log: Mapped[MealLog] = relationship("MealLog", back_populates="meal_items")


class SavedMealItem(Base):
    __tablename__ = "saved_meal_items"

    saved_meal_item_id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    saved_meal_id: Mapped[int] = mapped_column(
        ForeignKey("saved_meals.saved_meal_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    meal_name: Mapped[str] = mapped_column(String(255), nullable=False)
    serving_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    quantity: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    calories: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    protein: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    carbs: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fat: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    fibre: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    sugar: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    saved_meal: Mapped[SavedMeal] = relationship("SavedMeal", back_populates="items")
