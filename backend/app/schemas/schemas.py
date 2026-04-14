from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# User Schemas
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# Device Schemas
class DeviceBase(BaseModel):
    device_id: str
    name: str

class DeviceCreate(DeviceBase):
    pass

class Device(DeviceBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

# Sensor Data Schemas
class SensorDataBase(BaseModel):
    timestamp: datetime
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    airflow: Optional[float] = None
    pressure: Optional[float] = None
    vibrationRms: Optional[float] = None
    microphoneLevel: Optional[float] = None
    imuX: Optional[float] = None
    imuY: Optional[float] = None
    imuZ: Optional[float] = None
    
    rawFormat: Optional[str] = None
    rawPacket: Optional[str] = None
    rawBytesBase64: Optional[str] = None

class SensorDataCreate(SensorDataBase):
    pass

class SensorData(SensorDataBase):
    id: int
    session_id: int

    class Config:
        from_attributes = True

# Session Schemas
class SessionBase(BaseModel):
    name: str
    device_id: int

class SessionCreate(SessionBase):
    pass

class Session(SessionBase):
    id: int
    start_time: datetime
    end_time: Optional[datetime] = None

    class Config:
        from_attributes = True
