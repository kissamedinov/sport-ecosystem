import sys
import os

# Add the parent directory to sys.path so we can import from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL

def migrate():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    with engine.connect() as conn:
        print("Starting migration...")
        
        # 1. Add whatsapp and instagram to clubs
        try:
            conn.execute(text("ALTER TABLE clubs ADD COLUMN whatsapp VARCHAR;"))
            print("Added 'whatsapp' column to 'clubs'")
        except Exception as e:
            print(f"Column 'whatsapp' might already exist: {e}")

        try:
            conn.execute(text("ALTER TABLE clubs ADD COLUMN instagram VARCHAR;"))
            print("Added 'instagram' column to 'clubs'")
        except Exception as e:
            print(f"Column 'instagram' might already exist: {e}")

        # 2. Add join_status and child_profile_id to team_memberships
        try:
            # Need to define the enum type first if it doesn't exist
            # But let's use a simple varchar for flexibility in migrations
            conn.execute(text("ALTER TABLE team_memberships ADD COLUMN join_status VARCHAR DEFAULT 'APPROVED';"))
            print("Added 'join_status' column to 'team_memberships'")
        except Exception as e:
            print(f"Column 'join_status' might already exist: {e}")

        try:
            conn.execute(text("ALTER TABLE team_memberships ADD COLUMN child_profile_id UUID REFERENCES child_profiles(id);"))
            print("Added 'child_profile_id' column to 'team_memberships'")
        except Exception as e:
            print(f"Column 'child_profile_id' might already exist: {e}")

        conn.commit()
        print("Migration completed successfully.")

if __name__ == "__main__":
    migrate()
