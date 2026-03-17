import sys
import os
from sqlalchemy.orm import Session

# Add project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal, engine, Base
from app.users.models import Permission, RolePermission, Role

import traceback

def seed_permissions():
    with open("seed_debug_log.txt", "w") as log:
        log.write("Starting seed_permissions...\n")
        db = SessionLocal()
        try:
            # 1. Define Permissions
            permissions_data = [
                ("CREATE_TOURNAMENT", "Can create new tournaments"),
                ("EDIT_TOURNAMENT", "Can edit tournament details"),
                ("GENERATE_SCHEDULE", "Can trigger match schedule generation"),
                ("REGISTER_TEAM", "Can register a team in a tournament"),
                ("SUBMIT_LINEUP", "Can submit match lineups"),
                ("EDIT_MATCH_STATS", "Can edit player statistics for a match"),
                ("CREATE_FIELD", "Can create new sports fields"),
                ("EDIT_FIELD", "Can edit field details"),
                ("APPROVE_BOOKING", "Can approve or reject field bookings"),
                ("VIEW_BOOKINGS", "Can view all bookings"),
                ("VIEW_CHILD_STATS", "Can view stats of children"),
                ("VIEW_CHILD_ATTENDANCE", "Can view attendance of children"),
                ("VIEW_TEAM_PLAYERS", "Can view team roster details"),
            ]
            
            perm_objs = {}
            for name, desc in permissions_data:
                perm = db.query(Permission).filter(Permission.name == name).first()
                if not perm:
                    perm = Permission(name=name, description=desc)
                    db.add(perm)
                    db.flush()
                perm_objs[name] = perm
            
            log.write(f"Loaded {len(perm_objs)} permissions\n")
                
            # 2. Define Role-Permission Mappings
            mappings = {
                Role.ADMIN: [p[0] for p in permissions_data],
                Role.TOURNAMENT_MANAGER: [
                    "CREATE_TOURNAMENT", "EDIT_TOURNAMENT", "GENERATE_SCHEDULE", "EDIT_MATCH_STATS"
                ],
                Role.REFEREE: ["EDIT_MATCH_STATS"],
                Role.COACH: ["CREATE_TOURNAMENT", "REGISTER_TEAM", "SUBMIT_LINEUP", "VIEW_TEAM_PLAYERS"],
                Role.PARENT: ["VIEW_CHILD_STATS", "VIEW_CHILD_ATTENDANCE"],
                Role.FIELD_OWNER: [
                    "CREATE_FIELD", "EDIT_FIELD", "APPROVE_BOOKING", "VIEW_BOOKINGS"
                ],
            }
            
            for role, perms in mappings.items():
                log.write(f"Seeding role: {role.value}\n")
                for p_name in perms:
                    perm = perm_objs.get(p_name)
                    if not perm:
                        continue
                    
                    try:
                        exists = db.query(RolePermission).filter(
                            RolePermission.role == role,
                            RolePermission.permission_id == perm.id
                        ).first()
                        
                        if not exists:
                            rp = RolePermission(role=role, permission_id=perm.id)
                            db.add(rp)
                    except Exception as e:
                        log.write(f"FAILED on perm {p_name} for role {role.value}\n")
                        traceback.print_exc(file=log)
                        raise
                db.commit() # Commit after each role
            
            log.write("Permissions seeded successfully!\n")
            
        except Exception as e:
            log.write(f"Global error: {e}\n")
            traceback.print_exc(file=log)
            db.rollback()
        finally:
            db.close()

if __name__ == "__main__":
    seed_permissions()
