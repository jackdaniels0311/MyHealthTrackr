"""constrain health profile activity level

Revision ID: c7e8d1f4a6b2
Revises: b3f5c1a9d2e4
Create Date: 2026-03-23 15:05:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "c7e8d1f4a6b2"
down_revision: Union[str, None] = "b3f5c1a9d2e4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


CONSTRAINT_NAME = "ck_health_profiles_activity_level_allowed"


def upgrade() -> None:
    op.execute(
        """
        UPDATE health_profiles
        SET activity_level = NULL
        WHERE activity_level IS NOT NULL
          AND activity_level NOT IN (
              'Not Active',
              'Lightly Active',
              'Active',
              'Very Active'
          )
        """
    )
    op.execute(
        f"""
        ALTER TABLE health_profiles
        ADD CONSTRAINT {CONSTRAINT_NAME}
        CHECK (
            activity_level IS NULL OR activity_level IN (
                'Not Active',
                'Lightly Active',
                'Active',
                'Very Active'
            )
        )
        """
    )


def downgrade() -> None:
    op.drop_constraint(
        CONSTRAINT_NAME,
        "health_profiles",
        type_="check",
    )
