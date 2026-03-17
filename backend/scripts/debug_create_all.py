from app.database import engine, Base
import app.tournaments.models # important to load all models
import traceback
import sys

def debug_create_all():
    print("Attempting to run Base.metadata.create_all and capture error...")
    try:
        Base.metadata.create_all(bind=engine)
        print("create_all completed (ostensibly)")
    except Exception as e:
        print("CAUGHT ERROR:")
        traceback.print_exc()
        with open("create_all_error.log", "w") as f:
            traceback.print_exc(file=f)

if __name__ == "__main__":
    debug_create_all()
