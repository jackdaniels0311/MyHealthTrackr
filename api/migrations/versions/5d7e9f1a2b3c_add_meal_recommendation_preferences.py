"""add meal recommendation preferences

Revision ID: 5d7e9f1a2b3c
Revises: 4a6b8c1d2e3f
Create Date: 2026-04-25 21:30:00.000000

"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "5d7e9f1a2b3c"
down_revision: Union[str, None] = "4a6b8c1d2e3f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_meal_recommendation_preferences",
        sa.Column(
            "meal_recommendation_preference_id",
            sa.Integer(),
            primary_key=True,
            autoincrement=True,
        ),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("goal_type", sa.String(length=30), nullable=True),
        sa.Column("allergies", sa.String(length=500), nullable=True),
        sa.Column("dietary_preferences", sa.String(length=500), nullable=True),
        sa.Column("diet_plan_type", sa.String(length=100), nullable=True),
        sa.Column("meal_types", sa.JSON(), nullable=False),
        sa.Column("diet_targets", sa.JSON(), nullable=False),
        sa.Column("disliked_foods", sa.String(length=500), nullable=True),
        sa.Column("liked_cuisines", sa.String(length=500), nullable=True),
        sa.Column("disliked_cuisines", sa.String(length=500), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
    )
    op.create_index(
        "ix_user_meal_recommendation_preferences_user_id",
        "user_meal_recommendation_preferences",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_user_meal_recommendation_preferences_user_id",
        table_name="user_meal_recommendation_preferences",
    )
    op.drop_table("user_meal_recommendation_preferences")
