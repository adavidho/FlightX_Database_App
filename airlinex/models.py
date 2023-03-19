from django.db import models
from airportx.models import Airport


class Aircraft(models.Model):
    """
    A class used to represent an aircrafts

    Attributes
    ----------
    registration : str
        the unique aircraft registration
    type_series : str
        the type of aircraft
    passenger_capacity : int
        number of passengers the aircraft can carry
    """

    # Choices for different Aircraft types
    TYPE_SERIES_CHOICES = [
        ("A388", "A380-800"),
        ("A358", "A350-800"),
        ("A359", "A350-900"),
        ("A3501", "A350-1000"),
        ("A3201", "A320-100"),
        ("A3202", "A320-200"),
        ("A320n", "A320neo"),
        ("B772", "B777-200"),
        ("B773", "B777-300"),
        ("B788", "B787-8"),
        ("B789", "B787-9"),
        ("B744", "B747-400"),
        ("B748", "B747-8I"),
        ("B73710", "B737-MAX10"),
    ]

    # Model Attributes
    registration = models.CharField(
        "Unique aircraft registration", max_length=10, primary_key=True)
    type_series = models.CharField(
        "Aircraft type series", max_length=10, choices=TYPE_SERIES_CHOICES)
    passenger_capacity = models.IntegerField("Number of passenger seats")

    # Class functions
    def __str__(self) -> str:
        return f"{self.get_type_series_display()} ({self.registration})"


class Passenger(models.Model):
    """
    A class used to represent passengers

    Attributes
    ----------
    first_name : str
        the first name of the customer
    last_name : str
        the last name of the customer
    status : str
        the customer status (Bronze, Silver, Gold, Platinum)
    notes : str
        customer specific notes such as preferences
    """

    # Customer status options
    CUSTOMER_STATUS_CHOICES = [
        ("B", "Bronze"),
        ("S", "Silver"),
        ("G", "Gold"),
        ("P", "Platinum"),
    ]

    # Model Attributes
    first_name = models.CharField("First name", max_length=100)
    last_name = models.CharField("Last name", max_length=100, db_index=True)
    status = models.CharField(
        "Customer status", max_length=20, choices=CUSTOMER_STATUS_CHOICES, default="B")
    notes = models.TextField("Extra notes", max_length=2000, blank=True)

    # Class functions
    def __str__(self) -> str:
        return f"{self.first_name} {self.last_name}"


class Employee(models.Model):
    """
    A class used to represent employees

    Attributes
    ----------
    first_name : str
        the first name of the employee
    last_name : str
        the last name of the employee
    email : str
        the employee email address 
    role : str
        the role of the employee 
    based_in : obj
        relationship to the airport (Airport) the employee is based at
    spouse : obj
        relationship to the the spouse (Employee) if applicable
    """

    # Choices for employee role
    EMPLOYEE_ROLE_CHOICES = [
        ("C", "Captain"),
        ("FO", "First Officer"),
        ("SO", "Second Officer"),
        ("CC", "Cabin Crew"),
    ]

    # Model Attributes
    first_name = models.CharField("First name", max_length=100)
    last_name = models.CharField("Last name", max_length=100, db_index=True)
    email = models.EmailField("Employee mail")
    role = models.CharField("Employee role:", max_length=2,
                            choices=EMPLOYEE_ROLE_CHOICES)
    based_in = models.ForeignKey(Airport, on_delete=models.SET_NULL, null=True)
    spouse = models.OneToOneField(
        'self', on_delete=models.SET_NULL, related_name='spouse_of', null=True, blank=True)

    # Class functions
    def __str__(self) -> str:
        return f"{self.first_name} {self.last_name}"


class Flight(models.Model):
    """
    A class used to represent flights

    Attributes
    ----------
    number : str
        the flight number
    departure_airport : obj
        relationship to the departure airport
    destination_airport : obj
        relationship to the destination airport 
    aircraft : obj
        relationship to the aircraft for the flight
    departure_time : obj
        time the aircraft is sceduled to depart the departure_airport
    arrival_time : obj
        time the aircraft is sceduled to arrive at the destination_airport
    delay : int
        the delay of the flight in minutes
    cancelled : bool
        the cancelled status of the flight
    employees : obj
        flight crew as a many to many relationship with Employee through Assignment
    """

    # Model Attributes
    number = models.CharField("Flight number", max_length=10, primary_key=True)
    departure_airport = models.ForeignKey(
        Airport, on_delete=models.CASCADE, related_name="departure_airport")
    destination_airport = models.ForeignKey(
        Airport, on_delete=models.CASCADE, related_name="arrival_airport")
    aircraft = models.ForeignKey(
        Aircraft, on_delete=models.PROTECT, related_name="aircraft")

    departure_time = models.DateTimeField("Departure Date & Time")
    arrival_time = models.DateTimeField("Arrival Date & Time")
    delay = models.PositiveIntegerField("Delay in minutes", default=0)
    cancelled = models.BooleanField("Cancelation status", default=False)

    employees = models.ManyToManyField(Employee, through='Assignment')

    # Class functions
    def get_duration(self) -> int:
        """Return flight duration in minutes"""

        return self.arrival_time - self.departure_time

    def __str__(self) -> str:
        return f"Flight {self.number} from {self.departure_airport} to {self.destination_airport}"


class Assignment(models.Model):
    """
    A class used to represent assignment of employees to flights

    Attributes
    ----------
    employee : obj
        relationship to the employee assigned
    flight : obj
        relationship to the flight the employee was assigned to 
    """

    # Model Attributes 
    # Cannot delete Employee without replacement for assigments
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT)
    flight = models.ForeignKey(Flight, on_delete=models.CASCADE)

    # Class functions
    def __str__(self) -> str:
        return f"Employee {self.employee.first_name} {self.employee.last_name} on flight {self.flight.number}"


class Booking(models.Model):
    """
    A class used to represent flights bookings of passenger

    Attributes
    ----------
    flight : obj
        relationship to the booked flight
    passenger : obj
        relationship to the passenger who booked the flight 
    time : obj
        the time the booking was made
    cancelled : obj
        set to true if the respective flight was cancelled (sql procedure)
    """

    # Model Attributes 
    flight = models.ForeignKey(Flight, on_delete=models.CASCADE)
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE)
    time = models.DateTimeField("Creation time of booking", auto_now_add=True)
    cancelled = models.BooleanField("Cancelation status", default=False)

    # Uniqueness contrains to prevent one customer booking the same flight twice
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['flight', 'passenger'], name='flight_passenger_unique')
        ]

    def __str__(self) -> str:
        return f"Passenger {self.passenger.first_name} {self.passenger.last_name} on flight {self.flight.number}"
