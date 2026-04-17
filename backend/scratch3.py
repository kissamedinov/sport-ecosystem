from backend.app.academies.models import TrainingSchedule, AcademyTeam
from backend.app.academies.schemas import TrainingScheduleResponse
from datetime import time
from common.models import DayOfWeek
import uuid

# Mock a TrainingSchedule object
team1 = AcademyTeam(id=uuid.uuid4(), name="Team 1")
team2 = AcademyTeam(id=uuid.uuid4(), name="Team 2")
schedule = TrainingSchedule(
    id=uuid.uuid4(),
    academy_id=uuid.uuid4(),
    day_of_week=DayOfWeek.MONDAY,
    start_time=time(18, 0),
    end_time=time(19, 30),
    teams=[team1, team2]
)

# Try to validate with Pydantic
response = TrainingScheduleResponse.model_validate(schedule)
print(f"Team IDs: {response.team_ids}")
assert len(response.team_ids) == 2
print("Verification successful!")
