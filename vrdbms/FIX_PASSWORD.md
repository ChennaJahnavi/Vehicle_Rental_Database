# Fix PostgreSQL Password Authentication

## The Issue
PostgreSQL is asking for a password when it shouldn't.

## Quick Fix: Change Authentication Method

### Step 1: Find the config file

```bash
# Find where pg_hba.conf is located
psql postgres -c "SHOW hba_file;" 2>/dev/null || echo "/usr/local/var/postgresql@14/pg_hba.conf"
```

### Step 2: Edit the config file

```bash
# Open the config file
nano /usr/local/var/postgresql@14/pg_hba.conf
```

Or if nano doesn't work:
```bash
open -a TextEdit /usr/local/var/postgresql@14/pg_hba.conf
```

### Step 3: Change authentication to "trust"

Find these lines near the bottom:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

Change them to:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
```

**Change `md5` to `trust` on those three lines**

Save and exit (Ctrl+X, then Y, then Enter in nano)

### Step 4: Restart PostgreSQL

```bash
brew services restart postgresql@14
```

### Step 5: Test (should work without password now)

```bash
psql postgres -c "SELECT version();"
```

---

## Alternative: Try Without Specifying Database

Sometimes just connecting without `-d postgres` works:

```bash
# Try this instead
psql -c "SELECT version();"
```

Or just:
```bash
psql
```

Then type `\q` to exit.

---

## Nuclear Option: Reset PostgreSQL Config

If the above doesn't work, reset everything:

```bash
# Stop PostgreSQL
brew services stop postgresql@14

# Remove data directory
rm -rf /usr/local/var/postgresql@14

# Reinitialize with default settings
initdb /usr/local/var/postgresql@14 -E utf8

# Start PostgreSQL
brew services start postgresql@14

# Test
psql postgres -c "SELECT version();"
```

---

## Skip the Test - Just Setup Database

If you want to skip troubleshooting and just setup your project:

```bash
# Try creating the database directly
createdb vrdbms

# If it asks for password, do this first:
echo "local all all trust" | sudo tee -a /usr/local/var/postgresql@14/pg_hba.conf
brew services restart postgresql@14

# Then try again
createdb vrdbms
psql vrdbms -f database/schema.sql
psql vrdbms -f database/sample_data.sql
```

