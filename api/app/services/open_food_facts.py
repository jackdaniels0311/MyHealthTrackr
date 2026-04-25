import json
import os
import socket
import time
from dataclasses import dataclass
from typing import Any
from urllib import error, parse, request

from ..schemas import FoodLookupResult, FoodNutrients, FoodSearchResult

_OPEN_FOOD_FACTS_API_BASE = "https://world.openfoodfacts.org"
_PRODUCT_FIELDS = ",".join(
    [
        "code",
        "product_name",
        "product_name_en",
        "generic_name",
        "generic_name_en",
        "brands",
        "quantity",
        "serving_size",
        "serving_quantity",
        "serving_quantity_unit",
        "image_front_small_url",
        "image_small_url",
        "nutriments",
    ]
)


class OpenFoodFactsError(Exception):
    """Raised when Open Food Facts could not be queried successfully."""


@dataclass(frozen=True)
class OpenFoodFactsConfig:
    api_base_url: str = os.getenv("OPEN_FOOD_FACTS_API_BASE_URL", _OPEN_FOOD_FACTS_API_BASE)
    user_agent: str = os.getenv(
        "OPEN_FOOD_FACTS_USER_AGENT",
        "MyHealthTrackr/0.1 (openfoodfacts-integration)",
    )
    timeout_seconds: float = float(os.getenv("OPEN_FOOD_FACTS_TIMEOUT_SECONDS", "8"))
    max_retries: int = int(os.getenv("OPEN_FOOD_FACTS_MAX_RETRIES", "2"))
    retry_delay_seconds: float = float(os.getenv("OPEN_FOOD_FACTS_RETRY_DELAY_SECONDS", "0.35"))


class OpenFoodFactsService:
    def __init__(self, config: OpenFoodFactsConfig | None = None):
        self._config = config or OpenFoodFactsConfig()

    def lookup_product(self, barcode: str) -> FoodLookupResult:
        payload = self._fetch_json(
            f"/api/v2/product/{barcode}.json",
            {"fields": _PRODUCT_FIELDS},
        )

        status = payload.get("status")
        product = payload.get("product")
        if status != 1 or not isinstance(product, dict):
            raise LookupError("No Open Food Facts product was found for that barcode.")

        return FoodLookupResult.model_validate(self._normalize_product(product, barcode))

    def search_products(self, query: str, page_size: int = 10) -> list[FoodSearchResult]:
        primary_error: OpenFoodFactsError | None = None
        fallback_error: OpenFoodFactsError | None = None

        try:
            payload = self._fetch_json(
                "/cgi/search.pl",
                {
                    "search_terms": query,
                    "search_simple": 1,
                    "action": "process",
                    "json": 1,
                    "page_size": page_size,
                    "fields": _PRODUCT_FIELDS,
                },
            )
            results = self._normalize_search_results(payload)
        except OpenFoodFactsError as exc:
            primary_error = exc
            results = []

        if len(results) >= page_size:
            return results[:page_size]

        try:
            fallback_payload = self._fetch_json(
                "/api/v2/search",
                {
                    "categories_tags_en": query,
                    "page_size": page_size,
                    "fields": _PRODUCT_FIELDS,
                },
            )

            fallback_results = self._normalize_search_results(fallback_payload)
            seen_source_ids = {result.source_id for result in results}
            for result in fallback_results:
                if result.source_id in seen_source_ids:
                    continue
                results.append(result)
                seen_source_ids.add(result.source_id)
                if len(results) >= page_size:
                    break
        except OpenFoodFactsError as exc:
            fallback_error = exc

        if results:
            return results

        if primary_error and fallback_error:
            raise primary_error

        return results

    def _fetch_json(self, path: str, query: dict[str, Any] | None = None) -> dict[str, Any]:
        url = self._build_url(path, query)
        attempts = self._config.max_retries + 1
        body: str | None = None

        for attempt in range(attempts):
            req = request.Request(
                url,
                headers={
                    "Accept": "application/json",
                    "User-Agent": self._config.user_agent,
                },
                method="GET",
            )

            try:
                with request.urlopen(req, timeout=self._config.timeout_seconds) as response:
                    body = response.read().decode("utf-8")
                break
            except error.HTTPError as exc:
                if exc.code == 404:
                    raise LookupError("No Open Food Facts product was found.") from exc
                if self._should_retry_http_error(exc.code, attempt, attempts):
                    self._sleep_before_retry(attempt)
                    continue
                raise OpenFoodFactsError(
                    f"Open Food Facts returned an HTTP {exc.code} response."
                ) from exc
            except (error.URLError, TimeoutError, socket.timeout) as exc:
                if attempt < attempts - 1:
                    self._sleep_before_retry(attempt)
                    continue
                raise OpenFoodFactsError("Open Food Facts could not be reached.") from exc

        if body is None:
            raise OpenFoodFactsError("Open Food Facts could not be reached.")

        try:
            payload = json.loads(body)
        except json.JSONDecodeError as exc:
            raise OpenFoodFactsError("Open Food Facts returned invalid JSON.") from exc

        if not isinstance(payload, dict):
            raise OpenFoodFactsError("Open Food Facts returned an unexpected response shape.")

        return payload

    def _should_retry_http_error(self, status_code: int, attempt: int, attempts: int) -> bool:
        return status_code >= 500 and attempt < attempts - 1

    def _sleep_before_retry(self, attempt: int) -> None:
        delay = self._config.retry_delay_seconds * (attempt + 1)
        time.sleep(delay)

    def _build_url(self, path: str, query: dict[str, Any] | None = None) -> str:
        normalized_base = self._config.api_base_url.rstrip("/")
        normalized_path = path if path.startswith("/") else f"/{path}"
        if not query:
            return f"{normalized_base}{normalized_path}"

        query_string = parse.urlencode(
            {key: value for key, value in query.items() if value is not None}
        )
        return f"{normalized_base}{normalized_path}?{query_string}"

    def _normalize_product(self, product: dict[str, Any], barcode: str) -> dict[str, Any]:
        nutriments = product.get("nutriments")
        nutriments_map = nutriments if isinstance(nutriments, dict) else {}

        image_url = self._read_str(product.get("image_front_small_url")) or self._read_str(
            product.get("image_small_url")
        )

        return {
            "source": "open_food_facts",
            "source_id": barcode,
            "barcode": barcode,
            "name": self._read_product_name(product) or "Unknown product",
            "brand": self._read_str(product.get("brands")),
            "quantity": self._read_str(product.get("quantity")),
            "serving_size": self._read_str(product.get("serving_size")),
            "serving_quantity": self._read_float(product.get("serving_quantity")),
            "serving_unit": self._read_str(product.get("serving_quantity_unit")),
            "image_url": image_url,
            "nutrients": FoodNutrients(
                calories_per_100g=self._read_float(
                    nutriments_map.get("energy-kcal_100g")
                    or nutriments_map.get("energy-kcal_value")
                ),
                protein_per_100g=self._read_float(nutriments_map.get("proteins_100g")),
                carbs_per_100g=self._read_float(
                    nutriments_map.get("carbohydrates_100g")
                ),
                fat_per_100g=self._read_float(nutriments_map.get("fat_100g")),
                fibre_per_100g=self._read_float(nutriments_map.get("fiber_100g")),
                sugar_per_100g=self._read_float(nutriments_map.get("sugars_100g")),
                calories_per_serving=self._read_float(
                    nutriments_map.get("energy-kcal_serving")
                ),
                protein_per_serving=self._read_float(
                    nutriments_map.get("proteins_serving")
                ),
                carbs_per_serving=self._read_float(
                    nutriments_map.get("carbohydrates_serving")
                ),
                fat_per_serving=self._read_float(nutriments_map.get("fat_serving")),
                fibre_per_serving=self._read_float(nutriments_map.get("fiber_serving")),
                sugar_per_serving=self._read_float(nutriments_map.get("sugars_serving")),
            ),
        }

    def _normalize_search_results(self, payload: dict[str, Any]) -> list[FoodSearchResult]:
        products = payload.get("products")
        if not isinstance(products, list):
            return []

        results: list[FoodSearchResult] = []
        for product in products:
            if not isinstance(product, dict):
                continue

            barcode = self._read_str(product.get("code"))
            name = self._read_product_name(product)
            if not barcode or not name:
                continue

            results.append(
                FoodSearchResult.model_validate(
                    self._normalize_product(product, barcode)
                )
            )

        return results

    def _read_product_name(self, product: dict[str, Any]) -> str | None:
        return (
            self._read_str(product.get("product_name"))
            or self._read_str(product.get("product_name_en"))
            or self._read_str(product.get("generic_name"))
            or self._read_str(product.get("generic_name_en"))
        )

    def _read_str(self, value: Any) -> str | None:
        if value is None:
            return None

        text = str(value).strip()
        return text or None

    def _read_float(self, value: Any) -> float | None:
        if value is None or value == "":
            return None

        if isinstance(value, (int, float)):
            return float(value)

        text = str(value).strip().replace(",", ".")
        try:
            return float(text)
        except ValueError:
            return None
