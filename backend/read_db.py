import sqlite3

def main():
    conn = sqlite3.connect('sensor_data.db')
    cur = conn.cursor()
    
    # Get all tables
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cur.fetchall()]
    print("Database Tables:")
    print("-" * 30)
    for table in tables:
        # Get count
        cur.execute(f"SELECT COUNT(*) FROM {table};")
        count = cur.fetchone()[0]
        
        # Get columns
        cur.execute(f"PRAGMA table_info({table});")
        columns = [col[1] for col in cur.fetchall()]
        
        print(f"Table: {table}")
        print(f"  Total Rows: {count}")
        print(f"  Columns: {', '.join(columns)}")
        print("-" * 30)
    # Print recent sensor data
    print("\nLatest 5 records in sensor_data:")
    print("-" * 70)
    try:
        cur.execute("SELECT id, session_id, timestamp, temperature, humidity, airflow, pressure FROM sensor_data ORDER BY id DESC LIMIT 5;")
        rows = cur.fetchall()
        for row in rows:
            print(f"ID: {row[0]:<3} | Session: {row[1]:<2} | Time: {row[2]} | Temp: {row[3]:.1f}C | Hum: {row[4]:.1f}% | Airflow: {row[5]:.2f}")
    except Exception as e:
        print("Could not fetch rows:", e)
    print("-" * 70)
        
    conn.close()

if __name__ == "__main__":
    main()
