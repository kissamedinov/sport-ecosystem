# Import all models for SQLAlchemy registry compilation
from app.users import models as user_models
from app.teams import models as team_models
from app.tournaments import models as tournament_models
from app.matches import models as match_models
from app.bookings import models as booking_models
from app.fields import models as field_models
from app.clubs import models as club_models_system
from app.academies import models as academy_models
from app.club_teams import models as club_teams_models
from app.pickup import models as pickup_models
from app.scouting import models as scouting_models
from app.stats import models as stats_models
from app.media import models as media_models
from app.notifications import models as notification_models
from app.quizzes import models as quiz_models
from app.planner import models as planner_models

from app.database import SessionLocal
from app.quizzes.models import DailyQuiz
from app.quizzes.services import get_astana_date

db = SessionLocal()
today = get_astana_date()
quizzes = db.query(DailyQuiz).filter(DailyQuiz.date == today).all()
cnt = len(quizzes)
for q in quizzes:
    db.delete(q)
db.commit()
print(f"Deleted today's daily quizzes ({today}) with ORM delete: {cnt}")
db.close()
