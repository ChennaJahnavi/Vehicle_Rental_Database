# PostgreSQL Complete Reset Guide

## Step 1: Uninstall PostgreSQL

Run these commands one by one:

```bash
# Stop PostgreSQL service
brew services stop postgresql@14

# Uninstall PostgreSQL
brew uninstall postgresql@14

# Remove all PostgreSQL data directories
rm -rf /usr/local/var/postgresql@14
rm -rf /usr/local/var/postgres
rm -rf ~/Library/Application\ Support/Postgres
rm -rf ~/Library/LaunchAgents/homebrew.mxcl.postgresql*

# Remove any other PostgreSQL versions if installed
brew uninstall postgresql postgresql@15 postgresql@13 postgresql@12

# Clean up Homebrew
brew cleanup
```

## Step 2: Fresh Install PostgreSQL

```bash
# Install PostgreSQL 14
brew install postgresql@14

# Add to PATH (important!)
echo 'export PATH="/usr/local/opt/postgresql@14/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Initialize database
initdb /usr/local/var/postgresql@14

# Start PostgreSQL
brew services start postgresql@14

# Wait a moment for it to start
sleep 3

# Test connection (should work with no password)
psql postgres -c "SELECT version();"
```

## Step 3: Setup Your Project Database

```bash
# Navigate to project
cd "/Users/ceejayy/Documents/180B Project/vrdbms"

# Create database
createdb vrdbms

# Load schema
psql vrdbms -f database/schema.sql

# Load data
psql vrdbms -f database/sample_data.sql

# Verify
psql vrdbms -c "SELECT COUNT(*) as total_vehicles FROM vehicle;"
```

## Step 4: Update app.py

Edit `app/app.py` and change DB_CONFIG to:

```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'ceejayy',      # Your macOS username
    'password': '',          # Empty - no password needed!
    'host': 'localhost',
    'port': '5432'
}
```

## Step 5: Run the Application

```bash
cd app
pip install -r requirements.txt
python app.py
```

Open: http://localhost:5000

---

## Why No Password?

When you install PostgreSQL via Homebrew on macOS:
- It creates a database user with YOUR macOS username (ceejayy)
- This user can connect via Unix socket WITHOUT a password
- This is the standard, secure way on macOS
- No "postgres" user is created by default

---

## Alternative: Create postgres User (If You Really Want)

If you prefer to use "postgres" as the username:

```bash
# After fresh install, create postgres user
psql postgres -c "CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';"

# Then use these settings in app.py
DB_CONFIG = {
    'user': 'postgres',
    'password': 'postgres',
    ...
}
```

But using your macOS username (ceejayy) is easier and more secure!

