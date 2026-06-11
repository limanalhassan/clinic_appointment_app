from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AppointmentViewSet, DoctorViewSet, PatientViewSet

router = DefaultRouter()
router.register('patients', PatientViewSet)
router.register('doctors', DoctorViewSet)
router.register('appointments', AppointmentViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
