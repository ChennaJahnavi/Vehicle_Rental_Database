# PostgreSQL Installation and Setup Guide

## Issue: PostgreSQL Not Installed or Not Configured

You're seeing authentication errors because PostgreSQL needs to be properly installed and configured.

---

## Step 1: Install PostgreSQL

### Option A: Using Homebrew (Recommended)

```bash
# Install PostgreSQL
brew install postgresql@14

# Add to PATH
echo 'export PATH="/usr/local/opt/postgresql@14/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Start PostgreSQL service
brew services start postgresql@14
```

### Option B: Using Postgres.app (Easy GUI Option)

1. Download from: https://postgresapp.com/
2. Drag to Applications folder
3. Open Postgres.app
4. Click "Initialize" to create a new server
5. Server will start automatically

### Option C: Official Installer

1. Download from: https://www.postgresql.org/download/macosx/
2. Run the installer
3. Follow the installation wizard
4. Remember the password you set for the postgres user

---

## Step 2: Verify Installation

```bash
# Check if PostgreSQL is running
pg_isready

# Should output: /tmp:5432 - accepting connections
```

If not running:
```bash
# Start PostgreSQL
brew services start postgresql@14
# OR
pg_ctl -D /usr/local/var/postgresql@14 start
```

---

## Step 3: Create Database User (If Needed)

### Option A: Use Your macOS Username (Easiest)

```bash
# Create database with your username
createdb vrdbms

# Test connection (no password needed)
psql vrdbms
```

### Option B: Create postgres User

```bash
# Connect as superuser (your macOS username)
psql postgres

# In psql, create postgres user:
CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';

# Exit
\q
```

---

## Step 4: Update Project Configuration

Based on your setup, update the database configuration in the project:

### Edit: `app/app.py`

Find this section (around line 15):

```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'postgres',      # Change this
    'password': 'postgres',   # Change this
    'host': 'localhost',
    'port': '5432'
}
```

**Option 1: Use your macOS username (no password)**
```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'ceejayy',       # Your macOS username
    'password': '',           # Empty password
    'host': 'localhost',
    'port': '5432'
}
```

**Option 2: Use postgres user (if you created it)**
```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'postgres',
    'password': 'postgres',   # Or whatever password you set
    'host': 'localhost',
    'port': '5432'
}
```

---

## Step 5: Update Setup Script

### Edit: `setup.sh`

Change these lines at the top:

**FROM:**
```bash
DB_USER="postgres"
DB_PASSWORD="postgres"
```

**TO (using your macOS username):**
```bash
DB_USER="ceejayy"
DB_PASSWORD=""
```

**OR (if using postgres user):**
```bash
DB_USER="postgres"
DB_PASSWORD="postgres"
```

---

## Step 6: Run Setup

Now you can run the setup:

```bash
cd "/Users/ceejayy/Documents/180B Project/vrdbms"
./setup.sh
```

---

## Troubleshooting

### Issue: "connection to server failed"

**Solution 1: Check if PostgreSQL is running**
```bash
pg_isready
brew services list | grep postgresql
```

**Solution 2: Start PostgreSQL**
```bash
brew services start postgresql@14
```

### Issue: "password authentication failed"

**Solution 1: Use trust authentication temporarily**

Edit PostgreSQL config:
```bash
# Find config file
psql -U $(whoami) -d postgres -c "SHOW hba_file"

# Edit it (may need sudo)
nano /usr/local/var/postgresql@14/pg_hba.conf

# Change this line:
# FROM: host  all  all  127.0.0.1/32  md5
# TO:   host  all  all  127.0.0.1/32  trust

# Restart PostgreSQL
brew services restart postgresql@14
```

**Solution 2: Use your macOS username**

PostgreSQL by default creates a user with your macOS username that doesn't need a password:
```bash
# Test connection
psql -U ceejayy -d postgres

# If this works, use 'ceejayy' as DB_USER and empty password
```

### Issue: "database does not exist"

```bash
# Create the database manually
createdb vrdbms

# Or with specific user
createdb -U ceejayy vrdbms
```

---

## Quick Start After Installation

### Using Your macOS Username (Easiest)

1. **Update `app/app.py`:**
```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'ceejayy',
    'password': '',
    'host': 'localhost',
    'port': '5432'
}
```

2. **Update `setup.sh`:**
```bash
DB_USER="ceejayy"
DB_PASSWORD=""
```

3. **Create database:**
```bash
createdb vrdbms
```

4. **Load schema:**
```bash
psql vrdbms -f database/schema.sql
```

5. **Load data:**
```bash
psql vrdbms -f database/sample_data.sql
```

6. **Run app:**
```bash
cd app
pip install -r requirements.txt
python app.py
```

---

## Alternative: Quick Manual Setup

If the script keeps failing, do it manually:

```bash
# 1. Navigate to project
cd "/Users/ceejayy/Documents/180B Project/vrdbms"

# 2. Create database
createdb vrdbms

# 3. Load schema
psql vrdbms < database/schema.sql

# 4. Load data
psql vrdbms < database/sample_data.sql

# 5. Verify
psql vrdbms -c "SELECT COUNT(*) FROM vehicle;"

# 6. Install Python dependencies
cd app
pip install -r requirements.txt

# 7. Update app.py with your username
# Edit DB_CONFIG to use 'ceejayy' and empty password

# 8. Run app
python app.py
```

---

## Recommended: Use Your macOS Username

**Easiest approach - no password needed:**

1. PostgreSQL creates a superuser with your macOS username by default
2. This user can connect without a password via Unix socket
3. Update `app.py` to use `'user': 'ceejayy'` and `'password': ''`
4. Update `setup.sh` to use `DB_USER="ceejayy"` and `DB_PASSWORD=""`

---

## Test Your Connection

```bash
# Test 1: Can you connect?
psql -U ceejayy -d postgres -c "SELECT version();"

# Test 2: Can Python connect?
python3 -c "import psycopg2; conn = psycopg2.connect(dbname='postgres', user='ceejayy', host='localhost'); print('Success!')"
```

---

## Need More Help?

### Check PostgreSQL Status
```bash
brew services list
ps aux | grep postgres
```

### View PostgreSQL Logs
```bash
tail -f /usr/local/var/log/postgresql@14.log
```

### Reset Everything
```bash
brew services stop postgresql@14
rm -rf /usr/local/var/postgresql@14
brew reinstall postgresql@14
initdb /usr/local/var/postgresql@14
brew services start postgresql@14
```

---

## Summary

**The issue is**: PostgreSQL isn't installed or the authentication is wrong.

**Quick fix**:
1. Install PostgreSQL: `brew install postgresql@14`
2. Start it: `brew services start postgresql@14`
3. Use your macOS username (`ceejayy`) instead of `postgres`
4. Update `app.py` and `setup.sh` with your username
5. Run manual setup commands above

---

**Once PostgreSQL is properly configured, your project will work perfectly!**

