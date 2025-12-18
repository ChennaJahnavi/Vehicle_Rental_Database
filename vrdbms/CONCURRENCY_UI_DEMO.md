# 🔒 Concurrency Control UI Demonstration

## Overview

A visual web interface that demonstrates concurrency control in PostgreSQL by showing two users (Alice and Bob) trying to rent the same vehicle simultaneously.

---

## 🚀 Quick Start

### 1. Install Concurrency-Safe Functions (if not already done)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/concurrency_safe_rental.sql
```

### 2. Start the Application

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms/app
python app_concurrency.py
```

### 3. Open in Browser

```
http://localhost:5001/concurrency-demo
```

---

## 🎬 How to Demonstrate

### **Mode 1: WITHOUT Locking (Shows Problem)**

1. Click "❌ WITHOUT Locking" button
2. Click "🚀 Start Demo"
3. Click "Book This Vehicle" on **BOTH** Alice and Bob panels quickly
4. **Watch both succeed** ← This is the RACE CONDITION!
5. **Problem:** Both users booked the same vehicle (double booking)

**What Happens:**
- Alice checks availability → sees "available"
- Bob checks availability → also sees "available"
- Alice creates booking → SUCCESS
- Bob creates booking → SUCCESS (BUG!)
- **Result: DOUBLE BOOKING**

---

### **Mode 2: WITH Locking (Shows Solution)**

1. Click "✅ WITH Locking" button
2. Click "🚀 Start Demo"
3. Click "Book This Vehicle" on **BOTH** Alice and Bob panels quickly
4. **Watch:**
   - Alice locks the vehicle
   - Bob's request WAITS (you'll see "⏳ WAITING")
   - Alice completes booking
   - Bob sees "Vehicle is now rented"
   - **Only Alice succeeds** ← This is CORRECT!

**What Happens:**
- Alice uses `SELECT FOR UPDATE` → locks the row
- Bob tries to lock same row → WAITS
- Alice completes booking → releases lock
- Bob gets lock → sees vehicle is "rented"
- Bob's booking FAILS appropriately
- **Result: NO DOUBLE BOOKING**

---

## 📊 What to Show Your Professor

### Opening Statement:
> "I'll demonstrate how PostgreSQL prevents race conditions using row-level locking. We have two users, Alice and Bob, both trying to rent the same vehicle at the exact same time."

### Demo WITHOUT Locking:
> "First, WITHOUT proper concurrency control. Watch what happens when both users click 'Book' simultaneously..."
> 
> [Both succeed]
> 
> "Both users successfully booked the same vehicle - this is a race condition that causes double booking. In production, this would be a critical bug."

### Demo WITH Locking:
> "Now WITH proper locking using SELECT FOR UPDATE..."
>
> [Alice succeeds, Bob waits then fails]
>
> "Alice's transaction locks the vehicle row. Bob's transaction waits for the lock. When Alice commits, Bob sees the vehicle is already rented and his booking fails appropriately. This is the correct behavior."

### Key Points:
1. **Problem:** Race conditions cause double booking
2. **Solution:** `SELECT FOR UPDATE` locks rows
3. **Result:** Data integrity maintained
4. **Impact:** Essential for multi-user systems

---

## 🎯 Visual Features

### User Panels Show:
- ✅ Vehicle information (same vehicle for both users)
- ✅ Real-time status updates
- ✅ Color-coded logs (info, success, warning, error)
- ✅ Booking results

### Status Logs Show:
- 🔵 **Blue** - Information messages
- 🟢 **Green** - Success messages
- 🟡 **Orange** - Warnings
- 🔴 **Red** - Errors
- 🟣 **Purple** - Waiting (animated pulse)

---

## 🔧 Technical Details

### Backend (app_concurrency.py):

**WITHOUT Locking:**
```python
# Just checks and inserts - UNSAFE
SELECT * FROM vehicle WHERE id = X
# ... processing delay ...
INSERT INTO rental (...)
```

**WITH Locking:**
```python
# Locks the row - SAFE
SELECT * FROM vehicle WHERE id = X FOR UPDATE
# Other transactions WAIT here
# ... processing delay ...
INSERT INTO rental (...)
COMMIT  # Releases lock
```

### API Endpoints:

- `GET /concurrency-demo` - Demo page
- `GET /api/get-available-vehicle` - Load vehicle for demo
- `POST /api/book-without-lock` - Book WITHOUT locking (unsafe)
- `POST /api/book-with-lock` - Book WITH locking (safe)
- `POST /api/reset-demo` - Reset for next demo

---

## 📝 Demonstration Script

### Step 1: Introduction (30 seconds)
> "This demonstrates concurrency control - handling multiple users accessing the database simultaneously."

### Step 2: Show Problem (1 minute)
1. Select "WITHOUT Locking" mode
2. Click "Start Demo"
3. Click both "Book" buttons quickly
4. Show both succeeded → "This is a double booking bug!"

### Step 3: Show Solution (1 minute)
1. Click "Reset"
2. Select "WITH Locking" mode
3. Click "Start Demo"
4. Click both "Book" buttons quickly
5. Show Alice succeeds, Bob waits then fails → "This is correct!"

### Step 4: Explain (30 seconds)
> "SELECT FOR UPDATE is the key. It locks the database row while Alice processes her booking. Bob must wait. When Alice commits, Bob sees the updated status. This prevents race conditions and maintains data integrity."

**Total Time: 3 minutes**

---

## 🎓 Key Concepts Demonstrated

### 1. **Race Condition**
- Multiple users see same state
- Both proceed based on outdated information
- Results in data corruption

### 2. **Pessimistic Locking**
- `SELECT FOR UPDATE` locks rows
- Other transactions wait
- Prevents concurrent modifications

### 3. **Transaction Isolation**
- Each user's transaction is separate
- Locks ensure serializable access to shared resources
- Maintains ACID properties

### 4. **Real-World Impact**
- Without: Double bookings, angry customers, lost revenue
- With: Data integrity, fair access, production-ready

---

## 🐛 Troubleshooting

### If both users succeed even WITH locking:
**Reason:** Network latency - requests arrived sequentially

**Solution:** Click both buttons as quickly as possible, or add artificial delay in code

### If demo doesn't load:
```bash
# Check Flask is running
curl http://localhost:5001

# Restart application
python app_concurrency.py
```

### If vehicle not available:
```bash
# Reset some vehicles to available
psql -U ceejayy -d vrdbms -c "UPDATE vehicle SET status = 'available' WHERE vehicle_id <= 10;"
```

---

## 🎨 Customization

### Change timing delays:
Edit `app_concurrency.py` line ~150:
```python
delay = data.get('delay', 0)  # Increase for more visible waiting
```

### Change colors:
Edit `templates/concurrency_demo.html` CSS section

---

## ✅ Success Checklist

Before demo:
- [ ] Database is running
- [ ] Flask app is running (`python app_concurrency.py`)
- [ ] Browser open to http://localhost:5001/concurrency-demo
- [ ] At least one vehicle has status='available'

During demo:
- [ ] Show WITHOUT locking → both succeed (problem)
- [ ] Show WITH locking → only one succeeds (solution)
- [ ] Explain SELECT FOR UPDATE
- [ ] Show logs and status updates

---

## 📚 Files Created

```
vrdbms/
├── app/
│   ├── app_concurrency.py          ← Flask backend with APIs
│   └── templates/
│       └── concurrency_demo.html   ← Web UI
└── CONCURRENCY_UI_DEMO.md          ← This guide
```

---

## 🎯 What Your Professor Will See

1. **Visual Interface** - Two users side by side
2. **Real-Time Logs** - See each step of the process
3. **Race Condition** - Both users succeed without locking (BUG)
4. **Proper Locking** - Only one succeeds with locking (CORRECT)
5. **Production-Ready** - Real database transactions with proper error handling

---

**Start the app and open http://localhost:5001/concurrency-demo to begin! 🚀**





