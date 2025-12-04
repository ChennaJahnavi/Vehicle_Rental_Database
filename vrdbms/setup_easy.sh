#!/bin/bash
# ============================================================================
# VRDBMS Easy Setup Script (Uses your macOS username)
# ============================================================================

set -e

echo "🚗 Vehicle Rental Database Management System - Easy Setup"
echo "==========================================================="
echo ""

# Use macOS username (works without password)
DB_NAME="vrdbms"
DB_USER=$(whoami)
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Using your macOS user: ${DB_USER}${NC}"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL is not installed!${NC}"
    echo ""
    echo "Please install PostgreSQL first:"
    echo ""
    echo "  Option 1 - Homebrew:"
    echo "    brew install postgresql@14"
    echo "    brew services start postgresql@14"
    echo ""
    echo "  Option 2 - Postgres.app:"
    echo "    Download from https://postgresapp.com/"
    echo ""
    echo "After installation, run this script again."
    exit 1
fi

echo -e "${BLUE}Step 1: Checking PostgreSQL service...${NC}"
if ! pg_isready &> /dev/null; then
    echo -e "${YELLOW}PostgreSQL is not running. Trying to start...${NC}"
    brew services start postgresql@14 || true
    sleep 2
fi

if pg_isready &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${RED}Error: PostgreSQL is not running!${NC}"
    echo "Please start PostgreSQL manually:"
    echo "  brew services start postgresql@14"
    exit 1
fi

echo -e "${BLUE}Step 2: Creating database...${NC}"
# Check if database exists
if psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo -e "${YELLOW}Database '$DB_NAME' already exists. Dropping and recreating...${NC}"
    dropdb $DB_NAME || true
fi

createdb $DB_NAME
echo -e "${GREEN}✓ Database created${NC}"

echo -e "${BLUE}Step 3: Initializing schema...${NC}"
psql -d $DB_NAME -f database/schema.sql > /dev/null
echo -e "${GREEN}✓ Schema initialized${NC}"

echo -e "${BLUE}Step 4: Loading sample data...${NC}"
psql -d $DB_NAME -f database/sample_data.sql > /dev/null
echo -e "${GREEN}✓ Sample data loaded${NC}"

echo -e "${BLUE}Step 5: Verifying installation...${NC}"
echo ""
psql -d $DB_NAME -c "
SELECT 
    'Branches' as entity, COUNT(*) as count FROM branch
UNION ALL SELECT 'Vehicle Categories', COUNT(*) FROM vehicle_category
UNION ALL SELECT 'Vehicles', COUNT(*) FROM vehicle
UNION ALL SELECT 'Customers', COUNT(*) FROM customer
UNION ALL SELECT 'Employees', COUNT(*) FROM employee
UNION ALL SELECT 'Rentals', COUNT(*) FROM rental
UNION ALL SELECT 'Payments', COUNT(*) FROM payment
UNION ALL SELECT 'Maintenance Records', COUNT(*) FROM maintenance;
"

echo ""
echo -e "${GREEN}✓ Setup completed successfully!${NC}"
echo ""
echo "Database Configuration:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo ""
echo -e "${YELLOW}IMPORTANT: Update app/app.py with these settings:${NC}"
echo ""
echo "  DB_CONFIG = {"
echo "      'dbname': '$DB_NAME',"
echo "      'user': '$DB_USER',"
echo "      'password': '',"
echo "      'host': '$DB_HOST',"
echo "      'port': '$DB_PORT'"
echo "  }"
echo ""
echo "To start the web application:"
echo "  cd app"
echo "  pip install -r requirements.txt"
echo "  python app.py"
echo ""
echo "The application will be available at: http://localhost:5000"

