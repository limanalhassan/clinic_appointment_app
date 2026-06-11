import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


def _appointment_time(dt):
    return dt.strftime('%A, %b %d @ %I:%M %p')


def _time_only(dt):
    return dt.strftime('%I:%M %p')


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def send_booking_notifications(self, appointment_id):
    from .models import Appointment
    from .notifications import send_email, send_sms

    try:
        appt = (
            Appointment.objects
            .select_related('patient__user', 'doctor__user')
            .get(id=appointment_id)
        )
    except Appointment.DoesNotExist:
        logger.warning("Appointment %s not found for booking notification", appointment_id)
        return

    patient_name = appt.patient.user.get_full_name() or appt.patient.user.username
    doctor_name = appt.doctor.user.get_full_name() or appt.doctor.user.username
    appt_time = _appointment_time(appt.scheduled_at)
    notes = appt.notes.strip() if appt.notes.strip() else "No additional comments"

    doctor_msg = (
        f"{patient_name} has booked an appointment with you on {appt_time}. "
        f'Their comment is: "{notes}"'
    )
    patient_msg = (
        f"You have booked an appointment with Dr {doctor_name} on {appt_time}. "
        f"We have notified them of this appointment."
    )

    try:
        send_email(appt.doctor.user.email, "New Appointment Booked", doctor_msg)
        send_sms(appt.doctor.phone, doctor_msg)
        send_email(appt.patient.user.email, "Appointment Confirmed", patient_msg)
        send_sms(appt.patient.phone, patient_msg)
        logger.info("Booking notifications sent for appointment %s", appointment_id)
    except Exception as exc:
        raise self.retry(exc=exc)


REMINDER_CONTENT = {
    '1day': {
        'subject': 'Appointment Reminder — Tomorrow',
        'patient': lambda doctor_name, appt_time: (
            f"You have an appointment tomorrow with Dr {doctor_name} at {appt_time}."
        ),
        'doctor': lambda patient_name, appt_time: (
            f"You have an appointment tomorrow with {patient_name} at {appt_time}."
        ),
    },
    '2hr': {
        'subject': 'Appointment Reminder — 2 Hours',
        'patient': lambda doctor_name, appt_time: (
            f"Your appointment with Dr {doctor_name} is in 2 hours at {appt_time}."
        ),
        'doctor': lambda patient_name, appt_time: (
            f"Your appointment with {patient_name} is in 2 hours at {appt_time}."
        ),
    },
    '30min': {
        'subject': 'Appointment Reminder — 30 Minutes',
        'patient': lambda doctor_name, appt_time: (
            f"Don't forget your appointment with Dr {doctor_name} today @ {appt_time}."
        ),
        'doctor': lambda patient_name, appt_time: (
            f"Don't forget your appointment with {patient_name} today @ {appt_time}."
        ),
    },
}

REMINDER_FLAG = {
    '1day': 'reminder_1day_sent',
    '2hr': 'reminder_2hr_sent',
    '30min': 'reminder_30min_sent',
}


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def send_reminder_notifications(self, appointment_id, reminder_type):
    from .models import Appointment
    from .notifications import send_email, send_sms

    try:
        appt = (
            Appointment.objects
            .select_related('patient__user', 'doctor__user')
            .get(id=appointment_id, status=Appointment.Status.SCHEDULED)
        )
    except Appointment.DoesNotExist:
        logger.warning("Appointment %s not found or not scheduled, skipping reminder", appointment_id)
        return

    patient_name = appt.patient.user.get_full_name() or appt.patient.user.username
    doctor_name = appt.doctor.user.get_full_name() or appt.doctor.user.username
    appt_time = _time_only(appt.scheduled_at)
    content = REMINDER_CONTENT[reminder_type]

    patient_msg = content['patient'](doctor_name, appt_time)
    doctor_msg = content['doctor'](patient_name, appt_time)
    subject = content['subject']

    try:
        send_email(appt.patient.user.email, subject, patient_msg)
        send_sms(appt.patient.phone, patient_msg)
        send_email(appt.doctor.user.email, subject, doctor_msg)
        send_sms(appt.doctor.phone, doctor_msg)

        flag = REMINDER_FLAG[reminder_type]
        setattr(appt, flag, True)
        appt.save(update_fields=[flag])

        logger.info("Reminder (%s) sent for appointment %s", reminder_type, appointment_id)
    except Exception as exc:
        raise self.retry(exc=exc)


@shared_task
def dispatch_reminders():
    from .models import Appointment

    now = timezone.now()

    windows = [
        {
            'type': '1day',
            'start': now + timedelta(hours=23, minutes=45),
            'end': now + timedelta(hours=24, minutes=15),
            'flag': 'reminder_1day_sent',
        },
        {
            'type': '2hr',
            'start': now + timedelta(hours=1, minutes=45),
            'end': now + timedelta(hours=2, minutes=15),
            'flag': 'reminder_2hr_sent',
        },
        {
            'type': '30min',
            'start': now + timedelta(minutes=15),
            'end': now + timedelta(minutes=45),
            'flag': 'reminder_30min_sent',
        },
    ]

    total = 0
    for window in windows:
        ids = (
            Appointment.objects
            .filter(
                status=Appointment.Status.SCHEDULED,
                scheduled_at__gte=window['start'],
                scheduled_at__lte=window['end'],
                **{window['flag']: False},
            )
            .values_list('id', flat=True)
        )
        for appt_id in ids:
            send_reminder_notifications.delay(appt_id, window['type'])
            total += 1

    logger.info("Dispatched %d reminders across all windows", total)
    return total
