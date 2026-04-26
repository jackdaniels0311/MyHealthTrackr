"""Add food log day unique key.

Revision ID: 7a9d3e2c1b4f
Revises: 6f8a2c4e9b1d
Create Date: 2026-04-26 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "7a9d3e2c1b4f"
down_revision: Union[str, None] = "6f8a2c4e9b1d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("food_logs", sa.Column("log_day", sa.Date(), nullable=True))
    op.execute("UPDATE food_logs SET log_day = CAST(log_date AS DATE)")

    op.execute(
        """
        UPDATE meal_logs
        SET food_log_id = canonical.food_log_id
        FROM (
            SELECT user_id, log_day, MIN(food_log_id) AS food_log_id
            FROM food_logs
            GROUP BY user_id, log_day
            HAVING COUNT(*) > 1
        ) AS canonical
        JOIN food_logs AS duplicate
          ON duplicate.user_id = canonical.user_id
         AND duplicate.log_day = canonical.log_day
         AND duplicate.food_log_id <> canonical.food_log_id
        WHERE meal_logs.food_log_id = duplicate.food_log_id
        """
    )
    op.execute(
        """
        DELETE FROM food_logs
        USING (
            SELECT user_id, log_day, MIN(food_log_id) AS food_log_id
            FROM food_logs
            GROUP BY user_id, log_day
            HAVING COUNT(*) > 1
        ) AS canonical
        WHERE food_logs.user_id = canonical.user_id
          AND food_logs.log_day = canonical.log_day
          AND food_logs.food_log_id <> canonical.food_log_id
        """
    )

    op.alter_column("food_logs", "log_day", existing_type=sa.Date(), nullable=False)
    op.create_index("ix_food_logs_log_day", "food_logs", ["log_day"], unique=False)
    op.create_unique_constraint(
        "uq_food_logs_user_id_log_day",
        "food_logs",
        ["user_id", "log_day"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_food_logs_user_id_log_day", "food_logs", type_="unique")
    op.drop_index("ix_food_logs_log_day", table_name="food_logs")
    op.drop_column("food_logs", "log_day")
