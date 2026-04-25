"""convert meal item serving size to int

Revision ID: d9f4b2c7a1e3
Revises: c2b7a9d4e6f1
Create Date: 2026-04-11 12:30:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d9f4b2c7a1e3"
down_revision: Union[str, None] = "c2b7a9d4e6f1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE meal_items
        ALTER COLUMN serving_size
        TYPE INTEGER
        USING CASE
            WHEN serving_size IS NULL OR btrim(serving_size) = '' THEN NULL
            ELSE ROUND(
                CAST(
                    NULLIF(regexp_replace(serving_size, '[^0-9.]', '', 'g'), '')
                    AS NUMERIC
                )
            )::INTEGER
        END
        """
    )


def downgrade() -> None:
    op.alter_column(
        "meal_items",
        "serving_size",
        existing_type=sa.Integer(),
        type_=sa.String(length=100),
        existing_nullable=True,
        postgresql_using="""
        CASE
            WHEN serving_size IS NULL THEN NULL
            ELSE serving_size::VARCHAR || 'g'
        END
        """,
    )
