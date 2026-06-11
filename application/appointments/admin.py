from django import forms
from django.contrib import admin
from django.contrib.auth.models import User

from .models import Appointment, Doctor, Patient


class PatientAdminForm(forms.ModelForm):
    first_name = forms.CharField(max_length=150)
    last_name = forms.CharField(max_length=150)
    email = forms.EmailField(required=False)

    class Meta:
        model = Patient
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            self.fields['first_name'].initial = self.instance.user.first_name
            self.fields['last_name'].initial = self.instance.user.last_name
            self.fields['email'].initial = self.instance.user.email

    def save(self, commit=True):
        instance = super().save(commit=False)
        instance.user.first_name = self.cleaned_data['first_name']
        instance.user.last_name = self.cleaned_data['last_name']
        instance.user.email = self.cleaned_data['email']
        instance.user.save()
        if commit:
            instance.save()
        return instance


class DoctorAdminForm(forms.ModelForm):
    first_name = forms.CharField(max_length=150)
    last_name = forms.CharField(max_length=150)
    email = forms.EmailField(required=False)

    class Meta:
        model = Doctor
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            self.fields['first_name'].initial = self.instance.user.first_name
            self.fields['last_name'].initial = self.instance.user.last_name
            self.fields['email'].initial = self.instance.user.email

    def save(self, commit=True):
        instance = super().save(commit=False)
        instance.user.first_name = self.cleaned_data['first_name']
        instance.user.last_name = self.cleaned_data['last_name']
        instance.user.email = self.cleaned_data['email']
        instance.user.save()
        if commit:
            instance.save()
        return instance


@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    form = PatientAdminForm
    list_display = ['full_name', 'phone', 'date_of_birth', 'created_at']
    search_fields = ['user__first_name', 'user__last_name', 'user__email', 'phone']
    fields = ['user', 'first_name', 'last_name', 'email', 'phone', 'date_of_birth']

    def full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    full_name.short_description = 'Name'


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    form = DoctorAdminForm
    list_display = ['full_name', 'specialty', 'created_at']
    search_fields = ['user__first_name', 'user__last_name', 'specialty']
    fields = ['user', 'first_name', 'last_name', 'email', 'phone', 'specialty', 'bio']

    def full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    full_name.short_description = 'Name'


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ['patient', 'doctor', 'scheduled_at', 'status', 'reminder_1day_sent', 'reminder_2hr_sent', 'reminder_30min_sent']
    list_filter = ['status', 'reminder_1day_sent', 'reminder_2hr_sent', 'reminder_30min_sent']
    search_fields = ['patient__user__last_name', 'doctor__user__last_name']
