from fastapi import APIRouter

router = APIRouter(tags=["System"])


@router.get(
    "/",
    summary="API status",
    response_description="A short confirmation that the API is running.",
)
def root():
    return {"message": "MyHealthTrackr API is running!"}


@router.get(
    "/health",
    summary="Health check",
    response_description="The current API health status.",
)
def health_check():
    return {"status": "ok"}
