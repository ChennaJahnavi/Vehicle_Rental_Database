# Vehicle Rental Database Management System (VRDBMS)

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![Python](https://img.shields.io/badge/Python-3.x-green.svg)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.0-red.svg)](https://flask.palletsprojects.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive Vehicle Rental Database Management System demonstrating advanced database concepts including normalization, strategic indexing, and robust concurrency control. This project showcases production-ready database design with measurable performance optimizations and thread-safe operations.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technologies](#technologies)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Performance Results](#performance-results)
- [Concurrency Control](#concurrency-control)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Authors](#authors)
- [License](#license)

## 🎯 Overview

The VRDBMS is a complete vehicle rental management system designed to demonstrate:

- **Database Normalization**: Third Normal Form (3NF) schema design
- **Performance Optimization**: 34 strategic indexes achieving up to 106x query speedup
- **Concurrency Control**: Race condition prevention using SELECT FOR UPDATE
- **Production Features**: Triggers, stored procedures, views, and comprehensive constraints

### Key Statistics

- **8 Normalized Tables** (3NF compliance)
- **34 Performance Indexes**
- **5 Analytical Views**
- **4 Automated Triggers**
- **8 Stored Procedures**
- **9,457+ Test Records**
- **106x Query Performance Improvement** (measured)

## ✨ Features

### Database Features
- ✅ **Normalized Schema**: 3NF design eliminating redundancy
- ✅ **Strategic Indexing**: 34 indexes optimized for common query patterns
- ✅ **Concurrency Safe**: SELECT FOR UPDATE preventing race conditions
- ✅ **Automated Logic**: Triggers for status updates and calculations
- ✅ **Analytical Views**: Pre-built views for reporting
- ✅ **Data Integrity**: Comprehensive constraints (CHECK, UNIQUE, FOREIGN KEY)

### Application Features
- ✅ **Web Dashboard**: Real-time statistics and monitoring
- ✅ **Concurrency Demo UI**: Visual demonstration of race conditions
- ✅ **RESTful API**: Thread-safe endpoints
- ✅ **Performance Metrics**: Query execution time tracking

## 🛠️ Technologies

- **Database**: PostgreSQL 14+
- **Backend**: Python 3.x with Flask 3.0
- **Database Driver**: psycopg2-binary 2.9.9
- **Development Tools**: pgAdmin, psql

## 📦 Installation

### Prerequisites

- PostgreSQL 14 or higher
- Python 3.8 or higher
- pip (Python package manager)

### Step 1: Install PostgreSQL

**macOS:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install postgresql-14
sudo systemctl start postgresql
```

**Windows:**
Download and install from [PostgreSQL Official Website](https://www.postgresql.org/download/windows/)

### Step 2: Clone the Repository

```bash
git clone <your-repo-url>
cd 180B_Project1/vrdbms
```

### Step 3: Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database and user
CREATE DATABASE vrdbms;
CREATE USER your_username WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE vrdbms TO your_username;
\q
```

### Step 4: Setup Database Schema

```bash
# Apply schema with all indexes
psql -U your_username -d vrdbms -f database/schema.sql

# Load sample data
psql -U your_username -d vrdbms -f database/sample_data.sql
```

### Step 5: Install Python Dependencies

```bash
cd app
pip install -r requirements.txt
```

## 🚀 Quick Start

### Start the Web Application

```bash
cd app
python app.py
```

Access the dashboard at: `http://localhost:5001`

### Access Concurrency Demo

Navigate to: `http://localhost:5001/concurrency-demo`

### Run Performance Tests

```bash
# Index performance benchmark
psql -U your_username -d vrdbms -f database/benchmark_comparison.sql

# Quick verification (5 seconds)
psql -U your_username -d vrdbms -f database/quick_verify.sql
```

### Run Concurrency Tests

**Terminal 1:**
```bash
psql -U your_username -d vrdbms -f database/concurrency_terminal1.sql
```

**Terminal 2 (simultaneously):**
```bash
psql -U your_username -d vrdbms -f database/concurrency_terminal2.sql
```

## 📁 Project Structure

```
vrdbms/
├── app/                          # Flask web application
│   ├── app.py                    # Main application
│   ├── app_concurrency.py        # Concurrency demo
│   ├── requirements.txt          # Python dependencies
│   └── templates/                # HTML templates
│       └── concurrency_demo.html
│
├── database/                      # Database scripts
│   ├── schema.sql                # Complete database schema
│   ├── sample_data.sql           # Test data (9,457+ records)
│   ├── add_indexes.sql           # Add indexes to existing DB
│   ├── benchmark_comparison.sql  # Performance tests
│   ├── concurrency_tests.sql     # Concurrency test suite
│   ├── concurrency_terminal1.sql # Interactive demo (T1)
│   ├── concurrency_terminal2.sql # Interactive demo (T2)
│   ├── concurrency_safe_rental.sql # Production-safe functions
│   └── *.sql                     # Additional test scripts
│
├── PROJECT_REPORT.md              # Complete project report
├── PROJECT_REPORT.tex             # IEEE format LaTeX report
├── ER_DIAGRAM.md                 # Entity-Relationship diagram
├── INDEX_OPTIMIZATIONS.md        # Index documentation
├── CONCURRENCY_GUIDE.md          # Concurrency documentation
├── README.md                     # This file
└── *.md                          # Additional documentation
```

## 🗄️ Database Schema

### Entities

1. **CUSTOMER** - Customer profiles and information
2. **VEHICLE** - Vehicle inventory and details
3. **RENTAL** - Rental transactions (central entity)
4. **PAYMENT** - Payment records
5. **BRANCH** - Office locations
6. **EMPLOYEE** - Staff information
7. **VEHICLE_CATEGORY** - Vehicle types and pricing
8. **MAINTENANCE** - Service history

### Relationships

- CUSTOMER → RENTAL (1:N)
- VEHICLE → RENTAL (1:N)
- RENTAL → PAYMENT (1:N)
- VEHICLE → MAINTENANCE (1:N)
- BRANCH → VEHICLE (1:N)
- BRANCH → EMPLOYEE (1:N)
- EMPLOYEE → RENTAL (1:N)
- VEHICLE_CATEGORY → VEHICLE (1:N)

See `ER_DIAGRAM.md` for the complete Entity-Relationship diagram.

## 📊 Performance Results

### Index Optimization Results

**Test Case: Customer Rental Lookup (3,015 records)**

| Metric | Without Index | With Index | Improvement |
|--------|---------------|------------|-------------|
| **Execution Time** | 3.933 ms | 0.037 ms | **106x faster** |
| **Scan Method** | Sequential Scan | Bitmap Index Scan | ✅ |
| **Rows Scanned** | 3,007 | 8 | **99.7% reduction** |
| **Buffer Reads** | 42 pages | 6 pages | **86% reduction** |
| **Query Cost** | 79.69 | 25.97 | **67% lower** |

**Overall Performance Improvements:**

| Query Type | Before (ms) | After (ms) | Speedup |
|------------|-------------|------------|---------|
| Customer rental lookup | 3.933 | 0.037 | **106x** |
| Vehicle availability | 2.5 | 0.3 | **8.3x** |
| Dashboard statistics | 15.2 | 3.1 | **4.9x** |
| Date range queries | 4.8 | 0.6 | **8x** |
| Customer search | 3.2 | 0.4 | **8x** |

### Index Distribution

| Table | Indexes | Purpose |
|-------|---------|---------|
| rental | 8 | Status, dates, branches, customers, vehicles |
| vehicle | 6 | Status, branch, category, make/model |
| maintenance | 5 | Vehicle history, dates, service tracking |
| customer | 4 | Name search, email, phone, location |
| payment | 4 | Dates, methods, amounts |
| branch | 3 | City, state, location |
| employee | 2 | Branch, position |
| vehicle_category | 2 | Rate, capacity |
| **Total** | **34** | **Complete coverage** |

### Running Performance Tests

```bash
# Comprehensive benchmark
psql -U your_username -d vrdbms -f database/benchmark_comparison.sql

# Quick verification
psql -U your_username -d vrdbms -f database/quick_verify.sql

# Detailed analysis
psql -U your_username -d vrdbms -f database/test_optimization.sql
```

## 🔐 Concurrency Control

### Race Condition Prevention

The system uses **SELECT FOR UPDATE** to prevent race conditions when multiple users attempt to book the same vehicle simultaneously.

**Problem (Without Locking):**
```
User A: Check vehicle → "available" ✓
User B: Check vehicle → "available" ✓
User A: Book vehicle → SUCCESS ✓
User B: Book vehicle → SUCCESS ✓
Result: DOUBLE BOOKING ❌
```

**Solution (With SELECT FOR UPDATE):**
```sql
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 15 FOR UPDATE;
-- Row is locked, other transactions wait
UPDATE vehicle SET status = 'rented' WHERE vehicle_id = 15;
COMMIT; -- Releases lock
```

**Result:**
```
User A: Lock vehicle → Check → Book → SUCCESS ✓
User B: Wait → Lock → Check → "rented" → FAIL ✓
Result: SINGLE BOOKING ✅
```

### Concurrency Test Results

- ✅ **0 race conditions** with proper locking
- ✅ **100% data integrity** under concurrent load
- ✅ **Proper transaction isolation**
- ✅ **Thread-safe API endpoints**
- ✅ **Minimal overhead** (< 1ms additional latency)

### Running Concurrency Tests

**Interactive Demo (2 terminals):**
```bash
# Terminal 1
psql -U your_username -d vrdbms -f database/concurrency_terminal1.sql

# Terminal 2 (run simultaneously)
psql -U your_username -d vrdbms -f database/concurrency_terminal2.sql
```

**Web UI Demo:**
1. Start Flask app: `python app/app.py`
2. Navigate to: `http://localhost:5001/concurrency-demo`
3. Test with/without locking modes

## 🧪 Testing

### Index Performance Tests

```bash
# Quick verification (5 seconds)
psql -U your_username -d vrdbms -f database/quick_verify.sql

# Comprehensive benchmark
psql -U your_username -d vrdbms -f database/benchmark_comparison.sql

# Detailed analysis
psql -U your_username -d vrdbms -f database/test_optimization.sql
```

### Concurrency Tests

```bash
# Educational overview
psql -U your_username -d vrdbms -f database/concurrency_tests.sql

# Interactive demo (requires 2 terminals)
# Terminal 1:
psql -U your_username -d vrdbms -f database/concurrency_terminal1.sql
# Terminal 2:
psql -U your_username -d vrdbms -f database/concurrency_terminal2.sql
```

### Test Coverage

- ✅ Index performance (before/after comparison)
- ✅ Race condition prevention
- ✅ Deadlock detection
- ✅ Lost update prevention
- ✅ Phantom read prevention
- ✅ Transaction isolation levels
- ✅ Lock contention handling

## 📚 Documentation

### Main Documentation Files

- **`PROJECT_REPORT.md`** - Complete project report (PDF-ready)
- **`PROJECT_REPORT.tex`** - IEEE format LaTeX report
- **`ER_DIAGRAM.md`** - Entity-Relationship diagram details
- **`INDEX_OPTIMIZATIONS.md`** - Detailed index documentation
- **`CONCURRENCY_GUIDE.md`** - Complete concurrency guide
- **`INDEX_SUMMARY.md`** - Index optimization summary
- **`CONCURRENCY_SUMMARY.md`** - Concurrency testing summary

### Database Documentation

- **`database/INDEX_README.md`** - Index quick start guide
- **`database/TESTING_GUIDE.md`** - Testing documentation
- **`database/CONCURRENCY_GUIDE.md`** - Concurrency testing guide

### Setup Guides

- **`SIMPLE_SETUP.md`** - Quick setup instructions
- **`INSTALL_POSTGRESQL.md`** - PostgreSQL installation guide
- **`HOW_TO_DEMO.md`** - Demonstration guide

## 🎓 Key Concepts Demonstrated

### Normalization
- **1NF**: Atomic values, no repeating groups
- **2NF**: No partial dependencies
- **3NF**: No transitive dependencies

### Indexing
- Single-column indexes for fast lookups
- Composite indexes for multi-column queries
- Foreign key indexes for JOIN optimization

### Concurrency
- SELECT FOR UPDATE (pessimistic locking)
- Atomic operations
- Transaction isolation levels
- SKIP LOCKED pattern

### Database Features
- Triggers for automated business logic
- Stored procedures for complex operations
- Views for analytical reporting
- Constraints for data integrity

## 🔧 Configuration

### Database Connection

Update connection settings in `app/app.py`:

```python
DB_CONFIG = {
    'dbname': 'vrdbms',
    'user': 'your_username',
    'password': 'your_password',
    'host': 'localhost',
    'port': '5432'
}
```

### Flask Application

Default settings:
- Host: `0.0.0.0`
- Port: `5001`
- Debug mode: Enabled

## 📈 Database Statistics

| Table | Records | Purpose |
|-------|---------|---------|
| customer | 515 | Customer profiles |
| vehicle | 1,025 | Vehicle inventory |
| rental | 3,015 | Rental transactions |
| payment | 1,807 | Payment records |
| branch | 5 | Office locations |
| employee | 60 | Staff information |
| vehicle_category | 5 | Vehicle types |
| maintenance | 2,025 | Service history |
| **Total** | **9,457** | **Complete dataset** |

## 🚨 Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -U postgres -l | grep vrdbms

# Reset database (if needed)
psql -U your_username -d vrdbms -f database/schema.sql
```

### Index Not Being Used

```bash
# Update statistics
psql -U your_username -d vrdbms -c "ANALYZE;"

# Check index usage
psql -U your_username -d vrdbms -f database/analyze_indexes.sql
```

### Concurrency Issues

```bash
# Check for blocking queries
psql -U your_username -d vrdbms -c "
SELECT pid, wait_event, query 
FROM pg_stat_activity 
WHERE wait_event_type = 'Lock';
"

# View current locks
psql -U your_username -d vrdbms -c "
SELECT * FROM pg_locks 
WHERE relation::regclass::text LIKE '%vehicle%';
"
```

## 👥 Authors

1. **Jahnavi Chenna** - MS Computer Software Engineering, San José State University
2. **Krishna Sai Akhil Nanduri** - MS Computer Software Engineering, San José State University
3. **Kavya Yerneni** - MS Computer Software Engineering, San José State University
4. **Anurag Bodapally** - MS Computer Software Engineering, San José State University

## 📄 License

This project is created for educational purposes as part of Database Systems Course 180B.

## Acknowledgments

- PostgreSQL Global Development Group for excellent documentation
- Flask Development Team for the web framework
- Course instructors for guidance and support

## 📞 Support

For questions or issues:
1. Check the documentation files in the repository
2. Review test scripts for examples
3. Consult PostgreSQL and Flask documentation

---

**Built for Database Systems 180B**

