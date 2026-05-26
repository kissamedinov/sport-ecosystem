"""
Диагностика и исправление привязки CLUB_MANAGER к клубу.
Использование: python scripts/fix_club_manager.py [email менеджера]
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal
from app.users.models import User, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus
import uuid

db = SessionLocal()

# --- Найти менеджеров ---
manager_email = sys.argv[1] if len(sys.argv) > 1 else None

if manager_email:
    managers = db.query(User).filter(User.email == manager_email).all()
else:
    manager_role_users = db.query(UserRole).filter(UserRole.role == Role.CLUB_MANAGER).all()
    managers = [db.query(User).filter(User.id == ur.user_id).first() for ur in manager_role_users]

print(f"\n{'='*60}")
print(f"Найдено менеджеров: {len(managers)}")
print(f"{'='*60}\n")

for user in managers:
    if not user:
        continue
    print(f"Пользователь: {user.name} ({user.email}) [id={user.id}]")

    # Проверить ClubStaff
    staff_entries = db.query(ClubStaff).filter(ClubStaff.user_id == user.id).all()
    if staff_entries:
        for s in staff_entries:
            club = db.query(Club).filter(Club.id == s.club_id).first()
            print(f"  ✓ ClubStaff: клуб={club.name if club else s.club_id}, роль={s.role}, статус={s.status}")
    else:
        print(f"  ✗ ClubStaff: ЗАПИСЬ ОТСУТСТВУЕТ — пользователь не привязан к клубу")

        # Найти клубы для предложения
        clubs = db.query(Club).all()
        if clubs:
            print(f"\n  Доступные клубы:")
            for i, c in enumerate(clubs):
                print(f"    [{i}] {c.name} (id={c.id})")

            choice = input(f"\n  Привязать {user.name} к клубу? Введите номер или Enter для пропуска: ").strip()
            if choice.isdigit() and int(choice) < len(clubs):
                club = clubs[int(choice)]

                # Проверить нет ли уже записи
                existing = db.query(ClubStaff).filter(
                    ClubStaff.club_id == club.id,
                    ClubStaff.user_id == user.id
                ).first()

                if existing:
                    existing.status = ClubMembershipStatus.ACTIVE
                    existing.role = ClubRole.MANAGER
                    print(f"  → Обновлена существующая запись ClubStaff")
                else:
                    db.add(ClubStaff(
                        id=uuid.uuid4(),
                        club_id=club.id,
                        user_id=user.id,
                        role=ClubRole.MANAGER,
                        status=ClubMembershipStatus.ACTIVE
                    ))
                    print(f"  → Создана запись ClubStaff: {user.name} → {club.name}")

                db.commit()
                print(f"  ✓ Сохранено!")
        else:
            print("  Нет доступных клубов в базе.")
    print()

db.close()
print("Готово.")
