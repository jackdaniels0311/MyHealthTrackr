from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.database.session import SessionLocal
from app.services.nutrition_targets import NutritionTargetCalculator


def main() -> None:
    calculator = NutritionTargetCalculator()
    db = SessionLocal()

    try:
        summary = calculator.sync_all_users(db)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    print(
        "Backfill complete: "
        f"profiles_seen={summary.total_profiles_seen}, "
        f"targets_synced={summary.targets_synced}, "
        f"targets_cleared={summary.targets_cleared}"
    )


if __name__ == "__main__":
    main()
