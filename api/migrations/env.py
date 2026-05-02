from __future__ import annotations

import os
import sys
from pathlib import Path
from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

# Ensure the app package is importable when running alembic from different working dirs
BASE_DIR = Path(__file__).resolve().parent.parent  # /app (repo root inside container)
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

from app.database.session import Base  # noqa: E402
from app import models  # noqa: F401, E402

target_metadata = Base.metadata


def get_database_url() -> str:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError("DATABASE_URL is not set")
    return url


def run_migrations_offline() -> None:
    context.configure(
        url=get_database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = create_engine(
        get_database_url(),
        poolclass=pool.NullPool,
        pool_pre_ping=True,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
