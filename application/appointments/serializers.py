from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Appointment, Doctor, Patient


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']


class PatientSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Patient
        fields = ['id', 'user', 'phone', 'date_of_birth', 'created_at']


class DoctorSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Doctor
        fields = ['id', 'user', 'specialty', 'bio', 'created_at']


class AppointmentSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    doctor = DoctorSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset=Patient.objects.all(),
        source='patient',
        write_only=True,
    )
    doctor_id = serializers.PrimaryKeyRelatedField(
        queryset=Doctor.objects.all(),
        source='doctor',
        write_only=True,
    )

    class Meta:
        model = Appointment
        fields = [
            'id', 'patient', 'doctor', 'patient_id', 'doctor_id',
            'scheduled_at', 'status', 'notes',
            'reminder_1day_sent', 'reminder_2hr_sent', 'reminder_30min_sent',
            'created_at',
        ]
        read_only_fields = ['reminder_1day_sent', 'reminder_2hr_sent', 'reminder_30min_sent', 'created_at']

    def validate_scheduled_at(self, value):
        from django.utils import timezone
        if value <= timezone.now():
            raise serializers.ValidationError("Appointment must be scheduled in the future.")
        return value
