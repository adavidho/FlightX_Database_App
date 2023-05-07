# flightx_app
Database Project for university

The aviation management software suite FlightX, serves as common ground flight management for airlines and airports. Its two components are AirportX (supporting the management of large aviation facilities) and AirlineX (used for flight management).
- FlightX needs an ICAO (International Civil Aviation Organization) code to uniquely identify each managed airport. Additionally a human readable airport name has to be stored for a better user experience.
    - Each Airport can have multiple runways assigned, that have a certain length and a name (e.g. 07C). As they are only uniquely identifiable through the name in combination with the airport code, this is a weak entity type.
- To track individual aircraft, the software has to keep track of each aircraft’s unique registration, its series type (A380-800, A350-800, A350-900, A350-1000, A320-100, A320-200, A320neo, B777-200, B777-300, B787-8, B787-9, B747-400, B747- 8I, B737-MAX10) and the available passenger capacity.
- Each passenger is described by their first and last name, their status (Bronze, Silver, Gold, Platinum) and optionally a short note with additional information. An artificial ID uniquely identifies each customer.
- Each employee is described by their first and last name, their employee email address and their role (Captain, First Officer, Second Officer, Cabin Crew). An artificial ID uniquely identifies each employee. In addition to that, each employee has a base where he is stationed (one of the airports).
    - For better employee management the system also stores marital relations between coworkers if existent (One-to-One)
- To manage flights, the software has to keep track of the flight number which uniquely identifies each flight, the departure airport, the destination airport, the aircraft, departure time, arrival time, potential delay time as well as whether the flight has been canceled or not.
    - A cancellation should be automatically applied to the corresponding bookings. Additionally, the employees that work on any given flight must be known (Trigger and Procedure) so that their assignments can be deleted from the database.
    - An employee can be assigned to multiple flights through an assignment consisting of the employee ID and the unique flight number (Many-to-Many).
- The bookings are uniquely identified by flight and a passenger and are therefor a weak entity. Bookings also contain a timestamp from when the booking was made and the cancellation status.
