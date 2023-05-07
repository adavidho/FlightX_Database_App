-- Materialized view: number of employees based at Airport
CREATE MATERIALIZED VIEW airport_and_based_crew 
AS SELECT airportx_airport.*, COUNT(airlinex_employee.based_in_id) AS num_employees
FROM airportx_airport
LEFT JOIN airlinex_employee ON airportx_airport.icao_code = airlinex_employee.based_in_id
GROUP BY airportx_airport.icao_code;

-- View: incomming flights for each airport
-- CREATE OR REPLACE VIEW airport_stats AS
-- SELECT 
--   airportx_airport.icao_code, 
--   AVG(airlinex_flight.delay) AS average_delay, 
--   COUNT(airlinex_flight.number) AS number_flights, 
--   COUNT(airlinex_booking.id) AS number_bookings 
-- FROM 
--   airportx_airport 
--   JOIN airlinex_flight 
--   ON airportx_airport.icao_code = airlinex_flight.departure_airport_id 
--   OR airportx_airport.icao_code = airlinex_flight.destination_airport_id
-- GROUP BY 
--   airportx_airport.icao_code;

-- View: incomming flights for each airport
CREATE OR REPLACE VIEW airport_stats AS
SELECT 
  airportx_airport.icao_code, 
  AVG(airlinex_flight.delay) AS average_delay, 
  COUNT(airlinex_flight.number) AS number_flights 
FROM 
  airportx_airport 
  JOIN airlinex_flight 
  ON airportx_airport.icao_code = airlinex_flight.departure_airport_id 
  OR airportx_airport.icao_code = airlinex_flight.destination_airport_id
GROUP BY 
  airportx_airport.icao_code;