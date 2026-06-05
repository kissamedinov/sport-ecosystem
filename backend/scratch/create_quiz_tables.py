from app.database import engine, Base
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models
import app.tournaments.models
import app.matches.models
import app.quizzes.models

print("Creating quiz tables on the local database...")
Base.metadata.create_all(bind=engine)
print("Tables created successfully!")
