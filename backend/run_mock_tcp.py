import socket
import time
import json
import random
import datetime

def main():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # Allow address reuse
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    port = 9000
    server_socket.bind(('0.0.0.0', port))
    server_socket.listen(5)
    print(f"Mock TCP Server listening on 0.0.0.0:{port}...")
    
    try:
        while True:
            client_socket, client_address = server_socket.accept()
            print(f"Accepted connection from {client_address}")
            try:
                while True:
                    # Generate mock sensor data
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
                    # Send newline-terminated JSON data
                    packet = json.dumps(data) + "\n"
                    client_socket.sendall(packet.encode('utf-8'))
                    time.sleep(1)
            except (ConnectionResetError, ConnectionAbortedError, socket.error) as e:
                print(f"Client disconnected: {e}")
            finally:
                client_socket.close()
    except KeyboardInterrupt:
        print("\nShutting down Mock TCP Server.")
    finally:
        server_socket.close()

if __name__ == "__main__":
    main()
