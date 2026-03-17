try:
    from app.main import app
    from app.database import Base, engine
    print("App imported successfully. Attempting DB init...")
    Base.metadata.create_all(bind=engine)
    print("DB init successful")
except Exception:
    import traceback
    print("ERROR DURING INIT:")
    traceback.print_exc()
