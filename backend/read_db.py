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
        
    conn.close()

if __name__ == "__main__":
    main()
