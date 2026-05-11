import sys
import os

path = r'c:\Users\Asus\Desktop\test\mobile\backend\app\users\routes.py'
if not os.path.exists(path):
    print(f"Path not found: {path}")
    sys.exit(1)

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = '@router.get("/referees"'
replacement = """@router.get("/referees", response_model=List[schemas.UserResponse])
def get_referees(db: Session = Depends(get_db)):
    \"\"\"
    Returns a list of all users with the REFEREE role.
    \"\"\"
    try:
        from datetime import datetime
        referees = db.query(models.User).join(models.UserRole).filter(models.UserRole.role == models.Role.REFEREE).all()
        response = []
        for ref in referees:
            user_roles = [ur.role.value for ur in ref.roles]
            response.append({
                'id': ref.id,
                'name': ref.name or 'Referee',
                'email': ref.email,
                'roles': user_roles,
                'role': models.Role.REFEREE,
                'created_at': ref.created_at or datetime.now(),
                'date_of_birth': ref.date_of_birth,
                'phone': ref.phone,
                'onboarding_completed': bool(ref.onboarding_completed),
                'avatar_url': ref.avatar_url,
                'bio': ref.bio,
                'unique_code': ref.unique_code
            })
        return response
    except Exception as e:
        import traceback
        error_msg = f"ERROR: {e}\\n{traceback.format_exc()}"
        print(error_msg)
        raise HTTPException(status_code=500, detail=str(e))
"""

if start_marker in content:
    parts = content.split(start_marker)
    new_content = parts[0] + replacement + "\n"
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully updated")
else:
    print("Marker not found")
