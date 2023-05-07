from django.http import HttpResponse
from django.views import View
from django.views.generic import ListView
from django.views.generic.base import TemplateView
from django.views.generic.edit import CreateView, DeleteView, UpdateView
from django.urls import reverse_lazy

from .models import Aircraft, Assignment, Booking, Employee, Flight, Passenger
from airportx.models import Airport
from .forms import FlightFormCreate, FlightFormUpdate, EmployeeForm

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
        df = pd.read_csv("airlinex/airport_codes.csv",
                         index_col=0, low_memory=False)
        drop_list = ["type", "elevation_ft", "continent", "iso_country",
                     "iso_region", "municipality", "gps_code", "iata_code", "coordinates"]
        df.drop(drop_list, axis=1, inplace=True)
        df.reset_index(inplace=True, drop=True)
        # print(df.head(), df.shape)

        Airport.objects.all().delete()

        # Add Number of Airports
        desired_airport_count = 5
        if desired_airport_count > Airport.objects.all().count():
            for i in range(desired_airport_count):
                name = df.iloc[i]["name"]
                # Not a ICAO code but sufficient for this purpose
                code = str(df.iloc[i]["local_code"])[:4]
                Airport(name=name, icao_code=code).save()

        explanation = Airport.objects.filter(
            name="Epps Airpark").explain(verbose=True, analyze=True)
        # print(explanation)
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

    def get_context_data(self, **kwargs):
        "Extend the context for template rendering to incorporate additional info using advanced SQL queries."

        context = super().get_context_data(**kwargs)

        # In comparison with the documentation, we added the id here as required for handling with Django
        top_hours_pilot_query = """
        SELECT e.id, e.first_name, e.last_name, SUM(EXTRACT(epoch FROM (f.arrival_time - f.departure_time)) / 3600.0) AS total_hours
        FROM airlinex_employee e
        JOIN airlinex_assignment a ON a.employee_id = e.id
        JOIN airlinex_flight f ON f.number = a.flight_id
        WHERE e.role = 'C'
        GROUP BY e.id
        ORDER BY total_hours DESC
        LIMIT 1;
        """

        try:
            top_hours_pilot = list(Employee.objects.raw(top_hours_pilot_query))
            context['top_hours_pilot_id'] = top_hours_pilot[0].id
        except Exception:
            # Django will throw an error if there are not captains, so the query does not return anything
            pass


        top_flights_pilot_query = """
        SELECT e.id, (e.first_name ||' '|| e.last_name) as "Name", 
        (SELECT COUNT(a2.id) FROM airlinex_assignment a2 WHERE a2.employee_id = e.id) as "Number of flights"
        FROM airlinex_employee as e
        WHERE e.role IN ('C', 'FO', 'SO')
        ORDER BY "Number of flights" DESC
        LIMIT 1;
        """

        try:
            top_flights_pilot = list(Employee.objects.raw(top_flights_pilot_query))
            context['top_flights_pilot_id'] = top_flights_pilot[0].id
        except Exception:
            # Django will throw an error if there are not captains, so the query does not return anything
            pass

        return context


class EmployeeCreateView(CreateView):
    model = Employee
    fields = ['first_name', 'last_name', 'email', 'role', 'based_in', 'spouse']
    success_url = reverse_lazy('Employees')

    def form_valid(self, form):
        "Extend form validation to handle employee spouse attribute on creation."

        response = super().form_valid(form)

        # If the employee has a spouse and the spouse has a different spouse, update the spouse's spouse field
        # Also set the spouse field of the spouse's spouse to none.
        if self.object.spouse and self.object.spouse.spouse != self.object:
            # If the new spouse has another spouse already, reset the spouse attribute of the new spouse's spouse
            self.object.spouse.spouse = self.object
            self.object.spouse.save()

        return response


class EmployeeUpdateView(UpdateView):
    model = Employee
    success_url = reverse_lazy('Employees')
    form_class = EmployeeForm

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs['current_employee'] = self.object
        return kwargs

    def form_valid(self, form):
        "Extend employee form validation to handle updates of the spouse attribute."

        response = super().form_valid(form)

        # In case the spouse is updated to a new one, we want to remove the currently employee from the former spouse first.
        # Handle case of divorce: New spouse is set to None.
        if (hasattr(self.object, 'spouse_of') and self.object.spouse != self.object.spouse_of) | (hasattr(self.object, 'spouse_of') and not self.object.spouse):
            old_spouse = Employee.objects.get(pk=self.object.spouse_of.pk)
            old_spouse.spouse = None
            old_spouse.save()

        # If the employee has a spouse and the spouse has a different spouse, update the spouse's spouse field
        # Also set the spouse field of the spouse's spouse to none.
        if self.object.spouse and self.object.spouse.spouse != self.object:
            # If the new spouse has another spouse already, reset the spouse attribute of the new spouse's spouse
            self.object.spouse.spouse = self.object
            self.object.spouse.save()

        # If the spouse is also an employee and has a different spouse, update the spouse's spouse field
        if hasattr(self.object, 'spouse_of') and self.object.spouse_of.spouse != self.object:
            spouse_of = self.object.spouse_of
            spouse_of.spouse.spouse = None
            spouse_of.spouse = self.object
            spouse_of.save()

        return response


class EmployeeDeleteView(DeleteView):
    model = Employee
    success_url = reverse_lazy('Employees')


# Flights
class FlightListView(ListView):
    model = Flight


class FlightsCreateView(CreateView):
    model = Flight
    form_class = FlightFormCreate
    success_url = reverse_lazy('Flights')


class FlightsUpdateView(UpdateView):
    model = Flight
    form_class = FlightFormUpdate
    success_url = reverse_lazy('Flights')


class FlightsDeleteView(DeleteView):
    model = Flight
    success_url = reverse_lazy('Flights')


# Passenger
class PassengerListView(ListView):
    model = Passenger

    def get_context_data(self, **kwargs):
        "Extend the context for template rendering to incorporate additional info using advanced SQL queries."

        context = super().get_context_data(**kwargs)

        # In comparison with the documentation, we added the id here as required for handling with Django
        all_time_passenger_query = """
        SELECT distinct p.id, p.first_name, p.last_name
        FROM airlinex_booking b
        INNER JOIN airlinex_passenger p ON b.passenger_id = p.id
        WHERE p.status = 'P'
        AND NOT EXISTS (
            SELECT 1 
            FROM airlinex_flight f 
            WHERE NOT EXISTS (
                SELECT 1 
                FROM airlinex_booking b2 
                WHERE b2.flight_id = f.number 
                AND b2.passenger_id = p.id
            )
        );
        """

        try:
            all_time_passenger = list(Passenger.objects.raw(all_time_passenger_query))
            context['all_time_passenger_id'] = all_time_passenger[0].id
        except Exception:
            # Django will throw an error if there are not passengers booked on all flights, so the query does not return anything.
            pass


        return context


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
