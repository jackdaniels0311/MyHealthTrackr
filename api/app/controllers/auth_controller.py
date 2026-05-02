from jose import JWTError
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.api_docs import AUTH_RESPONSES
from ..core.auth import (
    REFRESH_TOKEN_TYPE,
    create_access_token,
    create_refresh_token,
    decode_token_payload,
)
from ..database.session import get_db
from ..models import User
from ..schemas import AuthToken, RefreshTokenRequest
from ..core.security import verify_password

router = APIRouter(tags=["Auth"], responses=AUTH_RESPONSES)


@router.post("/auth/login", response_model=AuthToken)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    email = form_data.username.lower()
    user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    if not verify_password(form_data.password, user.password_hashed):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Inactive user")

    return {
        "access_token": create_access_token(subject=str(user.id)),
        "refresh_token": create_refresh_token(subject=str(user.id)),
        "token_type": "bearer",
    }


@router.post("/auth/refresh", response_model=AuthToken)
def refresh_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Invalid refresh token",
    )

    try:
        token_payload = decode_token_payload(payload.refresh_token)
        subject = token_payload.get("sub")
        token_type = token_payload.get("token_type")
        if subject is None or token_type != REFRESH_TOKEN_TYPE:
            raise credentials_exception
        user_id = int(subject)
    except (JWTError, ValueError, TypeError):
        raise credentials_exception

    user = db.execute(select(User).where(User.id == user_id)).scalar_one_or_none()
    if not user:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Inactive user")

    return {
        "access_token": create_access_token(subject=str(user.id)),
        "refresh_token": create_refresh_token(subject=str(user.id)),
        "token_type": "bearer",
    }
