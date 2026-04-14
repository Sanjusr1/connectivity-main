from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import database
from app.models import models
from app.schemas import schemas
from app.services import auth

router = APIRouter(prefix="/devices", tags=["devices"])

@router.post("/", response_model=schemas.Device)
def register_device(device: schemas.DeviceCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    db_device = db.query(models.Device).filter(models.Device.device_id == device.device_id).first()
    if db_device:
        raise HTTPException(status_code=400, detail="Device ID already registered")
    
    new_device = models.Device(
        device_id=device.device_id,
        name=device.name,
        owner_id=current_user.id
    )
    db.add(new_device)
    db.commit()
    db.refresh(new_device)
    return new_device

@router.get("/", response_model=List[schemas.Device])
def get_devices(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.Device).filter(models.Device.owner_id == current_user.id).all()
