from app.database import Base, engine
from sqlalchemy import inspect

inspector = inspect(engine)
tables = inspector.get_table_names()
print("Tables in DB:")
for t in sorted(tables):
    print(f"  {t}")
