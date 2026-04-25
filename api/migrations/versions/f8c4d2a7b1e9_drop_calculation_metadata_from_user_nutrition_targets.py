"""drop calculation metadata from user nutrition targets

Revision ID: f8c4d2a7b1e9
Revises: f6b3a1c9d7e2
Create Date: 2026-04-14 18:55:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "f8c4d2a7b1e9"
down_revision: Union[str, None] = "f6b3a1c9d7e2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("user_nutrition_targets", "calculation_method")
    op.drop_column("user_nutrition_targets", "calculation_version")


def downgrade() -> None:
    op.add_column(
        "user_nutrition_targets",
        sa.Column("calculation_version", sa.String(length=50), nullable=False),
    )
    op.add_column(
        "user_nutrition_targets",
        sa.Column("calculation_method", sa.String(length=500), nullable=False),
    )
