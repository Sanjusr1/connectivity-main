from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.database import database
from app.models import models
from app.schemas import schemas
from app.services import auth

router = APIRouter(prefix="/sessions", tags=["sessions"])

@router.post("/", response_model=schemas.Session)
def create_session(session: schemas.SessionCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    # Verify device belongs to user
    device = db.query(models.Device).filter(models.Device.id == session.device_id, models.Device.owner_id == current_user.id).first()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found or not owned by user")
        
    db_session = models.Session(
        name=session.name,
        device_id=session.device_id
    )
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

@router.post("/{session_id}/end", response_model=schemas.Session)
def end_session(session_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    # Verify session and device ownership
    db_session = db.query(models.Session).join(models.Device).filter(
        models.Session.id == session_id,
        models.Device.owner_id == current_user.id
    ).first()
    
    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    if db_session.end_time:
        raise HTTPException(status_code=400, detail="Session already ended")
        
    db_session.end_time = datetime.utcnow()
    db.commit()
    db.refresh(db_session)
    return db_session

@router.get("/", response_model=List[schemas.Session])
def get_sessions(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.Session).join(models.Device).filter(models.Device.owner_id == current_user.id).all()

@router.post("/{session_id}/data", response_model=schemas.SensorData)
def add_sensor_data(session_id: int, stream: schemas.SensorDataCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    # Verify session and device ownership
    db_session = db.query(models.Session).join(models.Device).filter(
        models.Session.id == session_id,
        models.Device.owner_id == current_user.id
    ).first()
    
    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    if db_session.end_time:
        raise HTTPException(status_code=400, detail="Cannot add data to ended session")

    db_data = models.SensorData(
        session_id=session_id,
        **stream.model_dump()
    )
    db.add(db_data)
    db.commit()
    db.refresh(db_data)
    return db_data

@router.get("/{session_id}/data", response_model=List[schemas.SensorData])
def get_session_data(session_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    # Verify session and device ownership
    db_session = db.query(models.Session).join(models.Device).filter(
        models.Session.id == session_id,
        models.Device.owner_id == current_user.id
    ).first()
    
    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    return db.query(models.SensorData).filter(models.SensorData.session_id == session_id).all()
