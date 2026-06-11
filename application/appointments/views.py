from datetime import timedelta

from django.contrib.auth.mixins import LoginRequiredMixin
from django.core.paginator import Paginator
from django.shortcuts import redirect
from django.utils import timezone
from django.views import View
from django.views.generic import TemplateView
from rest_framework import permissions, viewsets

from .models import Appointment, Doctor, Patient
from .serializers import AppointmentSerializer, DoctorSerializer, PatientSerializer


def scoped_appointments(user):
    """Return appointments the user is allowed to see based on their role."""
    qs = Appointment.objects.select_related('patient__user', 'doctor__user')
    if user.is_staff:
        return qs.all()
    try:
        return qs.filter(patient=user.patient_profile)
    except Patient.DoesNotExist:
        pass
    try:
        return qs.filter(doctor=user.doctor_profile)
    except Doctor.DoesNotExist:
        pass
    return qs.none()


class DashboardView(LoginRequiredMixin, TemplateView):
    template_name = 'appointments/dashboard.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        user = self.request.user
        now = timezone.now()
        base_qs = scoped_appointments(user)

        if user.is_staff:
            ctx['total_patients'] = Patient.objects.count()
            ctx['total_doctors'] = Doctor.objects.count()
        else:
            ctx['total_patients'] = None
            ctx['total_doctors'] = None

        ctx['scheduled_count'] = base_qs.filter(status=Appointment.Status.SCHEDULED).count()
        ctx['completed_count'] = base_qs.filter(status=Appointment.Status.COMPLETED).count()
        from django.db.models import Q
        ctx['reminders_sent'] = base_qs.filter(
            Q(reminder_1day_sent=True) | Q(reminder_2hr_sent=True) | Q(reminder_30min_sent=True)
        ).count()
        ctx['upcoming_appointments'] = (
            base_qs
            .filter(scheduled_at__gte=now, scheduled_at__lte=now + timedelta(days=7))
            .order_by('scheduled_at')[:10]
        )
        return ctx


class AppointmentListHTMLView(LoginRequiredMixin, TemplateView):
    template_name = 'appointments/appointment_list.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        status_filter = self.request.GET.get('status', '')
        qs = scoped_appointments(self.request.user).order_by('scheduled_at')
        if status_filter:
            qs = qs.filter(status=status_filter)
        paginator = Paginator(qs, 20)
        ctx['appointments'] = paginator.get_page(self.request.GET.get('page'))
        ctx['status_choices'] = Appointment.Status.choices
        ctx['current_status'] = status_filter
        return ctx


class PatientListHTMLView(LoginRequiredMixin, TemplateView):
    template_name = 'appointments/patient_list.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        paginator = Paginator(Patient.objects.select_related('user').order_by('user__last_name'), 20)
        ctx['patients'] = paginator.get_page(self.request.GET.get('page'))
        return ctx


class DoctorListHTMLView(LoginRequiredMixin, TemplateView):
    template_name = 'appointments/doctor_list.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        paginator = Paginator(Doctor.objects.select_related('user').order_by('specialty'), 20)
        ctx['doctors'] = paginator.get_page(self.request.GET.get('page'))
        return ctx


class BookAppointmentView(LoginRequiredMixin, View):
    template_name = 'appointments/book_appointment.html'

    def _get_patient(self):
        try:
            return self.request.user.patient_profile
        except Patient.DoesNotExist:
            return None

    def get(self, request):
        from django.shortcuts import render
        return render(request, self.template_name, {
            'patient': self._get_patient(),
            'doctors': Doctor.objects.select_related('user').order_by('specialty'),
        })

    def post(self, request):
        from django.shortcuts import render
        patient = self._get_patient()
        if not patient:
            return redirect('appointment-list-html')

        doctor_id = request.POST.get('doctor_id')
        scheduled_at = request.POST.get('scheduled_at')
        notes = request.POST.get('notes', '')

        try:
            doctor = Doctor.objects.get(id=doctor_id)
            from django.utils.dateparse import parse_datetime
            scheduled_dt = timezone.make_aware(parse_datetime(scheduled_at))
            if scheduled_dt <= timezone.now():
                raise ValueError("Appointment must be in the future.")
            Appointment.objects.create(
                patient=patient,
                doctor=doctor,
                scheduled_at=scheduled_dt,
                notes=notes,
            )
            return redirect('appointment-list-html')
        except Exception as exc:
            return render(request, self.template_name, {
                'patient': patient,
                'doctors': Doctor.objects.select_related('user').order_by('specialty'),
                'error': str(exc),
            })


class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.select_related('user').all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]


class DoctorViewSet(viewsets.ModelViewSet):
    queryset = Doctor.objects.select_related('user').all()
    serializer_class = DoctorSerializer
    permission_classes = [permissions.IsAuthenticated]


class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.select_related('patient__user', 'doctor__user').all()
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        status = self.request.query_params.get('status')
        if status:
            qs = qs.filter(status=status)
        return qs
