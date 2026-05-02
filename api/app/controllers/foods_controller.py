from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from ..api_docs import EXTERNAL_FOOD_RESPONSES
from ..auth import get_current_user
from ..db import get_db
from ..models import User
from ..schemas import FoodLookupResult, FoodSearchResult
from ..services.open_food_facts import OpenFoodFactsError, OpenFoodFactsService
from ..services.user_food_history import UserFoodHistoryService

router = APIRouter(tags=["Foods"], responses=EXTERNAL_FOOD_RESPONSES)
_food_history_service = UserFoodHistoryService()


@router.get("/foods/barcode/{barcode}", response_model=FoodLookupResult)
def lookup_food_by_barcode(barcode: str):
    normalized_barcode = _normalize_barcode(barcode)

    try:
        return OpenFoodFactsService().lookup_product(normalized_barcode)
    except LookupError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except OpenFoodFactsError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc


@router.get("/foods/search", response_model=list[FoodSearchResult])
def search_foods(
    q: str = Query(min_length=2, max_length=120),
    page_size: int = Query(default=10, ge=1, le=20),
):
    query = q.strip()
    if len(query) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Search terms must be at least 2 characters long.",
        )

    try:
        return OpenFoodFactsService().search_products(query, page_size=page_size)
    except OpenFoodFactsError as exc:
        # Search should degrade gracefully when the upstream provider is flaky
        # or rate-limits broad queries. Returning an empty list keeps the UI
        # usable and avoids treating "no current OFF results" as a fatal error.
        return []


@router.get("/users/me/foods/search", response_model=list[FoodSearchResult])
def search_my_foods(
    q: str = Query(default="", max_length=120),
    meal_type: str | None = Query(default=None, min_length=1, max_length=100),
    page_size: int = Query(default=10, ge=1, le=20),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = q.strip()
    history_results = _food_history_service.search_for_user(
        db,
        user_id=current_user.id,
        query=query,
        limit=page_size,
        meal_type=meal_type,
    )

    if len(history_results) >= page_size or len(query) < 2:
        return history_results[:page_size]

    combined_results = list(history_results)
    seen_names = {
        _food_history_service.normalize_name(result.name) for result in combined_results
    }

    try:
        search_results = OpenFoodFactsService().search_products(query, page_size=page_size)
    except OpenFoodFactsError as exc:
        return combined_results[:page_size]

    for result in search_results:
        normalized_name = _food_history_service.normalize_name(result.name)
        if normalized_name in seen_names:
            continue
        combined_results.append(result)
        seen_names.add(normalized_name)
        if len(combined_results) >= page_size:
            break

    return combined_results


def _normalize_barcode(value: str) -> str:
    normalized = "".join(character for character in value if character.isdigit())
    if len(normalized) < 8 or len(normalized) > 32:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Barcode must contain between 8 and 32 digits.",
        )

    return normalized
