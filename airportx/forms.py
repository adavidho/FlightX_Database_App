from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from django import forms
from .models import Airport

class AirportUpdateForm(forms.ModelForm):
    class Meta:
        model = Airport
        fields = ['icao_code', 'name']
        
    def clean_name(self):
        name = self.cleaned_data['name']
        if any(char in name for char in ['ä', 'ö', 'ü', 'Ä', 'Ö', 'Ü']):
            raise ValidationError(_('Umlaut characters are not allowed.'))
        return name