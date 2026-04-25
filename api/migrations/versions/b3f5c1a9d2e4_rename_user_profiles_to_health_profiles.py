"""rename user_profiles to health_profiles

Revision ID: b3f5c1a9d2e4
Revises: 8d9a1c4b7e2f
Create Date: 2026-03-23 14:50:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "b3f5c1a9d2e4"
down_revision: Union[str, None] = "8d9a1c4b7e2f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.rename_table("user_profiles", "health_profiles")
    op.execute(
        """
        ALTER TABLE health_profiles
        RENAME CONSTRAINT uq_user_profiles_user_id
        TO uq_health_profiles_user_id
        """
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE health_profiles
        RENAME CONSTRAINT uq_health_profiles_user_id
        TO uq_user_profiles_user_id
        """
    )
    op.rename_table("health_profiles", "user_profiles")
