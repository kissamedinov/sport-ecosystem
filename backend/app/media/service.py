import os
import uuid
import shutil
from fastapi import UploadFile, HTTPException
from sqlalchemy.orm import Session
from app.media.models import MediaItem, MediaType
from PIL import Image

UPLOAD_DIR = "uploads"
THUMB_DIR = "uploads/thumbnails"

# Ensure directories exist
for d in [UPLOAD_DIR, THUMB_DIR]:
    if not os.path.exists(d):
        os.makedirs(d)

def save_media_item(
    db: Session, 
    file: UploadFile, 
    media_type: MediaType,
    user_id: uuid.UUID = None,
    club_id: uuid.UUID = None,
    tournament_id: uuid.UUID = None
) -> MediaItem:
    # Generate unique filename
    ext = os.path.splitext(file.filename)[1].lower()
    filename = f"{uuid.uuid4()}{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # Save original file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    url = f"/uploads/{filename}"
    thumb_url = None

    # Generate thumbnail for images
    if ext in [".jpg", ".jpeg", ".png", ".webp"]:
        try:
            thumb_filename = f"thumb_{filename}"
            thumb_path = os.path.join(THUMB_DIR, thumb_filename)
            
            with Image.open(file_path) as img:
                img.thumbnail((200, 200))
                img.save(thumb_path)
            
            thumb_url = f"/uploads/thumbnails/{thumb_filename}"
        except Exception as e:
            print(f"Failed to generate thumbnail: {e}")

    # Create DB record
    media_item = MediaItem(
        user_id=user_id,
        club_id=club_id,
        tournament_id=tournament_id,
        type=media_type,
        url=url,
        thumbnail_url=thumb_url
    )
    db.add(media_item)
    db.commit()
    db.refresh(media_item)
    return media_item

def get_media_by_user(db: Session, user_id: uuid.UUID):
    return db.query(MediaItem).filter(MediaItem.user_id == user_id).all()

def get_media_by_club(db: Session, club_id: uuid.UUID):
    return db.query(MediaItem).filter(MediaItem.club_id == club_id).all()

def get_media_by_tournament(db: Session, tournament_id: uuid.UUID):
    return db.query(MediaItem).filter(MediaItem.tournament_id == tournament_id).all()

def delete_media_item(db: Session, media_id: uuid.UUID):
    media = db.query(MediaItem).filter(MediaItem.id == media_id).first()
    if not media:
        raise HTTPException(status_code=404, detail="Media item not found")
    
    # Delete files
    for path in [media.url, media.thumbnail_url]:
        if path:
            full_path = path.lstrip("/") # Convert URL to local path snippet
            if os.path.exists(full_path):
                os.remove(full_path)
    
    db.delete(media)
    db.commit()
    return {"message": "Media item deleted"}

def update_media_item(db: Session, media_id: uuid.UUID, type: MediaType):
    media = db.query(MediaItem).filter(MediaItem.id == media_id).first()
    if not media:
        raise HTTPException(status_code=404, detail="Media item not found")
    
    media.type = type
    db.commit()
    db.refresh(media)
    return media
