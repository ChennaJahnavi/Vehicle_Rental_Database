# Entity-Relationship Diagram for VRDBMS

## Visual ER Diagram (For PowerPoint Slide 3)

```
                                    ┌──────────────────┐
                                    │     BRANCH       │
                                    │ ──────────────── │
                                    │ PK: branch_id    │
                                    │ branch_name      │
                                    │ city             │
                                    │ state            │
                                    │ phone            │
                                    └────────┬─────────┘
                                             │
                                             │ 1:N
                                ┌────────────┼────────────┐
                                │            │            │
                                │            │            │
                    ┌───────────▼─────┐     │    ┌───────▼──────────┐
                    │    EMPLOYEE     │     │    │     VEHICLE      │
                    │ ─────────────── │     │    │ ──────────────── │
                    │ PK: employee_id │     │    │ PK: vehicle_id   │
                    │ FK: branch_id   │     │    │ FK: branch_id    │
                    │ first_name      │     │    │ FK: category_id  │
                    │ last_name       │     │    │ make             │
                    │ position        │     │    │ model            │
                    │ salary          │     │    │ year             │
                    └────────┬────────┘     │    │ license_plate    │
                             │              │    │ status           │
                             │              │    │ mileage          │
                             │              │    └────┬─────────┬───┘
                             │              │         │         │
                             │              │         │ 1:N     │ 1:N
                             │              │         │         │
                             │ 1:N          │    ┌────▼──────┐  │
                             │              │    │MAINTENANCE│  │
                    ┌────────▼──────────────▼────▼───────┐   │  │
                    │            RENTAL                  │   │  │
                    │ ────────────────────────────────── │   │  │
                    │ PK: rental_id                      │   │  │
                    │ FK: customer_id                    │───┘  │
                    │ FK: vehicle_id                     │      │
                    │ FK: branch_id                      │      │
                    │ FK: employee_id                    │      │
                    │ rental_date                        │      │
                    │ start_date                         │      │
                    │ end_date                           │      │
                    │ return_date                        │      │
                    │ status                             │      │
                    │ total_amount                       │      │
                    └─────────┬──────────────────────────┘      │
                              │                                  │
                              │ 1:N                              │
                              │                         ┌────────▼─────────┐
                    ┌─────────▼────────┐               │   MAINTENANCE    │
                    │     PAYMENT      │               │ ──────────────── │
                    │ ──────────────── │               │ PK: maint_id     │
                    │ PK: payment_id   │               │ FK: vehicle_id   │
                    │ FK: rental_id    │               │ maintenance_type │
                    │ amount           │               │ maintenance_date │
                    │ payment_method   │               │ cost             │
                    │ payment_date     │               │ next_service_dt  │
                    └──────────────────┘               └──────────────────┘
                              ▲
                              │
                              │ N:1
                              │
                    ┌─────────┴────────┐               ┌──────────────────┐
                    │    CUSTOMER      │               │ VEHICLE_CATEGORY │
                    │ ──────────────── │               │ ──────────────── │
                    │ PK: customer_id  │               │ PK: category_id  │
                    │ first_name       │───────────────│ category_name    │
                    │ last_name        │      1:N      │ daily_rate       │
                    │ email            │               │ seating_capacity │
                    │ phone            │               │ description      │
                    │ license_number   │               └──────────────────┘
                    │ date_of_birth    │                         │
                    └──────────────────┘                         │
                                                                 │ 1:N
                                                                 │
                                                    (connects to VEHICLE)
```

---

## Relationship Details

### 1. CUSTOMER ──< RENTAL (1:N)
- One customer can have many rentals
- Each rental belongs to one customer
- FK: rental.customer_id → customer.customer_id

### 2. VEHICLE ──< RENTAL (1:N)
- One vehicle can have many rentals (over time)
- Each rental is for one vehicle
- FK: rental.vehicle_id → vehicle.vehicle_id

### 3. BRANCH ──< RENTAL (1:N)
- One branch processes many rentals
- Each rental is processed at one branch
- FK: rental.branch_id → branch.branch_id

### 4. BRANCH ──< VEHICLE (1:N)
- One branch has many vehicles
- Each vehicle belongs to one branch
- FK: vehicle.branch_id → branch.branch_id

### 5. BRANCH ──< EMPLOYEE (1:N)
- One branch has many employees
- Each employee works at one branch
- FK: employee.branch_id → branch.branch_id

### 6. EMPLOYEE ──< RENTAL (1:N)
- One employee processes many rentals
- Each rental is processed by one employee (optional)
- FK: rental.employee_id → employee.employee_id

### 7. RENTAL ──< PAYMENT (1:N)
- One rental can have multiple payments
- Each payment is for one rental
- FK: payment.rental_id → rental.rental_id

### 8. VEHICLE ──< MAINTENANCE (1:N)
- One vehicle has many maintenance records
- Each maintenance is for one vehicle
- FK: maintenance.vehicle_id → vehicle.vehicle_id

### 9. VEHICLE_CATEGORY ──< VEHICLE (1:N)
- One category includes many vehicles
- Each vehicle belongs to one category
- FK: vehicle.category_id → vehicle_category.category_id

---

## Entity Details

### CUSTOMER
- **Primary Key:** customer_id
- **Attributes:** name, email, phone, license_number, DOB, address
- **Constraints:** Unique email, unique license, age >= 18

### VEHICLE
- **Primary Key:** vehicle_id
- **Foreign Keys:** category_id, branch_id
- **Attributes:** make, model, year, license_plate, VIN, color, mileage, status
- **Constraints:** Unique license_plate, unique VIN

### RENTAL
- **Primary Key:** rental_id
- **Foreign Keys:** customer_id, vehicle_id, branch_id, employee_id
- **Attributes:** rental_date, start_date, end_date, return_date, amount, status
- **Constraints:** end_date >= start_date, return_date >= start_date

### PAYMENT
- **Primary Key:** payment_id
- **Foreign Keys:** rental_id
- **Attributes:** amount, payment_method, payment_date, transaction_id
- **Constraints:** amount > 0

### VEHICLE_CATEGORY
- **Primary Key:** category_id
- **Attributes:** category_name, description, daily_rate, seating_capacity
- **Constraints:** Unique category_name, daily_rate > 0

### BRANCH
- **Primary Key:** branch_id
- **Attributes:** branch_name, address, city, state, zip, phone, email
- **Constraints:** Unique phone, unique email

### EMPLOYEE
- **Primary Key:** employee_id
- **Foreign Keys:** branch_id
- **Attributes:** first_name, last_name, email, phone, position, salary
- **Constraints:** Unique email, salary > 0

### MAINTENANCE
- **Primary Key:** maintenance_id
- **Foreign Keys:** vehicle_id
- **Attributes:** maintenance_type, date, description, cost, next_service_date
- **Constraints:** next_service_date > maintenance_date

---

## ENUM Types

### rental_status
- pending
- active
- completed
- cancelled

### vehicle_status
- available
- rented
- maintenance
- retired

### payment_method
- cash
- credit_card
- debit_card
- online

### maintenance_type
- routine
- repair
- inspection
- emergency

---

## How to Create Visual ER Diagram for PowerPoint

### Option 1: Use Online Tool
1. Go to: https://dbdiagram.io or https://draw.io
2. Copy the entity definitions above
3. Create boxes for each entity
4. Draw lines for relationships
5. Export as PNG/SVG
6. Insert into PowerPoint

### Option 2: Use PowerPoint Directly
1. Insert → SmartArt → Hierarchy/Relationship
2. Add boxes for each entity
3. Add connection lines
4. Label relationships (1:N, etc.)

### Option 3: Generate from Database
```bash
# Use PostgreSQL to generate diagram
psql -U ceejayy -d vrdbms -c "\d+ rental"  # Shows relationships
```

### Option 4: Use pgAdmin
1. Right-click on vrdbms database
2. Select "ERD For Database"
3. Take screenshot
4. Insert into PowerPoint

---

## Recommended Visual for Slide 3

Use a **simplified version** focusing on main entities:

```
                    CUSTOMER ────< RENTAL >──── VEHICLE
                                     │              │
                                     │              │
                                     ▼              ▼
                                 PAYMENT      MAINTENANCE
```

Keep it simple for the slide, detailed diagram in appendix if needed.





