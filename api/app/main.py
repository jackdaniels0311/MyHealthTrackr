from fastapi import FastAPI

from .api_docs import (
    API_DESCRIPTION,
    API_TITLE,
    API_VERSION,
    OPENAPI_TAGS,
    generate_operation_id,
)
from .controllers import (
    auth_controller,
    food_logs_controller,
    foods_controller,
    health_profiles_controller,
    meal_items_controller,
    meal_logs_controller,
    meal_plans_controller,
    nutrition_targets_controller,
    saved_meals_controller,
    system_controller,
    user_goals_controller,
    users_controller,
    weight_entries_controller,
)

app = FastAPI(
    title=API_TITLE,
    version=API_VERSION,
    description=API_DESCRIPTION,
    openapi_tags=OPENAPI_TAGS,
    generate_unique_id_function=generate_operation_id,
)

CONTROLLERS = [
    system_controller.router,
    auth_controller.router,
    foods_controller.router,
    health_profiles_controller.router,
    users_controller.router,
    user_goals_controller.router,
    nutrition_targets_controller.router,
    food_logs_controller.router,
    meal_logs_controller.router,
    meal_items_controller.router,
    meal_plans_controller.router,
    saved_meals_controller.router,
    weight_entries_controller.router,
]

for controller in CONTROLLERS:
    app.include_router(controller)
