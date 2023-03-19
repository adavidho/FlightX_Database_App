from django.db import models


class Airport(models.Model):
    """
    A class used to represent airports.

    Attributes
    ----------
    icao_code : str
        the unique 4 character airport code assigned by the ICAO (International Civial Aviation Organization)
    name : str
        the publicly used name of the airport
    """

    icao_code = models.CharField(
        "Unique ICAO airport code", max_length=4, primary_key=True)
    name = models.CharField("Airport name", max_length=100, db_index=True)

    def __str__(self) -> str:
        return f"{self.name} ({self.icao_code})"


class Runway(models.Model):
    """
    A class used to represent runways.

    Attributes
    ----------
    length : int
        the usable length of the runway
    name : str
        the name of the runway consisting of the direction (e.g. 07 for 070 degrees) and perhaps the position (e.g. L for Left)
    airport : str
        the reference to the corresponding airport (being the icao_code of the airport)
    """

    length = models.IntegerField("Runway length")
    name = models.CharField("Runway name", max_length=4)
    airport = models.ForeignKey(Airport, on_delete=models.CASCADE)

    def __str__(self) -> str:
        return f"Runway {self.name} at {self.airport}"


# Materialized View
class AirportEmployees(models.Model):
    """
    A class used to represent the materialized view.
    This is used to retrieve airport statistics including the number of employees.

    Attributes
    ----------
    icao_code : str
        the unique 4 character airport code assigned by the ICAO (International Civial Aviation Organization)
    name : str
        the publicly used name of the airport
    num_employees : int
        the number of employees based on an airport
    """

    icao_code = models.CharField(
        "Unique ICAO airport code", max_length=4, primary_key=True)
    name = models.CharField("Airport name", max_length=100, db_index=True)
    num_employees = models.IntegerField("Number of Employees")

    class Meta:
        managed = False
        db_table = 'airport_and_based_crew'

    def __str__(self):
        return f"The Airport \"{self.name}\" is the base for {self.num_employees} Employees"


# Simple View
class AirportStats(models.Model):
    """
    A class used to represent the normal view.
    This is used to retrieve airport statistics including.

    Attributes
    ----------
    icao_code : str
        the unique 4 character airport code assigned by the ICAO (International Civial Aviation Organization)
    name : float
        the average delay of flights arriving or departing from the specified airport
    num_flights : int
        the number of flights that are arriving or departing from the specified airport
    num_passengers : int
        the number of passengers that are arriving or departing from the specified airport
    """

    icao_code = models.CharField(
        "Unique ICAO airport code", max_length=4, primary_key=True)
    avg_delay = models.FloatField("Average Delay")
    num_flights = models.IntegerField("Number of Flights")
    num_passengers = models.IntegerField("Number of Passengers")

    class Meta:
        managed = False
        db_table = 'airport_stats'

    def __str__(self):
        return f"ICAO: {self.icao_code}, Delay: {self.average_delay}, Flights: {self.number_flights}"
