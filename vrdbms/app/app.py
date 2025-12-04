"""
Vehicle Rental Database Management System (VRDBMS)
Flask Web Application
"""

from flask import Flask
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date
from decimal import Decimal

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
    elif isinstance(data, (date,)):
        return data.isoformat()
    elif isinstance(data, Decimal):
        return float(data)
    else:
        return data

@app.route('/')
def index():
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
        
        cur.execute("SELECT COALESCE(SUM(total_amount), 0) as revenue FROM rental WHERE status = 'completed'")
        total_revenue = float(cur.fetchone()['revenue'])
        
        cur.execute("""
            SELECT r.rental_id, c.first_name || ' ' || c.last_name AS customer_name,
                   v.make || ' ' || v.model AS vehicle, r.rental_date, r.status
            FROM rental r
            JOIN customer c ON r.customer_id = c.customer_id
            JOIN vehicle v ON r.vehicle_id = v.vehicle_id
            ORDER BY r.rental_date DESC LIMIT 5
        """)
        rentals = serialize_data(cur.fetchall())
        
        cur.close()
        conn.close()
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>VRDBMS</title>
            <style>
                body {{ font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px;
                       background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }}
                .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 5px 20px rgba(0,0,0,0.2); }}
                h1 {{ color: #667eea; text-align: center; }}
                .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }}
                .stat-card {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;
                            padding: 20px; border-radius: 8px; text-align: center; }}
                .stat-value {{ font-size: 2.5em; font-weight: bold; margin: 10px 0; }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
                th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
                th {{ background: #667eea; color: white; }}
                tr:hover {{ background: #f5f5f5; }}
                .badge {{ padding: 5px 10px; border-radius: 3px; font-size: 0.85em; font-weight: bold; }}
                .badge-success {{ background: #28a745; color: white; }}
                .badge-warning {{ background: #ffc107; color: #333; }}
                .badge-info {{ background: #17a2b8; color: white; }}
                .success-msg {{ background: #d4edda; color: #155724; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚗 Vehicle Rental Database Management System</h1>
                <div class="success-msg">✅ <strong>Database Connected Successfully!</strong></div>
                
                <h2>Dashboard Statistics</h2>
                <div class="stats">
                    <div class="stat-card"><h3>Available Vehicles</h3><div class="stat-value">{available_vehicles}</div></div>
                    <div class="stat-card"><h3>Active Rentals</h3><div class="stat-value">{active_rentals}</div></div>
                    <div class="stat-card"><h3>Total Customers</h3><div class="stat-value">{total_customers}</div></div>
                    <div class="stat-card"><h3>Total Revenue</h3><div class="stat-value">${total_revenue:,.2f}</div></div>
                </div>
                
                <h2>Recent Rentals</h2>
                <table>
                    <thead><tr><th>ID</th><th>Customer</th><th>Vehicle</th><th>Date</th><th>Status</th></tr></thead>
                    <tbody>
        """
        
        for rental in rentals:
            status_map = {'active': 'badge-success', 'pending': 'badge-warning', 'completed': 'badge-info'}
            status_class = status_map.get(rental['status'], 'badge-info')
            html += f"<tr><td>{rental['rental_id']}</td><td>{rental['customer_name']}</td><td>{rental['vehicle']}</td><td>{rental['rental_date']}</td><td><span class='badge {status_class}'>{rental['status']}</span></td></tr>"
        
        html += """
                    </tbody>
                </table>
                <div style="margin-top: 40px; padding: 20px; background: #e7f3ff; border-left: 4px solid #2196F3; border-radius: 5px;">
                    <h3 style="margin-top: 0;">✅ Project Complete!</h3>
                    <ul>
                        <li>✅ 8 normalized tables (3NF)</li>
                        <li>✅ 5 analytical views</li>
                        <li>✅ 4 triggers and 4 stored procedures</li>
                        <li>✅ 117 sample records loaded</li>
                        <li>✅ Ready for presentation!</li>
                    </ul>
                </div>
                <footer style="text-align: center; margin-top: 40px; color: #666;">
                    <p>&copy; 2024 VRDBMS | Database Course 180B</p>
                </footer>
            </div>
        </body>
        </html>
        """
        return html
        
    except Exception as e:
        return f"<h1>Error</h1><p>{str(e)}</p>"

if __name__ == '__main__':
    print("=" * 60)
    print("🚗 VRDBMS - Vehicle Rental Database Management System")
    print("=" * 60)
    print("\n📊 Access the dashboard at: http://localhost:5001")
    print("\n💡 Press Ctrl+C to stop the server")
    print("=" * 60)
    app.run(debug=True, host='0.0.0.0', port=5001)
