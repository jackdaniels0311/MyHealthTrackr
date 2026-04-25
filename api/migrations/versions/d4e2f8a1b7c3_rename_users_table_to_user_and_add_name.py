"""rename users table to User and add name

Revision ID: d4e2f8a1b7c3
Revises: c7e8d1f4a6b2
Create Date: 2026-03-23 15:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d4e2f8a1b7c3"
down_revision: Union[str, None] = "c7e8d1f4a6b2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.rename_table("users", "User")
    op.add_column("User", sa.Column("name", sa.String(length=255), nullable=True))

    op.execute('ALTER INDEX ix_users_email RENAME TO "ix_User_email"')
    op.execute('ALTER INDEX ix_users_id RENAME TO "ix_User_id"')

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
          AND u.name IS NULL
        """
    )

    op.execute(
        """
        UPDATE "User"
        SET name = NULLIF(INITCAP(REPLACE(SPLIT_PART(email, '@', 1), '.', ' ')), '')
        WHERE name IS NULL
        """
    )


def downgrade() -> None:
    op.execute('ALTER INDEX "ix_User_email" RENAME TO ix_users_email')
    op.execute('ALTER INDEX "ix_User_id" RENAME TO ix_users_id')
    op.drop_column("User", "name")
    op.rename_table("User", "users")
