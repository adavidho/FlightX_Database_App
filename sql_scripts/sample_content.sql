-- Populates the database with sample content. This corresponds to "Table_DDL_Django_free.sql" and does not populate the DB with application level data.
-- Use the final SQL dump (create_flightx_db.sql) for that.


INSERT INTO airlinex_aircraft (registration, type_series, passenger_capacity) VALUES 
('D-ABYA', 'B748', 364),
('D-AIXP', 'A359', 293);

INSERT INTO airportx_airport (icao_code, name) VALUES 
('EDDF', 'Frankfurt Airport'),
('EDDM', 'Munich Airport'),
('KJFK', 'John F. Kennedy International Airport');

INSERT INTO airportx_runway (length, name, airport_id) VALUES 
(3343, '07L', 'EDDF'),
(3343, '07C', 'EDDF'),
(4231, '18', 'EDDF'),
(2560, '04R', 'KJFK'),
(3682, '04L', 'KJFK'),
(2560, '22L', 'KJFK'),
(3682, '22R', 'KJFK'),
(4231, '36', 'EDDF'),
(3343, '25L', 'EDDF'),
(3343, '25R', 'EDDF');

INSERT INTO airlinex_employee (id, first_name, last_name, email, role, based_in_id, spouse_id) VALUES 
(1, 'Jürgen', 'Raps', 'raps@lufthansa.com', 'C', 'EDDF', null),
(2, 'Joong Gi', 'Joost', 'joost@lufthansa.com', 'FO', 'EDDM', null),
(3, 'Janine', 'Neumann', 'neumann@lufthansa.com', 'CC', 'EDDF', 4),
(4, 'Tobias', 'Reuter', 'treuter@lufthansa.com', 'CC', 'EDDM', 3);

INSERT INTO airlinex_flight (number, departure_time, arrival_time, delay, cancelled, aircraft_id, departure_airport_id, destination_airport_id) VALUES 
('LH470', '2023-02-19 09:10:00+01', '2023-02-19 17:40:00+01', 5, 'f', 'D-AIXP', 'EDDM', 'KJFK'),
('LH480', '2023-02-20 11:12:00+01', '2023-02-20 20:10:00+01', 0, 'f', 'D-ABYA', 'EDDF', 'KJFK'),
('LH440', '2023-02-21 11:15:00+01', '2023-02-21 20:20:00+01', 80, 'f', 'D-AIXP', 'KJFK', 'EDDM');

INSERT INTO airlinex_assignment (employee_id, flight_id) VALUES
(1, 'LH480'),
(2, 'LH480'),
(3, 'LH470'),
(4, 'LH480'),
(3, 'LH480'),
(1, 'LH470'),
(2, 'LH470'),
(4, 'LH470'),
(1, 'LH440');

INSERT INTO airlinex_passenger (id, first_name, last_name, status, notes) VALUES
(1, 'James', 'Bond', 'P', 'Likes his drinks stirred, not shaken.'),
(2, 'Rainer', 'Zufall', 'S', 'Preferes to choose his meals randomly.');

INSERT INTO airlinex_booking ("time", cancelled, flight_id, passenger_id) VALUES
('2023-02-19 15:22:41.408284+01', 'f', 'LH470', 1),
('2023-02-19 15:22:47.910238+01', 'f', 'LH480', 1),
('2023-02-19 15:22:55.240668+01', 'f', 'LH440', 1),
('2023-02-19 15:23:01.765973+01', 'f', 'LH470', 2),
('2023-02-19 15:23:07.689948+01', 'f', 'LH480', 2),
('2023-02-19 15:23:13.392197+01', 'f', 'LH440', 2);
