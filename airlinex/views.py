from django.db import transaction, connection
from django.http import HttpResponse
from django.views import View
from django.views.generic import ListView
from django.views.generic.base import TemplateView
from django.views.generic.edit import CreateView, DeleteView, UpdateView
from django.urls import reverse_lazy

from .models import Aircraft, Assignment, Booking, Employee, Flight, Passenger
from airportx.models import Airport
from .forms import FlightForm

import pandas as pd

class StartpageView(TemplateView):
    template_name = "base.html"

# Aircraft
class AircraftListView(ListView):
    model = Aircraft

class AircraftCreateView(CreateView):
    model = Aircraft
    fields = ['registration', 'type_series', 'passenger_capacity']
    success_url = reverse_lazy('Aircrafts')

class AircraftUpdateView(UpdateView):
    model = Aircraft
    fields = ['type_series', 'passenger_capacity']
    success_url = reverse_lazy('Aircrafts')

class AircraftDeleteView(DeleteView):
    model = Aircraft
    success_url = reverse_lazy('Aircrafts')   

class AirportSICheck(View):
    def get(self, request):
        """
        Return the DB explain output of filtering for an airport given a certain number of airports in the DB
        to filter from. This was used for the secondary index performance analysis on the airports name attribute.
        """
        
        # Data from: https://datahub.io/core/airport-codes#resource-airport-codes
        df = pd.read_csv("airlinex/airport_codes.csv", index_col=0, low_memory=False)
        drop_list = ["type", "elevation_ft", "continent", "iso_country", "iso_region", "municipality", "gps_code", "iata_code", "coordinates"]
        df.drop(drop_list, axis=1, inplace=True)
        df.reset_index(inplace=True, drop=True)
        print(df.head(), df.shape)
        
        Airport.objects.all().delete()

        # Add Number of Airports
        desired_airport_count = 5
        if desired_airport_count > Airport.objects.all().count():
            for i in range(desired_airport_count):
                name = df.iloc[i]["name"]
                code = str(df.iloc[i]["local_code"])[:4] # Not a ICAO code but sufficient for this purpose
                Airport(name=name, icao_code=code).save()


        explanation = Airport.objects.filter(name="Epps Airpark").explain(verbose=True, analyze=True)
        print(explanation)
        num_airports = Airport.objects.all().count()
        return HttpResponse(f'The explan for lookup out of {num_airports} airports: \n{explanation}')


# Assignment
class AssignmentListView(ListView):
    model = Assignment

class AssignmentCreateView(CreateView):
    model = Assignment
    fields = ['employee', 'flight']
    success_url = reverse_lazy('Assignments')

class AssignmentUpdateView(UpdateView):
    model = Assignment
    fields = ['employee', 'flight']
    success_url = reverse_lazy('Assignments')

class AssignmentDeleteView(DeleteView):
    model = Assignment
    success_url = reverse_lazy('Assignments')  

# Booking
class BookingListView(ListView):
    model = Booking

class BookingCreateView(CreateView):
    model = Booking
    fields = ['flight', 'passenger']
    success_url = reverse_lazy('Bookings')

class BookingUpdateView(UpdateView):
    model = Booking
    fields = ['flight', 'passenger', 'cancelled']
    success_url = reverse_lazy('Bookings')

class BookingDeleteView(DeleteView):
    model = Booking
    success_url = reverse_lazy('Bookings')  

# Employee
class EmployeeListView(ListView):
    model = Employee

class EmployeeCreateView(CreateView):
    model = Employee
    fields = ['first_name', 'last_name', 'email', 'role', 'based_in']
    success_url = reverse_lazy('Employees')

class EmployeeUpdateView(UpdateView):
    model = Employee
    fields = ['first_name', 'last_name', 'email', 'role', 'based_in']
    success_url = reverse_lazy('Employees')

class EmployeeDeleteView(DeleteView):
    model = Employee
    success_url = reverse_lazy('Employees')  
    
# Flights
class FlightListView(ListView):
    model = Flight

class FlightsCreateView(CreateView):
    model = Flight
    form_class = FlightForm
    success_url = reverse_lazy('Flights')

class FlightsUpdateView(UpdateView):
    model = Flight
    form_class = FlightForm
    success_url = reverse_lazy('Flights')

class FlightsDeleteView(DeleteView):
    model = Flight
    success_url = reverse_lazy('Flights')  

# Passenger  
class PassengerListView(ListView):
    model = Passenger

class PassengerCreateView(CreateView):
    model = Passenger
    fields = ['first_name', 'last_name', 'status', 'notes']
    success_url = reverse_lazy('Passengers')

class PassengerUpdateView(UpdateView):
    model = Passenger
    fields = ['first_name', 'last_name', 'status', 'notes']
    success_url = reverse_lazy('Passengers')

class PassengerDeleteView(DeleteView):
    model = Passenger
    success_url = reverse_lazy('Passengers')  