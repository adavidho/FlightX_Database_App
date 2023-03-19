"""flightx URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from airlinex.views import *
from airportx.views import *

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', StartpageView.as_view(), name='Home'),
    path('startpage/', StartpageView.as_view(), name='Home'),

    path('aircrafts/', AircraftListView.as_view(), name='Aircrafts'),
    path('airport-si-check/', AirportSICheck.as_view(), name='AirportsSICheck'),
    path('aircrafts/add/', AircraftCreateView.as_view(), name='AddAircrafts'),
    path('aircrafts/<slug:pk>/', AircraftUpdateView.as_view(),
         name='UpdateAircrafts'),
    path('aircrafts/<slug:pk>/delete/',
         AircraftDeleteView.as_view(), name='DeleteAircrafts'),

    path('airports/', AirportListView.as_view(), name='Airports'),
    path('airports/add/', AirportCreateView.as_view(), name='AddAirports'),
    path('airports/<slug:pk>/', AirportUpdateView.as_view(), name='UpdateAirports'),
    path('airports/<slug:pk>/delete/',
         AirportDeleteView.as_view(), name='DeleteAirports'),
    path('airports/<slug:pk>/materializedview/',
         AirportDetailView, name='AirportsMView'),

    path('runways/', RunwayListView.as_view(), name='Runways'),
    path('runways/add/', RunwayCreateView.as_view(), name='AddRunways'),
    path('runways/<slug:pk>/', RunwayUpdateView.as_view(), name='UpdateRunways'),
    path('runways/<slug:pk>/delete/',
         RunwayDeleteView.as_view(), name='DeleteRunways'),

    path('assignments/', AssignmentListView.as_view(), name='Assignments'),
    path('assignments/add/', AssignmentCreateView.as_view(), name='AddAssignments'),
    path('assignments/<slug:pk>/', AssignmentUpdateView.as_view(),
         name='UpdateAssignments'),
    path('assignments/<slug:pk>/delete/',
         AssignmentDeleteView.as_view(), name='DeleteAssignments'),

    path('bookings/', BookingListView.as_view(), name='Bookings'),
    path('bookings/add/', BookingCreateView.as_view(), name='AddBookings'),
    path('bookings/<slug:pk>/', BookingUpdateView.as_view(), name='UpdateBookings'),
    path('bookings/<slug:pk>/delete/',
         BookingDeleteView.as_view(), name='DeleteBookings'),

    path('employees/', EmployeeListView.as_view(), name='Employees'),
    path('employees/add/', EmployeeCreateView.as_view(), name='AddEmployees'),
    path('employees/<slug:pk>/', EmployeeUpdateView.as_view(),
         name='UpdateEmployees'),
    path('employees/<slug:pk>/delete/',
         EmployeeDeleteView.as_view(), name='DeleteEmployees'),

    path('flights/', FlightListView.as_view(), name='Flights'),
    path('flights/add/', FlightsCreateView.as_view(), name='AddFlights'),
    path('flights/<slug:pk>/', FlightsUpdateView.as_view(), name='UpdateFlights'),
    path('flights/<slug:pk>/delete/',
         FlightsDeleteView.as_view(), name='DeleteFlights'),

    path('passengers/', PassengerListView.as_view(), name='Passengers'),
    path('passengers/add/', PassengerCreateView.as_view(), name='AddPassengers'),
    path('passengers/<slug:pk>/', PassengerUpdateView.as_view(),
         name='UpdatePassengers'),
    path('passengers/<slug:pk>/delete/',
         PassengerDeleteView.as_view(), name='DeletePassengers'),
]
