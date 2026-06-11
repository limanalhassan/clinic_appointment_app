from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Appointment


@receiver(post_save, sender=Appointment)
def on_appointment_created(sender, instance, created, **kwargs):
    if created:
        from .tasks import send_booking_notifications
        send_booking_notifications.delay(instance.id)
