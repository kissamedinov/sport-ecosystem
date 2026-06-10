import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

# We need to find which DB is used.
db_url = os.getenv("DATABASE_URL", "sqlite:///sport_ecosystem.db")
print(f"Connecting to: {db_url}")

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        # Check daily_quizzes table
        res = conn.execute(text("SELECT * FROM daily_quizzes ORDER BY date DESC LIMIT 10"))
        quizzes = res.fetchall()
        print(f"\nLast 10 Daily Quizzes (total: {len(quizzes)}):")
        for q in quizzes:
            # Let's count questions for this quiz
            q_id = q[0] # assuming first col is ID
            # SQLite / Postgres column names might differ, let's select by index or inspect structure
            print(q)
            qres = conn.execute(text(f"SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = '{q_id}'"))
            cnt = qres.scalar()
            print(f"Quiz ID: {q_id}, Date: {q[1] if len(q) > 1 else '?'}, Audience: {q[2] if len(q) > 2 else '?'}, Questions Count: {cnt}")
except Exception as e:
    print(f"Error: {e}")
