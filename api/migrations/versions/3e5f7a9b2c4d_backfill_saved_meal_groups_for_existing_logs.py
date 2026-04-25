"""backfill saved meal groups for existing logs

Revision ID: 3e5f7a9b2c4d
Revises: 2c4d6e8f1a3b
Create Date: 2026-04-18 19:50:00.000000

"""

from __future__ import annotations

from collections import defaultdict
from decimal import Decimal
from typing import Sequence, Union
from uuid import uuid4

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "3e5f7a9b2c4d"
down_revision: Union[str, None] = "2c4d6e8f1a3b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()

    saved_meal_rows = bind.execute(
        sa.text(
            """
            SELECT
                sm.saved_meal_id,
                sm.user_id,
                sm.name,
                smi.meal_name,
                smi.serving_size,
                smi.quantity,
                smi.calories,
                smi.protein,
                smi.carbs,
                smi.fat,
                smi.fibre,
                smi.sugar
            FROM saved_meals sm
            JOIN saved_meal_items smi
              ON smi.saved_meal_id = sm.saved_meal_id
            ORDER BY sm.saved_meal_id, smi.saved_meal_item_id
            """
        )
    ).mappings()

    saved_meal_signatures: dict[int, list[tuple[str, tuple[object, ...]]]] = defaultdict(list)
    saved_meal_name_signatures: dict[int, list[tuple[str, tuple[str, ...]]]] = defaultdict(list)

    saved_meal_items_by_id: dict[int, list[dict[str, object]]] = defaultdict(list)
    saved_meal_names: dict[int, str] = {}

    for row in saved_meal_rows:
        saved_meal_id = int(row["saved_meal_id"])
        user_id = int(row["user_id"])
        saved_meal_names[saved_meal_id] = str(row["name"]).strip()
        saved_meal_items_by_id[saved_meal_id].append(dict(row))

    for saved_meal_id, items in saved_meal_items_by_id.items():
        if not items:
            continue
        user_id = int(items[0]["user_id"])
        meal_name = saved_meal_names[saved_meal_id]
        saved_meal_signatures[user_id].append(
            (meal_name, _full_signature(items)),
        )
        saved_meal_name_signatures[user_id].append(
            (meal_name, _name_signature(items)),
        )

    cluster_rows = bind.execute(
        sa.text(
            """
            SELECT
                fl.user_id,
                mi.meal_log_id,
                mi.meal_logged_at,
                mi.meal_item_id,
                mi.meal_name,
                mi.serving_size,
                mi.quantity,
                mi.calories,
                mi.protein,
                mi.carbs,
                mi.fat,
                mi.fibre,
                mi.sugar
            FROM meal_items mi
            JOIN meal_logs ml
              ON ml.meal_log_id = mi.meal_log_id
            JOIN food_logs fl
              ON fl.food_log_id = ml.food_log_id
            WHERE mi.meal_group_id IS NULL
            ORDER BY fl.user_id, mi.meal_log_id, mi.meal_logged_at, mi.meal_item_id
            """
        )
    ).mappings()

    clusters: dict[tuple[int, int, object], list[dict[str, object]]] = defaultdict(list)
    for row in cluster_rows:
        key = (int(row["user_id"]), int(row["meal_log_id"]), row["meal_logged_at"])
        clusters[key].append(dict(row))

    for (user_id, _meal_log_id, _meal_logged_at), items in clusters.items():
        if len(items) <= 1:
            continue

        meal_name = _resolve_saved_meal_name(
            user_id=user_id,
            items=items,
            saved_meal_signatures=saved_meal_signatures,
            saved_meal_name_signatures=saved_meal_name_signatures,
        )
        if meal_name is None:
            continue

        group_id = str(uuid4())
        item_ids = [int(item["meal_item_id"]) for item in items]
        bind.execute(
            sa.text(
                """
                UPDATE meal_items
                SET meal_group_id = :group_id,
                    meal_group_name = :meal_name
                WHERE meal_item_id IN :item_ids
                """
            ).bindparams(sa.bindparam("item_ids", expanding=True)),
            {
                "group_id": group_id,
                "meal_name": meal_name,
                "item_ids": item_ids,
            },
        )


def downgrade() -> None:
    # This is a data backfill only. The grouping columns themselves remain.
    pass


def _resolve_saved_meal_name(
    *,
    user_id: int,
    items: list[dict[str, object]],
    saved_meal_signatures: dict[int, list[tuple[str, tuple[object, ...]]]],
    saved_meal_name_signatures: dict[int, list[tuple[str, tuple[str, ...]]]],
) -> str | None:
    exact_signature = _full_signature(items)
    exact_matches = [
        meal_name
        for meal_name, signature in saved_meal_signatures.get(user_id, [])
        if signature == exact_signature
    ]
    unique_exact_matches = list(dict.fromkeys(exact_matches))
    if len(unique_exact_matches) == 1:
        return unique_exact_matches[0]
    if len(unique_exact_matches) > 1:
        return None

    name_signature = _name_signature(items)
    name_matches = [
        meal_name
        for meal_name, signature in saved_meal_name_signatures.get(user_id, [])
        if signature == name_signature
    ]
    unique_name_matches = list(dict.fromkeys(name_matches))
    if len(unique_name_matches) == 1:
        return unique_name_matches[0]
    return None


def _full_signature(items: list[dict[str, object]]) -> tuple[object, ...]:
    return tuple(
        sorted(
            (
                _normalized_string(item["meal_name"]),
                item["serving_size"],
                _normalized_decimal(item["quantity"]),
                _normalized_decimal(item["calories"]),
                _normalized_decimal(item["protein"]),
                _normalized_decimal(item["carbs"]),
                _normalized_decimal(item["fat"]),
                _normalized_decimal(item["fibre"]),
                _normalized_decimal(item["sugar"]),
            )
            for item in items
        )
    )


def _name_signature(items: list[dict[str, object]]) -> tuple[str, ...]:
    return tuple(sorted(_normalized_string(item["meal_name"]) for item in items))


def _normalized_string(value: object) -> str:
    return str(value).strip().lower()


def _normalized_decimal(value: object) -> str | None:
    if value is None:
        return None
    if isinstance(value, Decimal):
        return format(value.normalize(), "f")
    return str(value)
