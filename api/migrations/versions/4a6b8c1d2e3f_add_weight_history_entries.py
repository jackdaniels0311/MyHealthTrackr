"""add weight history entries

Revision ID: 4a6b8c1d2e3f
Revises: 3e5f7a9b2c4d
Create Date: 2026-04-22 12:15:00.000000

"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "4a6b8c1d2e3f"
down_revision: Union[str, None] = "3e5f7a9b2c4d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "weight_entries",
        sa.Column("weight_entry_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("weight_kg", sa.Numeric(precision=8, scale=2), nullable=False),
        sa.Column(
            "recorded_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["User.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_weight_entries_user_id", "weight_entries", ["user_id"], unique=False)
    op.create_index(
        "ix_weight_entries_recorded_at",
        "weight_entries",
        ["recorded_at"],
        unique=False,
    )

    op.execute(
        """
        INSERT INTO weight_entries (user_id, weight_kg, recorded_at, created_at)
        SELECT
            hp.user_id,
            hp.weight_kg,
            COALESCE(hp.updated_at, hp.created_at, NOW()),
            NOW()
        FROM health_profiles hp
        WHERE hp.weight_kg IS NOT NULL
        """
    )


def downgrade() -> None:
    op.drop_index("ix_weight_entries_recorded_at", table_name="weight_entries")
    op.drop_index("ix_weight_entries_user_id", table_name="weight_entries")
    op.drop_table("weight_entries")
