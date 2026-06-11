import logging
import os

import boto3
from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


def send_email(to_email, subject, body):
    if not to_email:
        logger.warning("Skipping email notification — no address provided")
        return
    send_mail(
        subject=subject,
        message=body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[to_email],
        fail_silently=False,
    )
    logger.info("Email sent to %s: %s", to_email, subject)


def send_sms(phone, message):
    if not phone:
        logger.warning("Skipping SMS notification — no phone number provided")
        return
    if getattr(settings, 'SMS_BACKEND', 'console') == 'console':
        logger.info("SMS to %s: %s", phone, message)
        return
    client = boto3.client('sns', region_name=os.environ.get('AWS_DEFAULT_REGION', 'ca-central-1'))
    client.publish(PhoneNumber=phone, Message=message)
    logger.info("SMS dispatched via SNS to %s", phone)
