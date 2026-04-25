"""add saved meals tables

Revision ID: 1b2c3d4e5f6a
Revises: c3d4e5f6a7b8
Create Date: 2026-04-18 12:30:00.000000

"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "1b2c3d4e5f6a"
down_revision: Union[str, None] = "c3d4e5f6a7b8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "saved_meals",
        sa.Column("saved_meal_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_saved_meals_user_id", "saved_meals", ["user_id"], unique=False)

    op.create_table(
        "saved_meal_items",
        sa.Column("saved_meal_item_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("saved_meal_id", sa.Integer(), nullable=False),
        sa.Column("meal_name", sa.String(length=255), nullable=False),
        sa.Column("serving_size", sa.Integer(), nullable=True),
        sa.Column("quantity", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("calories", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("protein", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("carbs", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fat", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fibre", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("sugar", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["saved_meal_id"], ["saved_meals.saved_meal_id"], ondelete="CASCADE"),
    )
    op.create_index(
        "ix_saved_meal_items_saved_meal_id",
        "saved_meal_items",
        ["saved_meal_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_saved_meal_items_saved_meal_id", table_name="saved_meal_items")
    op.drop_table("saved_meal_items")
    op.drop_index("ix_saved_meals_user_id", table_name="saved_meals")
    op.drop_table("saved_meals")
