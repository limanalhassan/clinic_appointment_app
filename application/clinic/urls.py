from django.contrib import admin
from django.contrib.auth import views as auth_views
from django.http import JsonResponse
from django.urls import path, include
from django.views.generic import RedirectView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from appointments.views import (
    DashboardView,
    AppointmentListHTMLView,
    BookAppointmentView,
    PatientListHTMLView,
    DoctorListHTMLView,
)


def health_check(request):
    return JsonResponse({'status': 'ok'})


urlpatterns = [
    path('', RedirectView.as_view(url='/dashboard/', permanent=False)),
    path('health/', health_check),
    path('admin/', admin.site.urls),

    path('login/', auth_views.LoginView.as_view(template_name='appointments/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='login'), name='logout'),

    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('appointments-list/', AppointmentListHTMLView.as_view(), name='appointment-list-html'),
    path('appointments/book/', BookAppointmentView.as_view(), name='book-appointment'),
    path('patients/', PatientListHTMLView.as_view(), name='patient-list-html'),
    path('doctors/', DoctorListHTMLView.as_view(), name='doctor-list-html'),

    path('api/token/', TokenObtainPairView.as_view()),
    path('api/token/refresh/', TokenRefreshView.as_view()),
    path('api/', include('appointments.urls')),
]
