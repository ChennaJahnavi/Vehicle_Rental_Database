# ✅ Simple Setup Guide - VRDBMS

## Your files are now recreated! Follow these steps:

### Step 1: Load the Database

```bash
cd "/Users/ceejayy/Documents/180B Project/vrdbms"

# Create database
createdb vrdbms

# Load schema
psql vrdbms -f database/schema.sql

# Load data
psql vrdbms -f database/sample_data.sql

# Verify
psql vrdbms -c "SELECT COUNT(*) as vehicles FROM vehicle;"
```

You should see: `vehicles = 25`

---

### Step 2: Install Python Requirements

```bash
cd app
pip install -r requirements.txt
```

---

### Step 3: Run the App

```bash
python app.py
```

---

### Step 4: Open Browser

Go to: **http://localhost:5000**

You should see a beautiful dashboard with all your data!

---

## ✅ That's It!

Your complete database project is now running with:
- ✅ 8 tables with 117 records
- ✅ 5 views, 4 triggers, 4 stored procedures
- ✅ Web interface showing statistics
- ✅ Ready for presentation!

---

## If You Get Errors:

### "createdb: database already exists"
```bash
dropdb vrdbms
createdb vrdbms
# Then continue with psql commands
```

### "psql: connection failed"
```bash
# Check PostgreSQL is running
pg_isready

# If not, start it
brew services start postgresql@14
```

### "Module not found"
```bash
# Reinstall requirements
pip install -r requirements.txt
```

---

**You're all set! Your project is ready for demo!** 🎉

