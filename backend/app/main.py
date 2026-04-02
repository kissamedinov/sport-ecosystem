from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from app.database import Base, engine
from app.auth.routes import router as auth_router
from app.teams.routes import router as teams_router
from app.tournaments.routes import router as tournaments_router
from app.matches.routes import router as matches_router
from app.bookings.routes import router as bookings_router
from app.fields.routes import router as fields_router
from app.media.routes import router as media_router
from app.stats.routes import router as stats_router
from app.notifications.routes import router as notifications_router
from app.academies.routes import router as academies_router
from app.users.routes import router as users_router
from app.clubs.routes import router as clubs_router

# Import all models for Base.metadata
from app.users import models as user_models
from app.teams import models as team_models
from app.tournaments import models as tournament_models
from app.matches import models as match_models
from app.bookings import models as booking_models
from app.fields import models as field_models
from app.clubs import models as club_models_system
from app.academies import models as academy_models
from app.club_teams import models as club_teams_models
from app.pickup import models as pickup_models
from app.scouting import models as scouting_models
from app.stats import models as stats_models
from app.media import models as media_models
from app.notifications import models as notification_models

# Create DB tables (Disabled for Gunicorn concurrency)
# Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sports Ecosystem API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; refine for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(teams_router)
app.include_router(tournaments_router)
app.include_router(matches_router)
app.include_router(bookings_router)
app.include_router(fields_router)
app.include_router(media_router)
app.include_router(stats_router)
app.include_router(notifications_router)
app.include_router(academies_router)
app.include_router(users_router)
app.include_router(clubs_router)

# Ensure uploads directory exists
if not os.path.exists("uploads"):
    os.makedirs("uploads")

# Mount uploads directory for static serving
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def read_root():
    return {"message": "Welcome to the Sports Ecosystem API"}
