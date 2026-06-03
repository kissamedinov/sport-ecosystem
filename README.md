# OrleOn - Sports Ecosystem Platform 🏆⚽

**OrleOn** is a next-generation sports management platform designed to orchestrate the entire lifecycle of sports organizations, tournaments, academies, and field bookings. It bridges the gap between tournament organizers, club owners, coaches, scouts, referees, parents, adult players, and youth players through role-specific workflows and a premium neon-accented dark interface.

---

## 🌟 Core Ecosystem Features ("The Doodads & Gizmos")

### 🏟️ Interactive Map & Arena Booking
*   **Custom Dark Map Tiles:** Uses `flutter_map` styled with **CartoDB Dark Matter** tiles, seamlessly blending maps into the premium dark-themed UI.
*   **Kaspi QR & Stripe Payments:** Integrated payment options allow local users to pay via Kaspi QR and international users to utilize Stripe Checkout (with webhook verification for automatic booking status transitions).
*   **Daily Grid Slot Generator:** Field owners can generate a daily calendar grid of booking slots in a single tap.
*   **Automated Cancellations:** Releasing a booking automatically frees up the slot and notifies affected players.

### 🏆 AI-Powered Tournament Engine 2.0
*   **AI Match Planner:** Heuristic algorithms automatically balance divisions, assign group stages, and generate fixture drafts (League, Knockout, Group Stage).
*   **Logistics Review Panel:** Interactive dashboard allowing tournament managers to drag, drop, reschedule, and swap team fixtures before final publication.
*   **Real-time Statistics:** Automated computation of standings, goal differences, top scorers, top assist makers, and card counts.

### 🎓 Academy CRM & Youth Gamification
*   **Recurring Training Cycles:** Generates automated training sessions with comprehensive attendance records.
*   **Dynamic Attendance Billing:** Automatically computes monthly academy fees for parents based on session attendance records.
*   **Youth Quiz & Rating System:** Children participate in daily quizzes, maintain active login streaks (`deystrik`), earn points (`points`), and climb the Youth Leaderboard (`rating`).

### 🛡️ State Security & Memory Isolation
*   **Global Reset on Logout:** When a user logs out, the system triggers `onLogoutCallbacks` in `AuthProvider` to clear cache data across all providers (`ClubProvider`, `TeamProvider`, `ChildProvider`, `NotificationProvider`), preventing cross-user data leakage.
*   **Dynamic Club Resolution:** Utilizes `get_user_club_name` on the backend to recursively resolve memberships across `ChildProfile`, `ClubStaff`, and owners, outputting "без клуба" if unassociated.

---

## 👥 Comprehensive Role-Based Workflows

OrleOn implements a strict Role-Based Access Control (RBAC) mechanism. Upon login, the `RoleRouter` automatically directs users to their dedicated dashboard:

### 1. 👟 Adult Player
*   **Dashboard:** `AdultPlayerDashboard`
*   **Key Capabilities:**
    *   **Tournament Tracker:** View upcoming matches, bracket progressions, standings, and personal stats.
    *   **Map Booking:** Find nearby football fields using the dark-matter interactive map, check availability, and book slots.
    *   **Kaspi & Stripe Checkout:** Pay securely for field bookings and tournament registrations.
    *   **Daily Quiz:** Answer daily questions to test football knowledge.

### 🧒 2. Youth Player (Child Profile)
*   **Dashboard:** `ChildPlayerDashboard`
*   **Key Capabilities:**
    *   **Football Hub:** Take daily quizzes, maintain daily streaks (`deystrik`), and earn `points`.
    *   **Youth Rankings:** Climb the leaderboard based on points and quiz participation (only children with a score > 0 are displayed).
    *   **Join Requests:** Accept parent-link invitations or club-academy invitations directly from the dashboard.
    *   **Training & Feedback:** View training schedules and read performance reviews submitted by coaches.

### 👪 3. Parent
*   **Dashboard:** `ParentDashboard`
*   **Key Capabilities:**
    *   **Child Linking:** Link child accounts using their unique player code (`unique_code`) or email.
    *   **Activity Monitoring:** Track physical metrics, training attendance logs, and game history.
    *   **Coach Feedback:** Read personal development notes and ratings left by team coaches.
    *   **Automated Billing:** Track monthly academy subscriptions and make payments via Stripe/Kaspi QR.

### 📋 4. Coach
*   **Dashboard:** `CoachDashboardScreen`
*   **Key Capabilities:**
    *   **Squad Management:** Assign player positions, jersey numbers, and manage squad lists.
    *   **Attendance Journal:** Log daily training attendance which feeds directly into parent billing.
    *   **Match Event Logger:** Log match details in real-time (substitutions, goals, assists, yellow/red cards).
    *   **Player Reviews:** Write qualitative feedback reports sent directly to parents.

### 🛡️ 5. Club Owner
*   **Dashboard:** `ClubDashboardScreen` (Owner View)
*   **Key Capabilities:**
    *   **Academy CRM:** Create academies, define branches, and manage core club properties.
    *   **Staff Hiring:** Invite and assign coaches, managers, and club administrators.
    *   **Financial Reports:** Track registrations, total active players, and academy membership payouts.

### ⚙️ 6. Club Manager
*   **Dashboard:** `ClubDashboardScreen` (Manager View)
*   **Key Capabilities:**
    *   **Operations Manager:** Oversee daily operations, approve branch updates, and schedule training cycles.
    *   **Roster Coordinator:** Handle team registrations for tournaments and leagues.

### 🏆 7. Tournament Organizer
*   **Dashboard:** `OrganizerDashboardScreen`
*   **Key Capabilities:**
    *   **Logistics Panel:** Create tournament structures, manage team entry fees, and publish AI schedule drafts.
    *   **Referees & Staff:** Assign registered referees to specific match fixtures.
    *   **Results Finalization:** Approve referee match reports to update standings automatically.

### 🏟️ 8. Field Owner
*   **Dashboard:** `FieldOwnerDashboard`
*   **Key Capabilities:**
    *   **Field Management:** Create field listings, upload images, specify turf types, and define hourly rates.
    *   **Interactive Calendar:** Color-coded slots visualize bookings (Pending, Confirmed, Blocked).
    *   **Slot Editor:** Block specific hours for maintenance or manual matches.
    *   **Owner Analytics:** Visual charts showing occupancy rates, monthly earnings, and booking trends.

### 🏁 9. Referee
*   **Key Capabilities:**
    *   **Live Game Center:** Enter game stats live, including card warnings, match goals, and injuries.
    *   **Match Reports:** Submit official post-game logs to organizers for standings confirmation.

### 🔎 10. Scout (Additional)
*   **Key Capabilities:**
    *   **Talent Database:** Search youth/adult databases filtering by position, height, weight, dominant foot, and match performance.

### 👑 11. Admin (Additional)
*   **Key Capabilities:**
    *   **System Admin:** Global user control, database maintenance, role modifications, and global log views.

---

## 🛠️ Technology Stack

*   **Frontend (Mobile):** Flutter 3.x, Provider state management, Dio HTTP Client, CartoDB/flutter_map, fl_chart, flutter_animate.
*   **Backend (Server):** FastAPI (Python 3.10+), SQLAlchemy ORM, PostgreSQL (production) / SQLite (development).
*   **Payments & APIs:** Stripe Payment SDK, Kaspi QR, Google Generative AI API (for match scheduling assistance).

---

## 🚀 Setting Up the Project

### 1. Backend Setup
1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Set up a virtual environment:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  Configure the environment variables in `backend/.env`:
    ```env
    DATABASE_URL=postgresql://user:password@localhost/dbname
    SECRET_KEY=your_secure_jwt_secret_key
    ```
5.  Run database seeds/migrations (optional):
    ```bash
    python seed.py
    ```
6.  Start the development server:
    ```bash
    uvicorn app.main:app --reload
    ```

### 2. Mobile App Setup
1.  Navigate to the root directory and get packages:
    ```bash
    flutter pub get
    ```
2.  Build JSON serializers:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  Run the application:
    ```bash
    flutter run
    ```

---
*Built with ❤️ for the global sports community.*
