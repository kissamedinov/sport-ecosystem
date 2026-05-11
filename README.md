# OrleOn - Sports Ecosystem Platform 🏆

OrleOn is a comprehensive platform designed to manage the entire lifecycle of sports organizations, tournaments, and field management. It bridge the gap between organizers, clubs, coaches, parents, and players.

## 🌟 Key Features

### 🏟️ Field & Booking Management
- **Automatic Slot Generation:** Field owners can generate a daily grid of time slots in one click.
- **Real-time Booking:** Prevent overlaps and manage field logistics seamlessly.
- **Smart Cancellations:** Integrated cancellation logic with automated slot release and notifications.

### 🏆 Tournament Management 2.0
- **AI-Enhanced Scheduling:** AI generates draft schedules for **League**, **Knockout**, and **Group Stage** formats.
- **Organizer Review Flow:** Review AI drafts, swap teams manually, and finalize once ready.
- **Automated Standings:** Real-time updates of league tables and player statistics (goals, assists, cards).
- **Squad Rosters:** Manage team squads, jersey numbers, and positions.

### 🎓 Academy CRM
- **Training Cycles:** Recurring schedules with automatic session generation.
- **Attendance Tracking:** Modern interface for coaches to track player presence.
- **Billing & Subscriptions:** Automated calculation of monthly fees based on attendance.
- **Academy Rankings:** Performance-based ranking system for youth academies.

### 📱 Mobile Experience (Flutter)
- **Role-Based Dashboards:** Unique views for Club Owners, Coaches, Parents, Players, and Organizers.
- **Premium Design:** Neon-accented UI with support for dark mode and smooth transitions.
- **Notifications:** Integrated inbox for match updates, invitations, and booking approvals.

## 🛠️ Technology Stack

- **Backend:** Python 3.10+, FastAPI, SQLAlchemy, PostgreSQL/SQLite.
- **Mobile:** Flutter 3.x, Provider for state management.
- **AI Integration:** Heuristic algorithms for optimal match scheduling and group balancing.

## 🚀 Getting Started

### Backend Setup
1. `cd backend`
2. `pip install -r requirements.txt`
3. `uvicorn app.main:app --reload`

### Mobile Setup
1. `flutter pub get`
2. `flutter run`

## 👥 Roles & Access
- **Club Owner:** Manage academies, teams, and staff.
- **Coach:** Manage squads, report match results, track attendance.
- **Parent:** Track child activity and manage payments.
- **Tournament Organizer:** Create series, manage registrations, and generate AI schedules.

---
*Built with ❤️ for the sports community.*
