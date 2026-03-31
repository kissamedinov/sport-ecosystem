# Sports Ecosystem Platform

This platform manages tournaments, teams, matches, field rentals, bookings, and notifications.

## Project Structure

- `backend/`: FastAPI Python Backend.
- `mobile/`: Flutter App.

## How to run Backend

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Create a virtual environment (optional but recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the server:
   ```bash
   uvicorn app.main:app --reload
   ```
   The API will be available at `http://127.0.0.1:8000`.

## How to run Flutter App

1. Navigate to the `mobile` (or whatever you named the main folder) directory:
   ```bash
   cd mobile
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
   (Make sure you have an Android/iOS emulator running or a device connected).
