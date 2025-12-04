-- ============================================================================
-- VEHICLE RENTAL DATABASE MANAGEMENT SYSTEM (VRDBMS)
-- Sample Data for Testing and Demonstration
-- ============================================================================

INSERT INTO branch (branch_name, address, city, state, zip_code, phone, email, manager_name) VALUES
('Downtown Auto Rentals', '123 Main Street', 'New York', 'NY', '10001', '212-555-0101', 'downtown@vrdbms.com', 'John Smith'),
('Airport Branch', '456 Airport Road', 'Los Angeles', 'CA', '90001', '310-555-0102', 'airport@vrdbms.com', 'Sarah Johnson'),
('Suburban Rentals', '789 Oak Avenue', 'Chicago', 'IL', '60601', '312-555-0103', 'suburban@vrdbms.com', 'Michael Brown'),
('Beachside Motors', '321 Beach Boulevard', 'Miami', 'FL', '33101', '305-555-0104', 'beachside@vrdbms.com', 'Emily Davis'),
('Mountain View Rentals', '654 Highland Drive', 'Denver', 'CO', '80201', '720-555-0105', 'mountainview@vrdbms.com', 'David Wilson');

INSERT INTO vehicle_category (category_name, description, daily_rate, seating_capacity) VALUES
('Economy', 'Fuel-efficient compact cars for budget-conscious travelers', 35.00, 5),
('Compact', 'Small cars perfect for city driving', 45.00, 5),
('Mid-Size', 'Comfortable sedans with ample space', 60.00, 5),
('Full-Size', 'Spacious sedans for long trips', 75.00, 5),
('SUV', 'Sport utility vehicles for families and adventure', 95.00, 7),
('Luxury', 'Premium vehicles with high-end features', 150.00, 5),
('Van', 'Large passenger vans for groups', 120.00, 12),
('Truck', 'Pickup trucks for cargo and towing', 85.00, 5),
('Convertible', 'Open-top vehicles for scenic drives', 110.00, 4),
('Electric', 'Eco-friendly electric vehicles', 70.00, 5);

INSERT INTO vehicle (category_id, branch_id, make, model, year, license_plate, vin, color, mileage, status) VALUES
(1, 1, 'Toyota', 'Corolla', 2023, 'ABC1234', '1HGBH41JXMN109186', 'Silver', 15000, 'available'),
(2, 1, 'Honda', 'Civic', 2023, 'XYZ5678', '2HGFA1F59FH543210', 'Blue', 12000, 'available'),
(3, 1, 'Toyota', 'Camry', 2022, 'DEF9012', '4T1BF1FK3CU123456', 'White', 25000, 'available'),
(4, 1, 'Nissan', 'Altima', 2023, 'GHI3456', 'JN1AZ4EH9FM345678', 'Black', 18000, 'rented'),
(6, 1, 'BMW', '5 Series', 2024, 'LUX1111', 'WBAJE5C52FCG12345', 'Gray', 5000, 'available'),
(1, 2, 'Hyundai', 'Elantra', 2023, 'LAX1234', 'KMHDH4AE3EU123456', 'Red', 10000, 'available'),
(5, 2, 'Ford', 'Explorer', 2023, 'LAX5678', '1FM5K7D84FGB12345', 'Blue', 20000, 'available'),
(5, 2, 'Jeep', 'Grand Cherokee', 2022, 'LAX9012', '1C4RJFAG0FC123456', 'Green', 30000, 'maintenance'),
(7, 2, 'Toyota', 'Sienna', 2023, 'VAN1234', '5TDKZ3DC0FS123456', 'Silver', 15000, 'available'),
(10, 2, 'Tesla', 'Model 3', 2024, 'EV12345', '5YJ3E1EA8LF123456', 'White', 8000, 'available'),
(2, 3, 'Mazda', 'Mazda3', 2023, 'CHI1234', 'JM1BN1U76F1123456', 'Gray', 14000, 'available'),
(3, 3, 'Honda', 'Accord', 2022, 'CHI5678', '1HGCV1F39MA123456', 'Black', 22000, 'available'),
(4, 3, 'Chevrolet', 'Malibu', 2023, 'CHI9012', '1G1ZD5ST0MF123456', 'White', 16000, 'rented'),
(8, 3, 'Ford', 'F-150', 2023, 'TRK1234', '1FTEW1E53NFB12345', 'Red', 25000, 'available'),
(9, 3, 'Mazda', 'MX-5 Miata', 2023, 'CONV123', 'JM1NDAD76N0123456', 'Red', 5000, 'available'),
(1, 4, 'Kia', 'Forte', 2023, 'MIA1234', 'KNAFX5A87N5123456', 'Blue', 11000, 'available'),
(5, 4, 'Honda', 'Pilot', 2023, 'MIA5678', '5FNYF6H59MB123456', 'Silver', 19000, 'available'),
(6, 4, 'Mercedes-Benz', 'C-Class', 2024, 'LUX2222', 'WDDWF4GB8PR123456', 'Black', 3000, 'available'),
(9, 4, 'Ford', 'Mustang Convertible', 2023, 'CONV456', '1FATP8UH9N5123456', 'Yellow', 7000, 'available'),
(10, 4, 'Nissan', 'Leaf', 2023, 'EV67890', '1N4BZ1CPXPC123456', 'White', 6000, 'available'),
(5, 5, 'Toyota', '4Runner', 2023, 'DEN1234', 'JTEBU5JR5M5123456', 'Silver', 21000, 'available'),
(5, 5, 'Subaru', 'Outback', 2023, 'DEN5678', '4S4BTAFC3P3123456', 'Green', 17000, 'available'),
(8, 5, 'Chevrolet', 'Silverado', 2022, 'TRK5678', '3GCUYDED4NG123456', 'Blue', 28000, 'available'),
(3, 5, 'Subaru', 'Legacy', 2023, 'DEN9012', '4S3BWAC63P3123456', 'Gray', 13000, 'available'),
(6, 5, 'Audi', 'A6', 2024, 'LUX3333', 'WAUFFAFC3PN123456', 'White', 4000, 'available');

INSERT INTO customer (first_name, last_name, email, phone, license_number, address, city, state, zip_code, date_of_birth) VALUES
('James', 'Anderson', 'james.anderson@email.com', '555-0201', 'DL123456789', '100 Maple St', 'New York', 'NY', '10002', '1985-03-15'),
('Maria', 'Garcia', 'maria.garcia@email.com', '555-0202', 'DL234567890', '200 Pine St', 'Los Angeles', 'CA', '90002', '1990-07-22'),
('Robert', 'Martinez', 'robert.martinez@email.com', '555-0203', 'DL345678901', '300 Elm St', 'Chicago', 'IL', '60602', '1988-11-08'),
('Jennifer', 'Rodriguez', 'jennifer.rodriguez@email.com', '555-0204', 'DL456789012', '400 Cedar St', 'Miami', 'FL', '33102', '1992-01-30'),
('William', 'Lee', 'william.lee@email.com', '555-0205', 'DL567890123', '500 Birch St', 'Denver', 'CO', '80202', '1987-05-12'),
('Linda', 'Taylor', 'linda.taylor@email.com', '555-0206', 'DL678901234', '600 Spruce St', 'New York', 'NY', '10003', '1995-09-18'),
('Michael', 'Thomas', 'michael.thomas@email.com', '555-0207', 'DL789012345', '700 Willow St', 'Los Angeles', 'CA', '90003', '1983-12-25'),
('Elizabeth', 'White', 'elizabeth.white@email.com', '555-0208', 'DL890123456', '800 Ash St', 'Chicago', 'IL', '60603', '1991-04-07'),
('David', 'Harris', 'david.harris@email.com', '555-0209', 'DL901234567', '900 Cherry St', 'Miami', 'FL', '33103', '1989-08-14'),
('Sarah', 'Clark', 'sarah.clark@email.com', '555-0210', 'DL012345678', '1000 Walnut St', 'Denver', 'CO', '80203', '1994-02-28'),
('Christopher', 'Lewis', 'chris.lewis@email.com', '555-0211', 'DL112345678', '1100 Oak Lane', 'New York', 'NY', '10004', '1986-06-10'),
('Jessica', 'Walker', 'jessica.walker@email.com', '555-0212', 'DL212345678', '1200 Maple Ave', 'Los Angeles', 'CA', '90004', '1993-10-05'),
('Daniel', 'Hall', 'daniel.hall@email.com', '555-0213', 'DL312345678', '1300 Pine Road', 'Chicago', 'IL', '60604', '1984-03-20'),
('Amanda', 'Allen', 'amanda.allen@email.com', '555-0214', 'DL412345678', '1400 Elm Drive', 'Miami', 'FL', '33104', '1996-07-15'),
('Matthew', 'Young', 'matthew.young@email.com', '555-0215', 'DL512345678', '1500 Cedar Court', 'Denver', 'CO', '80204', '1990-11-22');

INSERT INTO employee (branch_id, first_name, last_name, email, phone, position, hire_date, salary) VALUES
(1, 'Tom', 'Wilson', 'tom.wilson@vrdbms.com', '555-1001', 'Sales Agent', '2022-01-15', 45000.00),
(1, 'Lisa', 'Moore', 'lisa.moore@vrdbms.com', '555-1002', 'Customer Service', '2022-03-20', 42000.00),
(2, 'Kevin', 'Taylor', 'kevin.taylor@vrdbms.com', '555-1003', 'Sales Agent', '2021-06-10', 47000.00),
(2, 'Rachel', 'Anderson', 'rachel.anderson@vrdbms.com', '555-1004', 'Maintenance Coordinator', '2021-09-05', 50000.00),
(3, 'Brian', 'Jackson', 'brian.jackson@vrdbms.com', '555-1005', 'Sales Agent', '2022-02-12', 46000.00),
(3, 'Nicole', 'White', 'nicole.white@vrdbms.com', '555-1006', 'Customer Service', '2022-05-18', 43000.00),
(4, 'Steven', 'Harris', 'steven.harris@vrdbms.com', '555-1007', 'Sales Agent', '2021-08-22', 48000.00),
(4, 'Michelle', 'Martin', 'michelle.martin@vrdbms.com', '555-1008', 'Sales Agent', '2022-04-30', 45000.00),
(5, 'Jason', 'Thompson', 'jason.thompson@vrdbms.com', '555-1009', 'Sales Agent', '2021-11-15', 46000.00),
(5, 'Angela', 'Garcia', 'angela.garcia@vrdbms.com', '555-1010', 'Customer Service', '2022-01-28', 44000.00);

INSERT INTO rental (customer_id, vehicle_id, branch_id, employee_id, rental_date, start_date, end_date, return_date, start_mileage, end_mileage, daily_rate, status) VALUES
(1, 1, 1, 1, '2024-11-01', '2024-11-01', '2024-11-05', '2024-11-05', 15000, 15250, 35.00, 'completed'),
(2, 7, 2, 3, '2024-11-03', '2024-11-03', '2024-11-10', '2024-11-10', 20000, 20850, 95.00, 'completed'),
(3, 11, 3, 5, '2024-11-05', '2024-11-05', '2024-11-08', '2024-11-08', 14000, 14180, 45.00, 'completed'),
(4, 16, 4, 7, '2024-11-07', '2024-11-07', '2024-11-14', '2024-11-14', 11000, 11920, 35.00, 'completed'),
(5, 21, 5, 9, '2024-11-10', '2024-11-10', '2024-11-15', '2024-11-15', 21000, 21600, 95.00, 'completed'),
(6, 2, 1, 2, '2024-11-12', '2024-11-12', '2024-11-16', '2024-11-16', 12000, 12320, 45.00, 'completed'),
(7, 9, 2, 4, '2024-11-14', '2024-11-14', '2024-11-21', '2024-11-21', 15000, 15700, 120.00, 'completed'),
(8, 12, 3, 6, '2024-11-16', '2024-11-16', '2024-11-20', '2024-11-20', 22000, 22280, 60.00, 'completed'),
(9, 17, 4, 8, '2024-11-18', '2024-11-18', '2024-11-25', '2024-11-25', 19000, 19850, 95.00, 'completed'),
(10, 22, 5, 10, '2024-11-20', '2024-11-20', '2024-11-24', '2024-11-24', 17000, 17480, 95.00, 'completed'),
(11, 4, 1, 1, '2024-11-25', '2024-11-25', '2024-12-05', NULL, 18000, NULL, 75.00, 'active'),
(12, 13, 3, 5, '2024-11-26', '2024-11-26', '2024-12-03', NULL, 16000, NULL, 75.00, 'active'),
(13, 3, 1, 2, '2024-12-01', '2024-12-05', '2024-12-10', NULL, 25000, NULL, 60.00, 'pending'),
(14, 14, 3, 6, '2024-12-01', '2024-12-06', '2024-12-13', NULL, 25000, NULL, 85.00, 'pending'),
(15, 23, 5, 9, '2024-12-02', '2024-12-08', '2024-12-15', NULL, 13000, NULL, 60.00, 'pending');

INSERT INTO payment (rental_id, payment_date, amount, payment_method, transaction_id) VALUES
(1, '2024-11-05', 140.00, 'credit_card', 'TXN001234567'),
(2, '2024-11-10', 665.00, 'credit_card', 'TXN001234568'),
(3, '2024-11-08', 135.00, 'debit_card', 'TXN001234569'),
(4, '2024-11-14', 245.00, 'cash', NULL),
(5, '2024-11-15', 475.00, 'credit_card', 'TXN001234570'),
(6, '2024-11-16', 180.00, 'online', 'TXN001234571'),
(7, '2024-11-21', 840.00, 'credit_card', 'TXN001234572'),
(8, '2024-11-20', 240.00, 'debit_card', 'TXN001234573'),
(9, '2024-11-25', 665.00, 'credit_card', 'TXN001234574'),
(10, '2024-11-24', 380.00, 'online', 'TXN001234575'),
(11, '2024-11-25', 300.00, 'credit_card', 'TXN001234576'),
(12, '2024-11-26', 200.00, 'debit_card', 'TXN001234577');

INSERT INTO maintenance (vehicle_id, maintenance_type, maintenance_date, description, cost, performed_by, next_service_date) VALUES
(1, 'routine', '2024-10-15', 'Oil change and tire rotation', 85.00, 'Auto Service Center', '2025-01-15'),
(2, 'routine', '2024-10-20', 'Standard maintenance service', 95.00, 'Honda Service', '2025-01-20'),
(3, 'inspection', '2024-09-30', 'Annual safety inspection', 50.00, 'State Inspection Station', '2025-09-30'),
(4, 'repair', '2024-11-01', 'Brake pad replacement', 320.00, 'Brake Specialists Inc', NULL),
(5, 'routine', '2024-11-05', 'Premium oil change and filter', 150.00, 'BMW Service Center', '2025-02-05'),
(6, 'routine', '2024-10-25', 'Oil change and inspection', 80.00, 'Quick Lube', '2025-01-25'),
(7, 'routine', '2024-11-10', 'Full service maintenance', 180.00, 'Ford Dealership', '2025-02-10'),
(8, 'emergency', '2024-11-12', 'Transmission repair', 1250.00, 'Jeep Service Center', '2024-12-12'),
(9, 'routine', '2024-10-28', 'Oil change and tire check', 110.00, 'Toyota Service', '2025-01-28'),
(10, 'inspection', '2024-11-08', 'Battery and electrical system check', 75.00, 'Tesla Service Center', '2025-02-08'),
(11, 'routine', '2024-10-18', 'Standard service', 88.00, 'Mazda Service', '2025-01-18'),
(12, 'repair', '2024-11-15', 'Air conditioning repair', 450.00, 'AC Repair Shop', NULL),
(13, 'routine', '2024-11-18', 'Oil change', 92.00, 'Chevrolet Service', '2025-02-18'),
(14, 'routine', '2024-10-22', 'Standard maintenance', 95.00, 'Ford Service', '2025-01-22'),
(15, 'inspection', '2024-11-01', 'Pre-winter inspection', 65.00, 'Mazda Service', '2025-05-01'),
(16, 'routine', '2024-10-30', 'Oil change and filter', 78.00, 'Kia Service Center', '2025-01-30'),
(17, 'routine', '2024-11-20', 'Full service', 165.00, 'Honda Dealership', '2025-02-20'),
(18, 'routine', '2024-11-12', 'Premium service', 280.00, 'Mercedes-Benz Service', '2025-02-12'),
(19, 'inspection', '2024-11-05', 'Convertible top inspection', 120.00, 'Convertible Specialists', '2025-05-05'),
(20, 'routine', '2024-11-10', 'Battery check and software update', 95.00, 'Nissan EV Center', '2025-02-10'),
(21, 'routine', '2024-11-22', 'Full maintenance service', 195.00, 'Toyota 4x4 Service', '2025-02-22'),
(22, 'routine', '2024-11-15', 'All-wheel drive service', 175.00, 'Subaru Service', '2025-02-15'),
(23, 'repair', '2024-11-08', 'Headlight replacement', 385.00, 'Chevrolet Parts & Service', NULL),
(24, 'routine', '2024-11-18', 'Standard service', 165.00, 'Subaru Dealership', '2025-02-18'),
(25, 'routine', '2024-11-25', 'Premium maintenance', 295.00, 'Audi Service Center', '2025-02-25');
