
import uuid
import sys
import os
sys.path.append(os.getcwd())
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.clubs import services, schemas, models
from app.users.models import User
from app.clubs.models import Club

db = SessionLocal()
try:
    user = db.query(User).first()
    club = db.query(Club).first()
    if not user or not club:
        print("Required data (User or Club) missing!")
    else:
        print(f"Testing invitation for user: {user.id} to club: {club.id}")
        invite_in = schemas.InvitationCreate(
            invited_user_id=user.id,
            role=models.ClubRole.PLAYER,
            club_id=club.id
        )
        # We need an inviter ID (use the same user or someone else)
        inviter = db.query(User).filter(User.id != user.id).first()
        inviter_id = inviter.id if inviter else user.id
        
        print(f"Inviter: {inviter_id}")
        
        # This will call create_notification inside
        invite = services.create_invitation(db, invite_in, inviter_id)
        print(f"Success! Invitation ID: {invite.id}")
        
except Exception as e:
    print(f"Error occurred: {e}")
    import traceback; traceback.print_exc()
finally:
    db.close()
