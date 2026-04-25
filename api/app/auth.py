import os
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import get_db
from .models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

JWT_SECRET = os.environ.get("JWT_SECRET", "dev_only_change_me")
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
JWT_EXPIRES_MINUTES = int(os.environ.get("JWT_EXPIRES_MINUTES", "60"))
JWT_REFRESH_EXPIRES_DAYS = int(os.environ.get("JWT_REFRESH_EXPIRES_DAYS", "30"))

ACCESS_TOKEN_TYPE = "access"
REFRESH_TOKEN_TYPE = "refresh"


def _create_token(
    *,
    subject: str,
    token_type: str,
    expires_at: datetime,
) -> str:
    payload = {"sub": subject, "exp": expires_at, "token_type": token_type}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def create_access_token(*, subject: str, expires_minutes: Optional[int] = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=expires_minutes if expires_minutes is not None else JWT_EXPIRES_MINUTES
    )
    return _create_token(
        subject=subject,
        token_type=ACCESS_TOKEN_TYPE,
        expires_at=expire,
    )


def create_refresh_token(*, subject: str, expires_days: Optional[int] = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        days=expires_days if expires_days is not None else JWT_REFRESH_EXPIRES_DAYS
    )
    return _create_token(
        subject=subject,
        token_type=REFRESH_TOKEN_TYPE,
        expires_at=expire,
    )


def decode_token_payload(token: str) -> dict[str, Any]:
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = decode_token_payload(token)
        subject = payload.get("sub")
        token_type = payload.get("token_type", ACCESS_TOKEN_TYPE)
        if subject is None or token_type != ACCESS_TOKEN_TYPE:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # subject is user id (stored as string)
    user = db.scalar(select(User).where(User.id == int(subject)))
    if not user:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Inactive user")

    return user
