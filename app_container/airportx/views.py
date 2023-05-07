from django.urls import reverse_lazy
from django.db import transaction, connection
from django.shortcuts import get_object_or_404, render
from django.views.generic.edit import CreateView, DeleteView, UpdateView
from airportx.models import Airport, Runway, AirportEmployees, AirportStats
from django.views.generic import ListView


def refresh_materialized():
    with connection.cursor() as cursor:
        cursor.execute("REFRESH MATERIALIZED VIEW airport_and_based_crew;")
        transaction.commit()


# Airport
class AirportListView(ListView):
    model = Airport


class AirportEmployeesListView(ListView):
    model = AirportEmployees


class AirportCreateView(CreateView):
    model = Airport
    fields = ['icao_code', 'name']
    success_url = reverse_lazy('Airports')


class AirportUpdateView(UpdateView):
    model = Airport
    fields = ['name']
    success_url = reverse_lazy('Airports')


class AirportDeleteView(DeleteView):
    model = Airport
    success_url = reverse_lazy('Airports')


def AirportDetailView(request, pk):
    refresh_materialized()
    airport_info = "Number of Employees not available"
    airport_stats = {
        'avg_delay': 0,
        'num_flights': 0,
        'num_passengers': 0,
    }

    runways = Runway.objects.filter(airport=pk)

    try:
        airport_info = get_object_or_404(AirportEmployees, pk=pk)
        airport_stats = get_object_or_404(AirportStats, pk=pk)
    except Exception:
        print('failed to get airport stats')
    return render(
        request,
        'airportx/airportemployees_list.html',
        {'airport_info': airport_info,
            'airport_stats': airport_stats, 'runways': runways}
    )


# Runway
class RunwayListView(ListView):
    model = Runway


class RunwayCreateView(CreateView):
    model = Runway
    fields = ['airport', 'name', 'length']
    success_url = reverse_lazy('Runways')


class RunwayUpdateView(UpdateView):
    model = Runway
    fields = ['name', 'length']
    success_url = reverse_lazy('Runways')


class RunwayDeleteView(DeleteView):
    model = Runway
    success_url = reverse_lazy('Runways')
