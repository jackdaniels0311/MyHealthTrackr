"""add user food history table

Revision ID: b7c9d1e2f3a4
Revises: e4a1b6c9d2f3, a1e6c9f4b2d3
Create Date: 2026-04-17 10:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b7c9d1e2f3a4"
down_revision: Union[str, Sequence[str], None] = ("e4a1b6c9d2f3", "a1e6c9f4b2d3")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_food_items",
        sa.Column("user_food_item_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("meal_name", sa.String(length=255), nullable=False),
        sa.Column("normalized_name", sa.String(length=255), nullable=False),
        sa.Column("serving_size", sa.Integer(), nullable=True),
        sa.Column("quantity", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("calories", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("protein", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("carbs", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fat", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fibre", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("sugar", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("times_logged", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("last_logged_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_food_item_id"),
        sa.UniqueConstraint(
            "user_id",
            "normalized_name",
            name="uq_user_food_items_user_id_normalized_name",
        ),
    )
    op.create_index(
        "ix_user_food_items_user_id",
        "user_food_items",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_user_food_items_normalized_name",
        "user_food_items",
        ["normalized_name"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_user_food_items_normalized_name", table_name="user_food_items")
    op.drop_index("ix_user_food_items_user_id", table_name="user_food_items")
    op.drop_table("user_food_items")
