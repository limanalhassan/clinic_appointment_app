FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=clinic.settings.production

RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --chown=app:app . .

RUN SECRET_KEY=build-only \
    DATABASE_URL=sqlite:////tmp/build.db \
    CELERY_BROKER_URL=sqs:// \
    SQS_QUEUE_NAME=build \
    DJANGO_SETTINGS_MODULE=clinic.settings.base \
    python manage.py collectstatic --noinput

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')"

CMD ["gunicorn", "clinic.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "60"]
