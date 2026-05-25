from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import date

from app.database import get_db
from app.planner import models, schemas
from app.users.models import User
from app.common.dependencies import get_current_user

router = APIRouter(prefix="/planner", tags=["Planner"])


@router.get("/tasks", response_model=List[schemas.TaskOut])
def get_tasks(
    date: date,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(models.CoachTask)
        .filter(
            models.CoachTask.coach_id == current_user.id,
            models.CoachTask.date == date,
        )
        .order_by(models.CoachTask.created_at)
        .all()
    )


@router.post("/tasks", response_model=schemas.TaskOut)
def create_task(
    body: schemas.TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = models.CoachTask(
        coach_id=current_user.id,
        title=body.title,
        time=body.time,
        category=body.category,
        date=body.date,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/tasks/{task_id}", response_model=schemas.TaskOut)
def toggle_task(
    task_id: UUID,
    body: schemas.TaskToggle,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(models.CoachTask)
        .filter(
            models.CoachTask.id == task_id,
            models.CoachTask.coach_id == current_user.id,
        )
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.done = body.done
    db.commit()
    db.refresh(task)
    return task


@router.delete("/tasks/{task_id}")
def delete_task(
    task_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(models.CoachTask)
        .filter(
            models.CoachTask.id == task_id,
            models.CoachTask.coach_id == current_user.id,
        )
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return {"message": "deleted"}
