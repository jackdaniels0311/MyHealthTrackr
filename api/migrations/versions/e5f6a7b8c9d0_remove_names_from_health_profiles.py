"""remove names from health profiles

Revision ID: e5f6a7b8c9d0
Revises: d4e2f8a1b7c3
Create Date: 2026-03-23 15:40:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, None] = "d4e2f8a1b7c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE "User" AS u
        SET name = NULLIF(
            TRIM(
                COALESCE(hp.first_name, '') || ' ' || COALESCE(hp.last_name, '')
            ),
            ''
        )
        FROM health_profiles AS hp
        WHERE hp.user_id = u.id
          AND (u.name IS NULL OR BTRIM(u.name) = '')
          AND (
              COALESCE(hp.first_name, '') <> ''
              OR COALESCE(hp.last_name, '') <> ''
          )
        """
    )

    op.drop_column("health_profiles", "first_name")
    op.drop_column("health_profiles", "last_name")


def downgrade() -> None:
    op.add_column(
        "health_profiles",
        sa.Column("last_name", sa.String(length=100), nullable=True),
    )
    op.add_column(
        "health_profiles",
        sa.Column("first_name", sa.String(length=100), nullable=True),
    )
