from datetime import timedelta
from unittest.mock import patch

import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework.test import APIClient

from .models import Appointment, Doctor, Patient
from .tasks import dispatch_reminders, send_booking_notifications, send_reminder_notifications


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(username='testuser', password='testpass', email='test@example.com')


@pytest.fixture
def patient_user(db):
    u = User.objects.create_user(username='patient1', first_name='Jane', last_name='Doe', email='jane@example.com')
    return Patient.objects.create(user=u, phone='555-0100')


@pytest.fixture
def doctor_user(db):
    u = User.objects.create_user(username='doctor1', first_name='Alan', last_name='Smith', email='alan@example.com')
    return Doctor.objects.create(user=u, specialty='General Practice', phone='555-0200')


@pytest.fixture
def appointment(db, patient_user, doctor_user):
    return Appointment.objects.create(
        patient=patient_user,
        doctor=doctor_user,
        scheduled_at=timezone.now() + timedelta(hours=12),
    )


class TestModels:
    def test_patient_str(self, patient_user):
        assert str(patient_user) == 'Jane Doe'

    def test_doctor_str(self, doctor_user):
        assert str(doctor_user) == 'Dr. Alan Smith'

    def test_appointment_defaults(self, appointment):
        assert appointment.status == Appointment.Status.SCHEDULED
        assert appointment.reminder_1day_sent is False
        assert appointment.reminder_2hr_sent is False
        assert appointment.reminder_30min_sent is False
        assert appointment.any_reminder_sent is False


class TestAppointmentAPI:
    def test_list_requires_auth(self, api_client):
        response = api_client.get('/api/appointments/')
        assert response.status_code == 401

    def test_list_appointments(self, api_client, user, appointment):
        api_client.force_authenticate(user=user)
        response = api_client.get('/api/appointments/')
        assert response.status_code == 200
        assert response.data['count'] == 1

    def test_filter_by_status(self, api_client, user, appointment):
        api_client.force_authenticate(user=user)
        response = api_client.get('/api/appointments/?status=scheduled')
        assert response.status_code == 200
        assert response.data['count'] == 1

    def test_create_appointment_in_past_is_rejected(self, api_client, user, patient_user, doctor_user):
        api_client.force_authenticate(user=user)
        response = api_client.post('/api/appointments/', {
            'patient_id': patient_user.id,
            'doctor_id': doctor_user.id,
            'scheduled_at': (timezone.now() - timedelta(hours=1)).isoformat(),
        })
        assert response.status_code == 400


class TestNotificationTasks:
    def test_booking_notifications_sent(self, appointment):
        with patch('appointments.notifications.send_email') as mock_email, \
             patch('appointments.notifications.send_sms') as mock_sms:
            send_booking_notifications(appointment.id)
        assert mock_email.call_count == 2
        assert mock_sms.call_count == 2

    def test_booking_notifications_skips_missing(self, db):
        send_booking_notifications(99999)

    def test_reminder_marks_flag(self, appointment):
        with patch('appointments.notifications.send_email'), \
             patch('appointments.notifications.send_sms'):
            send_reminder_notifications(appointment.id, '1day')
        appointment.refresh_from_db()
        assert appointment.reminder_1day_sent is True
        assert appointment.reminder_2hr_sent is False

    def test_all_reminder_types(self, appointment):
        with patch('appointments.notifications.send_email'), \
             patch('appointments.notifications.send_sms'):
            for reminder_type in ('1day', '2hr', '30min'):
                send_reminder_notifications(appointment.id, reminder_type)
        appointment.refresh_from_db()
        assert appointment.any_reminder_sent is True
        assert appointment.reminder_1day_sent is True
        assert appointment.reminder_2hr_sent is True
        assert appointment.reminder_30min_sent is True

    def test_dispatch_enqueues_correct_window(self, db, patient_user, doctor_user):
        Appointment.objects.create(
            patient=patient_user,
            doctor=doctor_user,
            scheduled_at=timezone.now() + timedelta(hours=24),
        )
        with patch('appointments.tasks.send_reminder_notifications.delay') as mock_delay:
            count = dispatch_reminders()
        assert count == 1
        mock_delay.assert_called_once()
        assert mock_delay.call_args[0][1] == '1day'

    def test_dispatch_skips_already_reminded(self, db, patient_user, doctor_user):
        appt = Appointment.objects.create(
            patient=patient_user,
            doctor=doctor_user,
            scheduled_at=timezone.now() + timedelta(hours=24),
            reminder_1day_sent=True,
        )
        with patch('appointments.tasks.send_reminder_notifications.delay') as mock_delay:
            count = dispatch_reminders()
        assert count == 0
        mock_delay.assert_not_called()
