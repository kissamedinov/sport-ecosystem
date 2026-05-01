import asyncio
from sqlalchemy import text
from app.database import SessionLocal, engine

def run_migration():
    db = SessionLocal()
    try:
        print("Starting migration from academy_teams to teams...")

        # 1. Migrate AcademyTeam to Team
        # Insert all academy_teams into teams if they don't exist
        # We need to map academy_teams to teams. We can just create new teams.
        # But wait, it's easier to just recreate them or tell the user to recreate.
        # If the user has live data, we should migrate.
        
        sql_migrate_teams = """
        INSERT INTO teams (id, academy_id, name, age_category, coach_id, created_at, updated_at, is_active)
        SELECT id, academy_id, name, age_group, coach_id, created_at, updated_at, true
        FROM academy_teams
        ON CONFLICT (id) DO NOTHING;
        """
        db.execute(text(sql_migrate_teams))
        print("Migrated academy_teams to teams.")

        # 2. Migrate AcademyTeamPlayer to TeamMembership
        sql_migrate_players = """
        INSERT INTO team_memberships (id, team_id, player_profile_id, joined_at, role, status, join_status)
        SELECT id, team_id, player_profile_id, joined_at, 'PLAYER', 'ACTIVE', 'APPROVED'
        FROM academy_team_players
        ON CONFLICT (id) DO NOTHING;
        """
        db.execute(text(sql_migrate_players))
        print("Migrated academy_team_players to team_memberships.")

        # 3. Update association tables to point to teams instead of academy_teams
        # Actually, if we kept the same IDs (inserted academy_teams.id as teams.id),
        # the foreign keys in training_session_teams and training_schedule_teams 
        # might still be pointing to academy_teams. We need to drop those constraints and point them to teams.
        
        # PostgreSQL constraint manipulation
        # For training_session_teams
        try:
            db.execute(text("ALTER TABLE training_session_teams DROP CONSTRAINT IF EXISTS training_session_teams_team_id_fkey CASCADE;"))
            db.execute(text("ALTER TABLE training_session_teams ADD CONSTRAINT training_session_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;"))
        except Exception as e:
            print(f"Error updating training_session_teams constraint: {e}")

        # For training_schedule_teams
        try:
            db.execute(text("ALTER TABLE training_schedule_teams DROP CONSTRAINT IF EXISTS training_schedule_teams_team_id_fkey CASCADE;"))
            db.execute(text("ALTER TABLE training_schedule_teams ADD CONSTRAINT training_schedule_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;"))
        except Exception as e:
            print(f"Error updating training_schedule_teams constraint: {e}")

        print("Updated foreign key constraints.")

        db.commit()
        print("Migration completed successfully!")

    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
