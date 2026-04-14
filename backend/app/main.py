from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import database
from app.models import models
from app.routers import auth_router, device_router, session_router

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Connectivity Sensor Backend API", version="1.0.0")

# Configure CORS
origins = ["*"] # Configure appropriately for production

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(device_router.router)
app.include_router(session_router.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Connectivity Sensor API"}
