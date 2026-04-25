"""add serving size to meal items

Revision ID: c2b7a9d4e6f1
Revises: a4c6d8e2f9b1
Create Date: 2026-04-11 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c2b7a9d4e6f1"
down_revision: Union[str, None] = "a4c6d8e2f9b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "meal_items",
        sa.Column("serving_size", sa.String(length=100), nullable=True),
    )

    op.execute(
        """
        UPDATE meal_items
        SET serving_size = CASE
            WHEN quantity IS NULL THEN NULL
            WHEN quantity = CAST(quantity AS INTEGER) THEN CAST(CAST(quantity AS INTEGER) AS VARCHAR) || 'g'
            ELSE CAST(quantity AS VARCHAR) || 'g'
        END,
        quantity = CASE
            WHEN quantity IS NULL THEN NULL
            ELSE 1
        END
        WHERE serving_size IS NULL
        """
    )


def downgrade() -> None:
    op.drop_column("meal_items", "serving_size")
