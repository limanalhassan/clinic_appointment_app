from .base import *

DEBUG = True
ALLOWED_HOSTS = ['*']


REST_FRAMEWORK = {
    **REST_FRAMEWORK,
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
}

CELERY_BROKER_TRANSPORT_OPTIONS = {
    'region': env('AWS_DEFAULT_REGION', default='us-east-1'),
    'endpoint_url': env('SQS_ENDPOINT_URL', default='http://localstack:4566'),
    'predefined_queues': {
        env('SQS_QUEUE_NAME', default='clinic-tasks'): {
            'url': '{endpoint}/000000000000/{queue}'.format(
                endpoint=env('SQS_ENDPOINT_URL', default='http://localstack:4566'),
                queue=env('SQS_QUEUE_NAME', default='clinic-tasks'),
            ),
        },
    },
}
