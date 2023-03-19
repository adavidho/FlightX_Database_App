from django import forms
from .models import Flight

class FlightForm(forms.ModelForm):
    class Meta:
        model = Flight
        fields = ['departure_airport', 'destination_airport', 'aircraft', 'departure_time', 'arrival_time', 'delay', 'cancelled']
        widgets = {
            'departure_time': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'arrival_time': forms.DateTimeInput(attrs={'type': 'datetime-local'})
        }