from fastapi import FastAPI, WebSocket
import uvicorn
import asyncio
import json
import random
import datetime

app = FastAPI()

@app.websocket("/")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Test client connected to mock Wi-Fi WebSocket server!")
    try:
        while True:
            # Send a packet every second
            data = {
                "timestamp": datetime.datetime.now().isoformat() + "Z",
                "temperature": 26.5 + random.uniform(-0.5, 0.5),
                "humidity": 52.3 + random.uniform(-1.0, 1.0),
                "airflow": 1.8 + random.uniform(-0.3, 0.3),
                "pressure": 101.2 + random.uniform(-2.0, 2.0),
                "vibrationRms": 0.15 + random.uniform(-0.02, 0.02),
                "microphoneLevel": 45.0 + random.uniform(-5.0, 5.0),
                "imuX": random.uniform(-0.05, 0.05),
                "imuY": random.uniform(-0.05, 0.05),
                "imuZ": 0.99 + random.uniform(-0.01, 0.01)
            }
            # Flutter expects newline-framed JSON
            await websocket.send_text(json.dumps(data) + "\n")
            await asyncio.sleep(1)
    except Exception as e:
        print(f"Test client disconnected: {e}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
