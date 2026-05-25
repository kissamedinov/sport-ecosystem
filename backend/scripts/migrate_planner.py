"""Migration: create coach_tasks table"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.database import engine
from sqlalchemy import text

SQL = """
CREATE TABLE IF NOT EXISTS coach_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    time VARCHAR,
    category VARCHAR NOT NULL DEFAULT 'TRAINING',
    date DATE NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coach_tasks_coach_date ON coach_tasks(coach_id, date);
"""

with engine.begin() as conn:
    conn.execute(text(SQL))
    print("coach_tasks table created successfully")
