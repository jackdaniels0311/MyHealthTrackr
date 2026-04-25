"""make user food history meal specific

Revision ID: c3d4e5f6a7b8
Revises: b7c9d1e2f3a4
Create Date: 2026-04-17 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, None] = "b7c9d1e2f3a4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("DELETE FROM user_food_items")

    op.add_column(
        "user_food_items",
        sa.Column("meal_type", sa.String(length=100), nullable=False, server_default=""),
    )
    op.drop_constraint(
        "uq_user_food_items_user_id_normalized_name",
        "user_food_items",
        type_="unique",
    )
    op.create_unique_constraint(
        "uq_user_food_items_user_id_normalized_name",
        "user_food_items",
        ["user_id", "normalized_name", "meal_type"],
    )
    op.create_index(
        "ix_user_food_items_meal_type",
        "user_food_items",
        ["meal_type"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_user_food_items_meal_type", table_name="user_food_items")
    op.drop_constraint(
        "uq_user_food_items_user_id_normalized_name",
        "user_food_items",
        type_="unique",
    )
    op.create_unique_constraint(
        "uq_user_food_items_user_id_normalized_name",
        "user_food_items",
        ["user_id", "normalized_name"],
    )
    op.drop_column("user_food_items", "meal_type")
