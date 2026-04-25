"""add recommended water to user nutrition targets

Revision ID: a1e6c9f4b2d3
Revises: f8c4d2a7b1e9
Create Date: 2026-04-16 00:30:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a1e6c9f4b2d3"
down_revision: Union[str, None] = "f8c4d2a7b1e9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_nutrition_targets",
        sa.Column("recommended_water_ml", sa.Numeric(10, 2), nullable=True),
    )

    bind = op.get_bind()
    bind.execute(
        sa.text(
            """
            UPDATE user_nutrition_targets
            SET recommended_water_ml = (
                ROUND(
                    (
                        (
                            (CAST(weight_kg AS NUMERIC(10, 2)) * 35.0) +
                            CASE activity_level
                                WHEN 'Lightly Active' THEN 250.0
                                WHEN 'Active' THEN 500.0
                                WHEN 'Very Active' THEN 750.0
                                ELSE 0.0
                            END
                        ) / 50.0
                    ),
                    0
                ) * 50.0
            )
            """
        )
    )

    op.alter_column(
        "user_nutrition_targets",
        "recommended_water_ml",
        existing_type=sa.Numeric(10, 2),
        nullable=False,
    )


def downgrade() -> None:
    op.drop_column("user_nutrition_targets", "recommended_water_ml")
