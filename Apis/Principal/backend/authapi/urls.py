from django.urls import path
from .views import LoginView, VehicleListCreateView, VehicleDetailView
from rest_framework_simplejwt.views import TokenRefreshView
from django.urls import path
from .views import InfraccionListCreateView

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('vehicles/', VehicleListCreateView.as_view(), name='vehicle-list-create'),
    path('vehicles/<int:pk>/', VehicleDetailView.as_view(), name='vehicle-detail'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # Modificación del 07/06/2025
    path('infracciones/', InfraccionListCreateView.as_view(), name='infraccion-list-create'),
]