-- Stored procedure
CREATE OR REPLACE PROCEDURE cancel_flight(flight_number VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update bookings
  UPDATE airlinex_booking SET cancelled = true WHERE flight_id = flight_number;
  -- Remove crew assignments for the flight
  DELETE FROM airlinex_assignment WHERE flight_id = flight_number;
END;$$;

-- Trigger function to trigger and check for cancellation
CREATE OR REPLACE FUNCTION cancel_flight_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.cancelled THEN
    CALL cancel_flight(NEW.number);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Corresponding trigger
CREATE OR REPLACE TRIGGER cancel_flight_trigger
AFTER UPDATE ON airlinex_flight
FOR EACH ROW
EXECUTE FUNCTION cancel_flight_trigger_function();
