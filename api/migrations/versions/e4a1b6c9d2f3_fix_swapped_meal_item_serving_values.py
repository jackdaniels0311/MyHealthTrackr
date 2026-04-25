"""fix swapped meal item serving values

Revision ID: e4a1b6c9d2f3
Revises: d9f4b2c7a1e3
Create Date: 2026-04-14 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "e4a1b6c9d2f3"
down_revision: Union[str, None] = "d9f4b2c7a1e3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE meal_items
        SET
            serving_size = ROUND(quantity)::INTEGER,
            quantity = serving_size
        WHERE serving_size IS NOT NULL
          AND quantity IS NOT NULL
          AND serving_size <= 5
          AND quantity >= 10
          AND quantity = ROUND(quantity)
        """
    )


def downgrade() -> None:
    op.execute(
        """
        UPDATE meal_items
        SET
            quantity = serving_size,
            serving_size = ROUND(quantity)::INTEGER
        WHERE serving_size IS NOT NULL
          AND quantity IS NOT NULL
          AND quantity <= 5
          AND serving_size >= 10
          AND serving_size = ROUND(serving_size)
        """
    )
