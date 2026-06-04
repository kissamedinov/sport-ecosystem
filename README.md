# OrleOn — Sports Ecosystem Platform 🏆⚽

> **OrleOn** is a next-generation, full-stack sports management platform that orchestrates the entire lifecycle of sports organizations: from youth academies and adult clubs to tournament management, field bookings, live match events, and scouting — all wrapped in a premium neon-accented dark UI.

---

## 📋 Table of Contents

1. [Platform Overview](#-platform-overview)
2. [Core Features](#-core-features)
3. [Role-Based Workflows](#-role-based-workflows)
4. [Technology Stack](#-technology-stack)
5. [Architecture](#-architecture)
6. [Backend API Modules](#-backend-api-modules)
7. [Mobile App Structure](#-mobile-app-structure)
8. [Setup & Installation](#-setup--installation)
9. [Environment Variables](#-environment-variables)
10. [Security & State Management](#-security--state-management)

---

## 🌐 Platform Overview

OrleOn bridges the gap between **11 distinct user roles** through dedicated dashboards and role-specific workflows:

| Role | Description |
|------|-------------|
| 👟 Adult Player | Books fields, joins tournaments, tracks personal stats |
| 🧒 Youth Player | Participates in quizzes, earns points, views training |
| 👪 Parent | Links children, monitors activity, manages billing |
| 📋 Coach | Manages squads, logs attendance, submits match events |
| 🛡️ Club Owner | Runs academies, hires staff, views financials |
| ⚙️ Club Manager | Oversees daily operations, manages rosters |
| 🏆 Tournament Organizer | Creates tournaments, assigns referees, publishes standings |
| 🏟️ Field Owner | Lists fields, manages booking calendar, views analytics |
| 🏁 Referee | Logs live match events, submits post-game reports |
| 🔎 Scout | Searches talent databases by position, metrics, and stats |
| 👑 Admin | Full system control, user management, global logs |

---

## 🌟 Core Features

### 🏟️ Interactive Map & Arena Booking
- **Dark-Matter Map Tiles** — Uses `flutter_map` with CartoDB Dark Matter tiles, blending seamlessly into the premium dark UI.
- **Field Discovery** — Players and adult users find nearby football fields using real-time geolocation.
- **Slot Booking System** — Interactive daily calendar grid with color-coded status: `Pending`, `Confirmed`, `Blocked`.
- **Daily Grid Generator** — Field owners generate a full day's slots in one tap.
- **Automated Cancellation** — Releasing a booking frees the slot and notifies affected users.

### 💳 Payment Integration
- **Kaspi QR** — Local Kazakh users pay via QR code linked to Kaspi Bank.
- **Stripe Checkout** — International users pay via Stripe with webhook verification for automatic booking transitions.
- **Academy Billing** — Monthly fees auto-computed based on training attendance records.

### 🏆 AI-Powered Tournament Engine
- **AI Match Planner** — Heuristic algorithms balance divisions, assign group stages, and generate fixture drafts (League, Knockout, Group Stage).
- **Logistics Review Panel** — Tournament managers drag, drop, reschedule, and swap fixtures before final publication.
- **Real-Time Standings** — Automated computation of points, goal difference, top scorers, assist leaders, and card counts.
- **Division & Pool Management** — Multi-pool round-robin with configurable team limits per pool.

### 🎓 Academy CRM & Youth Gamification
- **Recurring Training Cycles** — Auto-generates training sessions with attendance tracking.
- **Dynamic Attendance Billing** — Monthly fees calculated from actual session attendance.
- **Daily Quiz System** — Children answer daily football knowledge questions.
- **Streak Tracking (`deystrik`)** — Consecutive-login streaks award bonus points.
- **Youth Leaderboard** — Points-based ranking visible to all users (only players with score > 0 displayed).

### 📊 Statistics & Analytics
- **Player Stats** — Goals, assists, yellow/red cards, match minutes per player.
- **Team Stats** — Win/draw/loss record, GF, GA, goal difference, ranking.
- **Field Owner Analytics** — Occupancy rates, monthly earnings, booking trend charts.
- **Coach Reports** — Qualitative player feedback with numeric ratings.

### 🔔 Notification System
- **Real-Time Push Notifications** — Event-driven notifications for:
  - Invitations (club, academy, team)
  - Booking confirmations / cancellations
  - Match results & standings updates
  - Training reminders
- **In-App Badge Counters** — Unread count shown on Home and Profile screens, synced on state change.
- **Notification Center** — Paginated history with mark-as-read functionality.

### 📸 Media & Content
- **Upload Infrastructure** — Image uploads for field listings, player avatars, club logos, and academy banners.
- **Cached Network Images** — `cached_network_image` for smooth image loading across slow connections.

### 🛡️ State Security & Memory Isolation
- **Global Reset on Logout** — `onLogoutCallbacks` in `AuthProvider` clears all provider caches (`ClubProvider`, `TeamProvider`, `ChildProvider`, `NotificationProvider`), preventing cross-user data leakage.
- **Dynamic Club Resolution** — Backend `get_user_club_name` recursively resolves memberships across `ChildProfile`, `ClubStaff`, and owners; returns `«без клуба»` if unassociated.

---

## 👥 Role-Based Workflows

OrleOn uses strict Role-Based Access Control (RBAC). On login, `RoleRouter` redirects to the user's dedicated dashboard.

---

### 👟 1. Adult Player — `AdultPlayerDashboard`

| Feature | Details |
|---------|---------|
| Tournament Tracker | Upcoming matches, bracket progression, personal stats |
| Map Booking | Find fields on dark-matter map, check slots, book & pay |
| Payment | Kaspi QR or Stripe Checkout |
| Pickup Games | Join or create casual pickup matches |
| Daily Quiz | Test football knowledge for points |
| Notifications | Match invites, booking confirmations |

---

### 🧒 2. Youth Player (Child) — `ChildPlayerDashboard`

| Feature | Details |
|---------|---------|
| Football Hub | Daily quizzes, streak tracking, points accumulation |
| Youth Rankings | Leaderboard sorted by total points |
| Join Requests | Accept parent-link or club/academy invitations |
| Training Schedule | View upcoming training sessions and feedback |
| Match History | View past games and personal match stats |

---

### 👪 3. Parent — `ParentDashboard`

| Feature | Details |
|---------|---------|
| Child Linking | Link children via `unique_code` or email |
| Activity Monitor | Physical metrics, attendance logs, game history |
| Coach Feedback | Read performance reviews and ratings |
| Billing | Monthly academy invoices with Stripe/Kaspi payment |
| Notifications | Training alerts, coach updates, billing reminders |

---

### 📋 4. Coach — `CoachDashboardScreen`

| Feature | Details |
|---------|---------|
| Squad Management | Assign positions, jersey numbers, manage squad lists |
| Attendance Journal | Log training attendance → feeds parent billing |
| Match Event Logger | Live input: goals, assists, cards, substitutions, injuries |
| Player Reviews | Write qualitative feedback reports sent to parents |
| Match Reports | View upcoming match fixtures and submit post-game reports |

---

### 🛡️ 5. Club Owner — `ClubDashboardScreen` (Owner View)

| Feature | Details |
|---------|---------|
| Club Creation | Create club, upload logo, set description and location |
| Academy CRM | Create academies, define branches, set tuition rates |
| Staff Hiring | Invite coaches, managers, admins by email |
| Team Management | Create teams, assign coaches and players |
| Financial Reports | Track registrations, active player count, academy payouts |
| Children Enrollment | Enroll youth players into academies |

---

### ⚙️ 6. Club Manager — `ClubDashboardScreen` (Manager View)

| Feature | Details |
|---------|---------|
| Operations | Approve branch updates, oversee daily operations |
| Roster Coordinator | Register teams for tournaments and leagues |
| Player Invitations | Invite players to teams, manage jersey assignments |
| Training Oversight | Schedule and monitor training cycles |

---

### 🏆 7. Tournament Organizer — `OrganizerDashboardScreen`

| Feature | Details |
|---------|---------|
| Tournament Creation | Set name, format (League/Knockout/Group), date range, entry fee |
| Team Registration | Approve team entries, manage waitlists |
| AI Fixture Generator | Generate balanced fixture lists with AI planner |
| Logistics Panel | Drag-and-drop rescheduling before publication |
| Referee Assignment | Assign registered referees to specific fixtures |
| Results Finalization | Approve referee reports → standings auto-update |
| Standings & Stats | Real-time tables, scorers, assisters, cards |

---

### 🏟️ 8. Field Owner — `FieldOwnerDashboard`

| Feature | Details |
|---------|---------|
| Field Listings | Create fields with images, turf type, location, hourly rates |
| Booking Calendar | Color-coded interactive calendar (Pending / Confirmed / Blocked) |
| Slot Editor | Block time slots for maintenance or manual matches |
| Daily Grid Generator | Generate all booking slots for a day in one tap |
| Analytics Dashboard | Occupancy rates, monthly earnings, booking trends (fl_chart) |
| Payment Tracking | Track Kaspi QR and Stripe payments per booking |

---

### 🏁 9. Referee

| Feature | Details |
|---------|---------|
| Live Game Center | Enter live stats: goals, cards, injuries, substitutions |
| Match Reports | Submit official post-game logs to organizers |
| Fixture List | View assigned matches and locations |

---

### 🔎 10. Scout

| Feature | Details |
|---------|---------|
| Talent Database | Search youth/adult players with filters |
| Filters | Position, height, weight, dominant foot, performance metrics |
| Player Profiles | View detailed stats and match history |

---

### 👑 11. Admin

| Feature | Details |
|---------|---------|
| User Management | View, edit, and modify all user roles globally |
| Database Maintenance | Trigger migrations, seeds, and schema updates |
| System Logs | View global event logs and error reports |
| Role Override | Reassign or revoke any user role |

---

## 🛠️ Technology Stack

### Mobile (Flutter)

| Library | Version | Purpose |
|---------|---------|---------|
| `flutter` | 3.x | Core framework |
| `provider` | ^6.0.5 | State management |
| `dio` | ^5.3.0 | HTTP client with interceptors |
| `flutter_secure_storage` | ^9.0.0 | JWT token secure storage |
| `flutter_map` | ^8.3.0 | Interactive map (CartoDB Dark Matter tiles) |
| `latlong2` | ^0.9.1 | Geo-coordinate handling |
| `fl_chart` | ^0.68.0 | Analytics charts |
| `flutter_animate` | ^4.5.2 | Smooth micro-animations |
| `google_fonts` | ^6.1.0 | Typography (Outfit, Inter) |
| `cached_network_image` | ^3.3.0 | Image caching |
| `image_picker` | ^1.0.4 | Camera/gallery upload |
| `intl` | ^0.19.0 | Date/time formatting |
| `timeago` | ^3.5.0 | Relative time strings |
| `url_launcher` | ^6.3.2 | External links (Kaspi, Stripe) |
| `shared_preferences` | ^2.2.0 | Local settings storage |
| `json_annotation` + `json_serializable` | ^4.9 / ^6.7 | JSON model generation |

### Backend (Python / FastAPI)

| Technology | Purpose |
|-----------|---------|
| **FastAPI** | High-performance async REST API |
| **SQLAlchemy ORM** | Database modeling & queries |
| **PostgreSQL** | Production database |
| **Pydantic v2** | Request/response validation |
| **python-jose** | JWT token generation & validation |
| **passlib (bcrypt)** | Password hashing |
| **Stripe SDK** | Payment processing & webhook handling |
| **nginx** | Reverse proxy & TLS termination |
| **uvicorn** | ASGI server |
| **systemd** | Process management (orleon-backend.service) |

### Infrastructure

| Component | Technology |
|-----------|-----------|
| Deployment | VPS (Ubuntu) — `207.154.222.151` |
| Process Manager | `systemctl` via `orleon-backend.service` |
| Reverse Proxy | nginx with CORS headers |
| Media Storage | Local `/uploads` directory served via nginx |
| Payments | Stripe (international) + Kaspi QR (Kazakhstan) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│          Flutter Mobile App         │
│                                     │
│  ┌─────────┐  ┌──────────────────┐  │
│  │ Screens │  │    Providers     │  │
│  │ (UI)    │◄─┤  (State Mgmt)   │  │
│  └────┬────┘  └────────┬─────────┘  │
│       │                │            │
│       └────────────────┘            │
│              │ Dio HTTP             │
└──────────────┼──────────────────────┘
               │
        ┌──────▼──────┐
        │    nginx    │   (Reverse Proxy)
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │   FastAPI   │   (REST API)
        │             │
        │ ┌─────────┐ │
        │ │ Routers │ │   /auth, /clubs, /teams,
        │ │ Models  │ │   /tournaments, /fields,
        │ │ Schemas │ │   /bookings, /quizzes...
        │ └─────────┘ │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │ PostgreSQL  │   (Production DB)
        └─────────────┘
```

---

## 📦 Backend API Modules

| Module | Prefix | Key Endpoints |
|--------|--------|---------------|
| `auth` | `/auth` | Register, login, refresh token, onboarding |
| `users` | `/users` | Profile, role info, child link, club resolution |
| `clubs` | `/clubs` | CRUD clubs, invite staff, manage academies |
| `club_teams` | `/clubs/teams` | Create teams, assign coaches, manage rosters |
| `teams` | `/teams` | Team details, player assignment, jersey numbers |
| `academies` | `/academies` | Academy CRUD, branch management, enrollment |
| `tournaments` | `/tournaments` | Tournament CRUD, division management, fixtures |
| `matches` | `/matches` | Match events, live logging, results |
| `fields` | `/fields` | Field listings, slot management, booking calendar |
| `bookings` | `/bookings` | Create/confirm/cancel bookings, Stripe/Kaspi flow |
| `quizzes` | `/quizzes` | Daily quiz CRUD, answer submission, leaderboard |
| `notifications` | `/notifications` | List, mark-read, paginated history |
| `stats` | `/stats` | Player stats, team standings, top scorers |
| `scouting` | `/scouting` | Talent search with filters |
| `media` | `/media` | Image upload/serve |
| `pickup` | `/pickup` | Casual pickup game creation & joining |
| `planner` | `/planner` | AI tournament fixture generation |
| `scheduler` | `/scheduler` | Training session scheduling |

---

## 📱 Mobile App Structure

```
lib/
├── core/
│   ├── providers/         # Global providers (AuthProvider, NotificationProvider...)
│   ├── services/          # DioClient, ApiEndpoints
│   └── router/            # RoleRouter — redirects by user role
│
└── features/
    ├── auth/              # Login, Register, Onboarding
    ├── dashboard/         # Role-specific dashboard shells
    ├── profile/           # User profile, settings, logout
    ├── clubs/             # Club management (owner/manager views)
    ├── teams/             # Team screens, squad management
    ├── academies/         # Academy CRM, enrollment, billing
    ├── tournaments/       # Tournament creation, fixtures, standings
    ├── matches/           # Live match events, reports
    ├── fields/            # Field listing, booking calendar
    ├── bookings/          # Booking flow, payment screens
    ├── children/          # Child profile, parent linking
    ├── coaches/           # Coach views, attendance journal
    ├── players/           # Player profiles, stats
    ├── player_stats/      # Detailed stat views
    ├── squads/            # Squad assignment
    ├── lineups/           # Match lineup builder
    ├── match_reports/     # Post-game report submission
    ├── notifications/     # Notification center
    ├── football_hub/      # Youth quiz, streaks, leaderboard
    ├── quiz/              # Quiz screens
    ├── stats/             # Analytics & chart views
    ├── media/             # Image upload flows
    ├── onboarding/        # First-time user setup
    ├── settings/          # App settings
    └── admin/             # Admin panel
```

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK `≥ 3.7.0`
- Dart SDK `≥ 3.0`
- Python `≥ 3.10`
- PostgreSQL `≥ 14` (or use SQLite for local dev)
- Android Studio / Xcode for device testing

---

### 1. Backend Setup

```bash
# Navigate to backend
cd backend

# Create & activate virtual environment
python -m venv venv
source venv/bin/activate        # Linux/macOS
venv\Scripts\activate           # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment (see section below)
cp .env.example .env
# Edit .env with your values

# Run database migrations / seed (optional)
python seed.py

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Production (systemd):**
```bash
sudo systemctl start orleon-backend
sudo systemctl status orleon-backend
```

---

### 2. Mobile App Setup

```bash
# From project root — install packages
flutter pub get

# Generate JSON serializers
dart run build_runner build --delete-conflicting-outputs

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

---

## 🔐 Environment Variables

### Backend (`backend/.env`)

```env
# Database
DATABASE_URL=postgresql://user:password@localhost/orleon_db

# Security
SECRET_KEY=your_secure_jwt_secret_key_min_32_chars
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Stripe (optional)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Google AI (tournament planner)
GOOGLE_AI_API_KEY=your_gemini_api_key
```

### Mobile (`/.env`)

```env
API_BASE_URL=http://207.154.222.151
```

---

## 🛡️ Security & State Management

### Authentication Flow
1. User logs in → backend returns JWT access token
2. Token stored in `flutter_secure_storage` (hardware-backed on device)
3. `DioClient` injects `Authorization: Bearer <token>` on every request
4. Token refresh handled transparently via Dio interceptor

### Role Resolution
- Backend decodes JWT → extracts `role` claim
- `RoleRouter` in Flutter reads role from `AuthProvider` → redirects to correct dashboard
- All API endpoints enforce role-based permissions server-side

### Memory Isolation on Logout
```dart
// AuthProvider.logout()
for (final callback in _onLogoutCallbacks) {
  callback(); // clears ClubProvider, TeamProvider, ChildProvider, NotificationProvider
}
await _storage.deleteAll();
```

### CORS & Proxy
- nginx configured with `Access-Control-Allow-Origin` for API consumers
- All traffic proxied through nginx (port 80 → uvicorn port 8000)

---

## 📊 Database Models (Key Entities)

| Model | Key Fields |
|-------|-----------|
| `User` | id, email, role, unique_code, points, deystrik |
| `Club` | id, name, owner_id, logo_url, description |
| `Team` | id, name, club_id, coach_id |
| `Academy` | id, name, club_id, monthly_fee |
| `Tournament` | id, name, format, organizer_id, status |
| `Match` | id, tournament_id, home_team_id, away_team_id, date |
| `Field` | id, name, owner_id, location, hourly_rate |
| `Booking` | id, field_id, user_id, slot_start, slot_end, status, payment_method |
| `ChildProfile` | id, user_id, parent_id, club_name, unique_code |
| `QuizQuestion` | id, question, options, correct_answer, points |
| `Notification` | id, user_id, type, title, message, is_read |
| `PlayerStat` | id, user_id, match_id, goals, assists, yellow_cards, red_cards |

---

*Built with ❤️ for the global sports community — OrleOn, 2026*
