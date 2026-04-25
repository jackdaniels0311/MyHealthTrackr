"""add meal type to saved meals

Revision ID: 6f8a2c4e9b1d
Revises: 5d7e9f1a2b3c
Create Date: 2026-04-25 22:15:00.000000

"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "6f8a2c4e9b1d"
down_revision: Union[str, None] = "5d7e9f1a2b3c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "saved_meals",
        sa.Column("meal_type", sa.String(length=100), nullable=True),
    )
    op.create_index(
        "ix_saved_meals_meal_type",
        "saved_meals",
        ["meal_type"],
        unique=False,
    )

    op.execute(
        """
        UPDATE saved_meals
        SET meal_type = CASE
            WHEN lower(name) LIKE '%yoghurt pot%'
            THEN 'Snacks'
            WHEN lower(name) LIKE '%breakfast%'
              OR lower(name) LIKE '%porridge%'
              OR lower(name) LIKE '%oats%'
              OR lower(name) LIKE '%cereal%'
              OR lower(name) LIKE '%toast%'
              OR lower(name) LIKE '%eggs%'
              OR lower(name) LIKE '%omelette%'
              OR lower(name) LIKE '%smoothie%'
              OR lower(name) LIKE '%yoghurt%'
            THEN 'Breakfast'
            WHEN lower(name) LIKE '%lunch%'
              OR lower(name) LIKE '%sandwich%'
              OR lower(name) LIKE '%wrap%'
              OR lower(name) LIKE '%salad%'
              OR lower(name) LIKE '%soup%'
            THEN 'Lunch'
            WHEN lower(name) LIKE '%dinner%'
              OR lower(name) LIKE '%pasta%'
              OR lower(name) LIKE '%curry%'
              OR lower(name) LIKE '%stir fry%'
              OR lower(name) LIKE '%chilli%'
              OR lower(name) LIKE '%roast%'
              OR lower(name) LIKE '%steak%'
            THEN 'Dinner'
            WHEN lower(name) LIKE '%snack%'
              OR lower(name) LIKE '%bar%'
              OR lower(name) LIKE '%fruit%'
              OR lower(name) LIKE '%nuts%'
              OR lower(name) LIKE '%crisps%'
            THEN 'Snacks'
            ELSE NULL
        END
        WHERE meal_type IS NULL
        """
    )


def downgrade() -> None:
    op.drop_index("ix_saved_meals_meal_type", table_name="saved_meals")
    op.drop_column("saved_meals", "meal_type")
