
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)

try:
    with engine.connect() as conn:
        print("Migrating 'tournaments' table...")
        # Add whatsapp
        try:
            conn.execute(text("ALTER TABLE tournaments ADD COLUMN whatsapp VARCHAR;"))
            print("Added column 'whatsapp'")
        except Exception as e:
            print(f"Column 'whatsapp' might already exist or error: {e}")
            
        # Add phone
        try:
            conn.execute(text("ALTER TABLE tournaments ADD COLUMN phone VARCHAR;"))
            print("Added column 'phone'")
        except Exception as e:
            print(f"Column 'phone' might already exist or error: {e}")
            
        conn.commit()
        print("Migration SUCCESSFUL!")

except Exception as e:
    print(f"Migration FAILED: {e}")
