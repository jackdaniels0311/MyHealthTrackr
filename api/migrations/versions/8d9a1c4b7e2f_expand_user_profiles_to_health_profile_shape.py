"""expand user_profiles to health profile shape

Revision ID: 8d9a1c4b7e2f
Revises: 901f8b6d435b
Create Date: 2026-03-23 14:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "8d9a1c4b7e2f"
down_revision: Union[str, None] = "901f8b6d435b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_profiles_v2",
        sa.Column("profile_id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=True),
        sa.Column("last_name", sa.String(length=100), nullable=True),
        sa.Column("date_of_birth", sa.Date(), nullable=True),
        sa.Column("gender", sa.String(length=20), nullable=True),
        sa.Column("height_cm", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("weight_kg", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("activity_level", sa.String(length=30), nullable=True),
        sa.Column("dietary_preferences", sa.String(length=255), nullable=True),
        sa.Column("allergies", sa.String(length=255), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", name="uq_user_profiles_user_id"),
    )

    op.execute(
        """
        INSERT INTO user_profiles_v2 (
            user_id,
            first_name,
            last_name,
            date_of_birth,
            gender,
            height_cm,
            weight_kg,
            activity_level,
            dietary_preferences,
            allergies,
            created_at,
            updated_at
        )
        SELECT
            user_id,
            first_name,
            last_name,
            date_of_birth,
            sex,
            height_cm,
            weight_kg,
            activity_level,
            dietary_preferences,
            allergies,
            created_at,
            updated_at
        FROM user_profiles
        """
    )

    op.drop_table("user_profiles")
    op.rename_table("user_profiles_v2", "user_profiles")


def downgrade() -> None:
    op.create_table(
        "user_profiles_legacy",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=True),
        sa.Column("last_name", sa.String(length=100), nullable=True),
        sa.Column("date_of_birth", sa.Date(), nullable=True),
        sa.Column("sex", sa.String(length=20), nullable=True),
        sa.Column("height_cm", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("weight_kg", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("activity_level", sa.String(length=30), nullable=True),
        sa.Column("dietary_preferences", sa.String(length=255), nullable=True),
        sa.Column("allergies", sa.String(length=255), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id"),
    )

    op.execute(
        """
        INSERT INTO user_profiles_legacy (
            user_id,
            first_name,
            last_name,
            date_of_birth,
            sex,
            height_cm,
            weight_kg,
            activity_level,
            dietary_preferences,
            allergies,
            created_at,
            updated_at
        )
        SELECT
            user_id,
            first_name,
            last_name,
            date_of_birth,
            gender,
            height_cm,
            weight_kg,
            activity_level,
            dietary_preferences,
            allergies,
            created_at,
            updated_at
        FROM user_profiles
        """
    )

    op.drop_table("user_profiles")
    op.rename_table("user_profiles_legacy", "user_profiles")
