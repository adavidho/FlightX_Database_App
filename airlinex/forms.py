from django import forms
from .models import Flight, Employee


class FlightForm(forms.ModelForm):
    class Meta:
        model = Flight
        fields = ['departure_airport', 'destination_airport', 'aircraft',
                  'departure_time', 'arrival_time', 'delay', 'cancelled']
        widgets = {
            'departure_time': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'arrival_time': forms.DateTimeInput(attrs={'type': 'datetime-local'})
        }


class EmployeeForm(forms.ModelForm):
    """
    Customize the Employee form to exclude the selected employee itself from the potential spouses list.
    """
    
    spouse = forms.ModelChoiceField(
        queryset=Employee.objects.all(), required=False)

    def __init__(self, *args, **kwargs):
        current_employee = kwargs.pop('current_employee', None)
        super().__init__(*args, **kwargs)
        if current_employee:
            self.fields['spouse'].queryset = Employee.objects.exclude(
                pk=current_employee.pk)

    class Meta:
        model = Employee
        fields = ['first_name', 'last_name',
                  'email', 'role', 'based_in', 'spouse']
