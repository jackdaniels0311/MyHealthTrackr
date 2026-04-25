"""add goal and meal tracking tables

Revision ID: f1a2b3c4d5e6
Revises: e5f6a7b8c9d0
Create Date: 2026-03-25 20:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "f1a2b3c4d5e6"
down_revision: Union[str, None] = "e5f6a7b8c9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_goals",
        sa.Column("goal_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("goal_type", sa.String(length=100), nullable=False),
        sa.Column("goal_weight", sa.Numeric(precision=8, scale=2), nullable=True),
        sa.Column("goal_date", sa.Date(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_user_goals_user_id", "user_goals", ["user_id"], unique=False)

    op.create_table(
        "food_logs",
        sa.Column("food_log_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("log_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("goal_weight", sa.Numeric(precision=8, scale=2), nullable=True),
        sa.Column("goal_date", sa.Date(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_food_logs_user_id", "food_logs", ["user_id"], unique=False)

    op.create_table(
        "meal_logs",
        sa.Column("meal_log_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("food_log_id", sa.Integer(), nullable=False),
        sa.Column("meal_type", sa.String(length=100), nullable=False),
        sa.Column("meal_logged_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["food_log_id"],
            ["food_logs.food_log_id"],
            ondelete="CASCADE",
        ),
    )
    op.create_index("ix_meal_logs_food_log_id", "meal_logs", ["food_log_id"], unique=False)

    op.create_table(
        "meal_items",
        sa.Column("meal_item_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("meal_log_id", sa.Integer(), nullable=False),
        sa.Column("meal_name", sa.String(length=255), nullable=False),
        sa.Column("quantity", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("calories", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("protein", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("carbs", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fat", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("fibre", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("sugar", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("meal_logged_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["meal_log_id"],
            ["meal_logs.meal_log_id"],
            ondelete="CASCADE",
        ),
    )
    op.create_index("ix_meal_items_meal_log_id", "meal_items", ["meal_log_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_meal_items_meal_log_id", table_name="meal_items")
    op.drop_table("meal_items")

    op.drop_index("ix_meal_logs_food_log_id", table_name="meal_logs")
    op.drop_table("meal_logs")

    op.drop_index("ix_food_logs_user_id", table_name="food_logs")
    op.drop_table("food_logs")

    op.drop_index("ix_user_goals_user_id", table_name="user_goals")
    op.drop_table("user_goals")
