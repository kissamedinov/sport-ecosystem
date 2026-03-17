import os

base_dir = r"c:\Users\Asus\Desktop\test\mobile"

# Backend
backend_dirs = [
    "backend/app/auth",
    "backend/app/users",
    "backend/app/teams",
    "backend/app/tournaments",
    "backend/app/matches",
    "backend/app/fields",
    "backend/app/bookings",
    "backend/app/notifications",
    "backend/app/scheduler",
    "backend/app/common",
]

for d in backend_dirs:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)
    # create __init__.py
    with open(os.path.join(base_dir, d, "__init__.py"), "w") as f:
        pass

# backend files
backend_files = {
    "backend/app/__init__.py": "",
    "backend/app/common/__init__.py": "",
    "backend/app/common/dependencies.py": "# Dependencies\n",
    "backend/app/common/permissions.py": "# Permissions\n",
    "backend/app/common/exceptions.py": "# Exceptions\n",
    "backend/app/common/config.py": "# Config\n",
    "backend/app/database.py": "# Database connection\n",
    "backend/app/main.py": '''from fastapi import FastAPI\n\napp = FastAPI(title="Sports Ecosystem API")\n\n@app.get("/")\ndef read_root():\n    return {"message": "Welcome to the Sports Ecosystem API"}\n''',
    "backend/requirements.txt": "fastapi\nuvicorn\nsqlalchemy\npsycopg2-binary\n",
}

for f, content in backend_files.items():
    with open(os.path.join(base_dir, f), "w") as file:
        file.write(content)

# Mobile
mobile_features = [
    "auth",
    "teams",
    "tournaments",
    "matches",
    "fields",
    "notifications",
    "profile"
]

for feature in mobile_features:
    for sub in ["data/models", "data/repositories", "presentation/screens", "presentation/widgets", "providers"]:
        os.makedirs(os.path.join(base_dir, f"mobile/lib/features/{feature}/{sub}"), exist_ok=True)
        # Add a dummy file to ensure empty folders are preserved if needed (like in git), though the prompt says "empty modules / folders"
        with open(os.path.join(base_dir, f"mobile/lib/features/{feature}/{sub}", ".placeholder"), "w") as f:
            f.write("")

mobile_core_dirs = [
    "mobile/lib/core/api",
    "mobile/lib/core/constants",
    "mobile/lib/core/theme"
]

for d in mobile_core_dirs:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)
    with open(os.path.join(base_dir, d, ".placeholder"), "w") as f:
        f.write("")

mobile_files = {
    "mobile/pubspec.yaml": "name: sports_ecosystem\ndescription: A new Flutter project.\nversion: 1.0.0+1\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\n",
    "mobile/lib/main.dart": '''import 'package:flutter/material.dart';\n\nvoid main() {\n  runApp(const MyApp());\n}\n\nclass MyApp extends StatelessWidget {\n  const MyApp({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    return MaterialApp(\n      title: 'Sports Ecosystem',\n      theme: ThemeData(\n        primarySwatch: Colors.blue,\n      ),\n      home: const Scaffold(\n        body: Center(\n          child: Text('Welcome to Sports Ecosystem'),\n        ),\n      ),\n    );\n  }\n}\n''',
}

for f, content in mobile_files.items():
    os.makedirs(os.path.dirname(os.path.join(base_dir, f)), exist_ok=True)
    with open(os.path.join(base_dir, f), "w") as file:
        file.write(content)

readme_content = """# Sports Ecosystem Platform

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
   source venv/bin/activate  # On Windows: venv\\Scripts\\activate
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

1. Navigate to the `mobile` directory:
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
"""

with open(os.path.join(base_dir, "README.md"), "w") as file:
    file.write(readme_content)

print("Scaffolding complete.")
