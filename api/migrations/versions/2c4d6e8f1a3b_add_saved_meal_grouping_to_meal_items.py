"""add saved meal grouping to meal items

Revision ID: 2c4d6e8f1a3b
Revises: 1b2c3d4e5f6a
Create Date: 2026-04-18 19:15:00.000000

"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "2c4d6e8f1a3b"
down_revision: Union[str, None] = "1b2c3d4e5f6a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "meal_items",
        sa.Column("meal_group_id", sa.String(length=36), nullable=True),
    )
    op.add_column(
        "meal_items",
        sa.Column("meal_group_name", sa.String(length=255), nullable=True),
    )
    op.create_index(
        "ix_meal_items_meal_group_id",
        "meal_items",
        ["meal_group_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_meal_items_meal_group_id", table_name="meal_items")
    op.drop_column("meal_items", "meal_group_name")
    op.drop_column("meal_items", "meal_group_id")
