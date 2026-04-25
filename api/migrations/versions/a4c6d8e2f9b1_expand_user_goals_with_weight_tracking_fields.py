"""expand user goals with weight tracking fields

Revision ID: a4c6d8e2f9b1
Revises: f1a2b3c4d5e6
Create Date: 2026-04-08 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a4c6d8e2f9b1"
down_revision: Union[str, None] = "f1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE user_goals
        SET goal_type = 'Maintain Weight'
        WHERE goal_type NOT IN ('Gain Weight', 'Maintain Weight', 'Lose Weight')
        """
    )

    op.add_column(
        "user_goals",
        sa.Column(
            "goal_start_date",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
    )
    op.add_column(
        "user_goals",
        sa.Column("goal_start_weight", sa.Numeric(precision=8, scale=2), nullable=True),
    )
    op.add_column(
        "user_goals",
        sa.Column("weekly_goal", sa.Numeric(precision=4, scale=2), nullable=True),
    )

    op.create_check_constraint(
        "ck_user_goals_goal_type_allowed",
        "user_goals",
        "goal_type IN ('Gain Weight', 'Maintain Weight', 'Lose Weight')",
    )
    op.create_check_constraint(
        "ck_user_goals_weekly_goal_allowed",
        "user_goals",
        "weekly_goal IS NULL OR weekly_goal IN (-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0)",
    )


def downgrade() -> None:
    op.drop_constraint("ck_user_goals_weekly_goal_allowed", "user_goals", type_="check")
    op.drop_constraint("ck_user_goals_goal_type_allowed", "user_goals", type_="check")
    op.drop_column("user_goals", "weekly_goal")
    op.drop_column("user_goals", "goal_start_weight")
    op.drop_column("user_goals", "goal_start_date")
