from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.api_docs import CONFLICT_RESPONSES
from ..core.auth import get_current_user
from ..database.session import get_db
from ..dependencies import enforce_user_scope, require_user
from ..models import User
from ..schemas import UserCreate, UserOut, UserUpdate
from ..core.security import hash_password

router = APIRouter(tags=["Users"], responses=CONFLICT_RESPONSES)


@router.post("/users", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    email = user.email.lower()
    existing_user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=409, detail="Email already registered")

    hashed_password = hash_password(user.password)
    name = user.name.strip() if user.name else None
    new_user = User(name=name or None, email=email, password_hashed=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.get("/users/me", response_model=UserOut, include_in_schema=False)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/users/me", response_model=UserOut, include_in_schema=False)
def update_me(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return update_user(
        user_id=current_user.id,
        payload=payload,
        db=db,
        current_user=current_user,
    )


@router.get("/users/{user_id}", response_model=UserOut)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    return require_user(db, user_id)


@router.put("/users/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    user = require_user(db, user_id)
    user.name = payload.name.strip() if payload.name else None
    db.commit()
    db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    enforce_user_scope(user_id, current_user)
    user = require_user(db, user_id)
    db.delete(user)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
