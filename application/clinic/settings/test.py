from .local import *

CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

EMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'
SMS_BACKEND = 'console'
