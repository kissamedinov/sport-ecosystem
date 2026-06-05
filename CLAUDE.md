# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sports Ecosystem Platform - A full-stack sports management system with a Flutter mobile app and FastAPI backend. Manages tournaments, teams, matches, field rentals, bookings, academies, clubs, and player statistics.

## Tech Stack

- **Frontend**: Flutter (Dart) with Provider for state management
- **Backend**: FastAPI (Python) with SQLAlchemy ORM
- **Database**: PostgreSQL
- **Auth**: JWT tokens + bcrypt password hashing

## Development Commands

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload  # API at http://127.0.0.1:8000
```

Database connection via `DATABASE_URL` env var (default: `postgresql://postgres:postgres@localhost/sportseco`).

### Flutter

```bash
flutter pub get
flutter run
```

Code generation (after modifying models with json_annotation):
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Backend Structure (`backend/app/`)

Domain-driven modular architecture. Each module follows:
```
module/
├── models.py      # SQLAlchemy ORM models
├── schemas.py     # Pydantic request/response schemas
├── routes.py      # FastAPI route handlers
└── services.py    # Business logic
```

Key modules: `auth`, `users`, `tournaments`, `teams`, `matches`, `clubs`, `academies`, `fields`, `bookings`, `notifications`, `stats`, `media`

Database session dependency: `from app.database import get_db` with `Depends(get_db)`

### Flutter Structure (`lib/`)

Feature-based architecture with Clean Architecture layers:
```
lib/
├── core/
│   ├── api/api_client.dart    # Dio HTTP client with JWT interceptor
│   ├── services/token_service.dart
│   └── theme/app_theme.dart
└── features/
    └── [feature]/
        ├── data/
        │   ├── models/        # JSON serializable models
        │   └── repositories/  # API calls
        ├── presentation/
        │   ├── screens/
        │   └── widgets/
        └── providers/         # ChangeNotifierProvider state
```

API base URL is hardcoded in `lib/core/api/api_client.dart` (production: `http://207.154.222.151`).

### Role System

15 user roles: `ADMIN`, `TOURNAMENT_MANAGER`, `REFEREE`, `COACH`, `PLAYER_ADULT`, `PLAYER_CHILD`, `PLAYER_YOUTH`, `PARENT`, `FIELD_OWNER`, `SCOUT`, `TOURNAMENT_ORGANIZER`, `ACADEMY_ADMIN`, `TEAM_OWNER`, `CLUB_OWNER`, `CLUB_MANAGER`

Users can have multiple roles via `UserRole` many-to-many relationship.

### Tournament Hierarchy

`TournamentSeries` → `Tournament` (with format: LEAGUE/GROUP_STAGE/KNOCKOUT) → `TournamentDivision` → `TournamentGroup` → `Match`

### Academy Structure

`Academy` → `AcademyBranch` (multiple locations) → `AcademyTeam` (age groups U7-U17) → `AcademyPlayer`

Training schedules: `TrainingSchedule` (recurring) → `AcademySession` (instances)

## Database Migrations

Auto table creation is disabled for Gunicorn concurrency. Schema changes require manual migration scripts in `backend/scripts/`.

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `AI_SCHEDULER_TOKEN` - For AI-powered match scheduling (used in `tournaments/ai_scheduler_service.py`)
