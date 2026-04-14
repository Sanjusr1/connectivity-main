from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)

class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True)
    name = Column(String)
    owner_id = Column(Integer, ForeignKey("users.id"))
    
    owner = relationship("User")

class Session(Base):
    __tablename__ = "sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    device_id = Column(Integer, ForeignKey("devices.id"))
    
    device = relationship("Device")
    data = relationship("SensorData", back_populates="session")

class SensorData(Base):
    __tablename__ = "sensor_data"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("sessions.id"))
    timestamp = Column(DateTime, index=True)
    
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    airflow = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    vibrationRms = Column(Float, nullable=True)
    microphoneLevel = Column(Float, nullable=True)
    imuX = Column(Float, nullable=True)
    imuY = Column(Float, nullable=True)
    imuZ = Column(Float, nullable=True)
    
    # Raw payload data
    rawFormat = Column(String, nullable=True)
    rawPacket = Column(String, nullable=True)
    rawBytesBase64 = Column(String, nullable=True)
    
    session = relationship("Session", back_populates="data")
