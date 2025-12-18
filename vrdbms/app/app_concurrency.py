"""
Vehicle Rental Database Management System (VRDBMS)
Flask Web Application with Concurrency Demo
"""

from flask import Flask, render_template, jsonify, request
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date, datetime, timedelta
from decimal import Decimal
import time
import threading

app = Flask(__name__)
app.secret_key = 'vrdbms_secret_key_2024'

# Database configuration
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'ceejayy',
    'password': '',
    'host': 'localhost',
    'port': '5432'
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def serialize_data(data):
    if isinstance(data, list):
        return [serialize_data(item) for item in data]
    elif isinstance(data, dict):
        return {key: serialize_data(value) for key, value in data.items()}
    elif isinstance(data, (date, datetime)):
        return data.isoformat()
    elif isinstance(data, Decimal):
        return float(data)
    else:
        return data

@app.route('/')
def index():
    """Main dashboard"""
    conn = get_db_connection()
    if not conn:
        return "<h1>Database Connection Error</h1>"
    
    try:
        cur = conn.cursor()
        
        cur.execute("SELECT COUNT(*) as count FROM vehicle WHERE status = 'available'")
        available_vehicles = cur.fetchone()['count']
        
        cur.execute("SELECT COUNT(*) as count FROM rental WHERE status = 'active'")
        active_rentals = cur.fetchone()['count']
        
        cur.execute("SELECT COUNT(*) as count FROM customer")
        total_customers = cur.fetchone()['count']
        
        cur.close()
        conn.close()
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>VRDBMS - Concurrency Demo</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px;
                       background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }}
                .container {{ background: white; padding: 30px; border-radius: 10px; 
                            box-shadow: 0 5px 20px rgba(0,0,0,0.2); max-width: 1200px; margin: 0 auto; }}
                h1 {{ color: #667eea; text-align: center; }}
                .stats {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 30px 0; }}
                .stat-card {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;
                            padding: 20px; border-radius: 8px; text-align: center; }}
                .stat-value {{ font-size: 2em; font-weight: bold; }}
                .demo-link {{ text-align: center; margin: 40px 0; }}
                .demo-btn {{ display: inline-block; background: #28a745; color: white; padding: 20px 40px;
                           text-decoration: none; border-radius: 8px; font-size: 1.2em; font-weight: bold;
                           box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: all 0.3s; }}
                .demo-btn:hover {{ background: #218838; transform: translateY(-2px); 
                                  box-shadow: 0 6px 15px rgba(0,0,0,0.3); }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚗 Vehicle Rental Database Management System</h1>
                
                <div class="stats">
                    <div class="stat-card">
                        <h3>Available Vehicles</h3>
                        <div class="stat-value">{available_vehicles}</div>
                    </div>
                    <div class="stat-card">
                        <h3>Active Rentals</h3>
                        <div class="stat-value">{active_rentals}</div>
                    </div>
                    <div class="stat-card">
                        <h3>Total Customers</h3>
                        <div class="stat-value">{total_customers}</div>
                    </div>
                </div>
                
                <div class="demo-link">
                    <a href="/concurrency-demo" class="demo-btn">
                        🔒 Concurrency Control Demo
                    </a>
                </div>
            </div>
        </body>
        </html>
        """
        return html
        
    except Exception as e:
        return f"<h1>Error</h1><p>{str(e)}</p>"


@app.route('/concurrency-demo')
def concurrency_demo():
    """Concurrency demonstration page"""
    return render_template('concurrency_demo.html')


@app.route('/api/get-available-vehicle')
def get_available_vehicle():
    """Get an available vehicle for demo"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT vehicle_id, make, model, year, license_plate, status
            FROM vehicle
            WHERE status = 'available'
            ORDER BY vehicle_id
            LIMIT 1
        """)
        vehicle = cur.fetchone()
        cur.close()
        conn.close()
        
        if vehicle:
            return jsonify({'success': True, 'vehicle': serialize_data(vehicle)})
        else:
            return jsonify({'success': False, 'message': 'No available vehicles'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/book-without-lock', methods=['POST'])
def book_without_lock():
    """Book vehicle WITHOUT proper locking (demonstrates race condition)"""
    data = request.json
    customer_name = data.get('customer_name')
    vehicle_id = data.get('vehicle_id')
    delay = data.get('delay', 0)  # Simulate processing time
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor()
        
        # Step 1: Check if vehicle is available (NO LOCK)
        cur.execute("SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = %s", (vehicle_id,))
        vehicle = cur.fetchone()
        
        if not vehicle:
            return jsonify({'success': False, 'message': 'Vehicle not found', 'step': 'check'})
        
        if vehicle['status'] != 'available':
            return jsonify({'success': False, 'message': f"Vehicle is {vehicle['status']}", 'step': 'check'})
        
        # Step 2: Simulate processing delay (this is where race condition happens!)
        time.sleep(delay)
        
        # Step 3: Create rental (both users can get here!)
        cur.execute("""
            INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
            VALUES (1, %s, 1, CURRENT_DATE, CURRENT_DATE + 7, 10000, 50.00, 'pending')
            RETURNING rental_id
        """, (vehicle_id,))
        
        rental = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': f'{customer_name} successfully booked the vehicle!',
            'rental_id': rental['rental_id'],
            'step': 'booked'
        })
        
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e), 'step': 'error'})


@app.route('/api/book-with-lock', methods=['POST'])
def book_with_lock():
    """Book vehicle WITH proper locking (prevents race condition)"""
    data = request.json
    customer_name = data.get('customer_name')
    customer_id = data.get('customer_id', 1)
    vehicle_id = data.get('vehicle_id')
    delay = data.get('delay', 0)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor()
        
        # Start transaction
        conn.autocommit = False
        
        # Step 1: Check and LOCK the vehicle (SELECT FOR UPDATE)
        cur.execute("""
            SELECT vehicle_id, status, make, model
            FROM vehicle 
            WHERE vehicle_id = %s
            FOR UPDATE
        """, (vehicle_id,))
        
        vehicle = cur.fetchone()
        
        if not vehicle:
            conn.rollback()
            return jsonify({'success': False, 'message': 'Vehicle not found', 'step': 'check'})
        
        # Vehicle is now LOCKED for this transaction
        
        # Step 2: Simulate processing delay (other users will WAIT here)
        time.sleep(delay)
        
        # Step 3: Check if still available
        if vehicle['status'] != 'available':
            conn.rollback()
            return jsonify({
                'success': False, 
                'message': f"Vehicle is now {vehicle['status']} (another user got it)", 
                'step': 'unavailable'
            })
        
        # Step 4: Create rental
        cur.execute("""
            INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
            VALUES (%s, %s, 1, CURRENT_DATE, CURRENT_DATE + 7, 
                    (SELECT mileage FROM vehicle WHERE vehicle_id = %s), 
                    50.00, 'active')
            RETURNING rental_id
        """, (customer_id, vehicle_id, vehicle_id))
        
        rental = cur.fetchone()
        
        # Step 5: Update vehicle status
        cur.execute("UPDATE vehicle SET status = 'rented' WHERE vehicle_id = %s", (vehicle_id,))
        
        # Commit transaction (releases lock)
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': f'{customer_name} successfully booked the vehicle!',
            'rental_id': rental['rental_id'],
            'step': 'booked'
        })
        
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e), 'step': 'error'})


@app.route('/api/reset-demo', methods=['POST'])
def reset_demo():
    """Reset demo vehicles to available status"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor()
        
        # Reset vehicles to available
        cur.execute("""
            UPDATE vehicle 
            SET status = 'available' 
            WHERE vehicle_id IN (
                SELECT DISTINCT vehicle_id 
                FROM rental 
                WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '5 minutes'
            )
        """)
        
        # Delete test rentals from last 5 minutes
        cur.execute("""
            DELETE FROM rental 
            WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '5 minutes'
        """)
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Demo reset successfully'})
        
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("=" * 60)
    print("🚗 VRDBMS - Vehicle Rental Database Management System")
    print("=" * 60)
    print("\n📊 Access the application at:")
    print("   Main Dashboard: http://localhost:5002")
    print("   Concurrency Demo: http://localhost:5002/concurrency-demo")
    print("\n💡 Press Ctrl+C to stop the server")
    print("=" * 60)
    app.run(debug=True, host='0.0.0.0', port=5002, threaded=True)





