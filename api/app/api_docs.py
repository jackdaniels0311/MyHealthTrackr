from fastapi.routing import APIRoute

API_TITLE = "MyHealthTrackr API"
API_VERSION = "0.1.0"
API_DESCRIPTION = """
Backend API for MyHealthTrackr, covering authentication, user profiles,
nutrition goals, food search, diary logging, saved meals, meal recommendations,
and weight history.
"""

OPENAPI_TAGS = [
    {
        "name": "System",
        "description": "Operational endpoints for API status and health checks.",
    },
    {
        "name": "Auth",
        "description": "Authentication endpoints for issuing and refreshing bearer tokens.",
    },
    {
        "name": "Users",
        "description": "User account creation and account profile management.",
    },
    {
        "name": "Health Profiles",
        "description": "Health profile data used for personalised nutrition recommendations.",
    },
    {
        "name": "User Goals",
        "description": "Weight and nutrition goal records for a user.",
    },
    {
        "name": "Nutrition Targets",
        "description": "Calculated calorie, macro, and hydration targets.",
    },
    {
        "name": "Foods",
        "description": "Food search, barcode lookup, and personal food history search.",
    },
    {
        "name": "Food Logs",
        "description": "Daily food log containers.",
    },
    {
        "name": "Meal Logs",
        "description": "Meal-level log entries within daily food logs.",
    },
    {
        "name": "Meal Items",
        "description": "Individual foods logged within meal logs.",
    },
    {
        "name": "Saved Meals",
        "description": "Reusable saved meals and saved-meal logging workflows.",
    },
    {
        "name": "Meal Plans",
        "description": "Meal recommendation preferences and generated meal plan options.",
    },
    {
        "name": "Weight Entries",
        "description": "Weight history entries and profile weight synchronisation.",
    },
]

AUTH_RESPONSES = {
    401: {"description": "Authentication failed or the supplied token is invalid."},
    403: {"description": "The authenticated user is not allowed to access this resource."},
    422: {"description": "The request payload or parameters failed validation."},
}

AUTHENTICATED_RESPONSES = {
    **AUTH_RESPONSES,
    404: {"description": "The requested resource was not found."},
}

CONFLICT_RESPONSES = {
    **AUTHENTICATED_RESPONSES,
    409: {"description": "The request conflicts with existing data."},
}

EXTERNAL_FOOD_RESPONSES = {
    404: {"description": "The food product was not found."},
    422: {"description": "The request parameters failed validation."},
    502: {"description": "The upstream food data provider returned an error."},
}

MEAL_PLAN_RESPONSES = {
    **AUTHENTICATED_RESPONSES,
    400: {"description": "The profile or goal data is incomplete for meal planning."},
    502: {"description": "The meal plan provider returned an error."},
    503: {"description": "The meal plan provider is not configured."},
}


def generate_operation_id(route: APIRoute) -> str:
    return route.name
