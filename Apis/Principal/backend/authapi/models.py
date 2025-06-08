from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('ciudadano', 'Ciudadano'),
        ('policia', 'Policía'),
    ]
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='ciudadano')
    telefono = models.CharField(max_length=20, blank=True)
    ci = models.CharField(max_length=30, blank=True)
    direccion = models.CharField(max_length=255, blank=True)
    fecha_nacimiento = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} - {self.role}"

class Vehicle(models.Model):
    user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='vehicles')
    marca = models.CharField(max_length=50)
    modelo = models.CharField(max_length=50)
    color = models.CharField(max_length=30)
    placa = models.CharField(max_length=20, default="SIN_PLACA")  # Reemplaza año por placa

    def __str__(self):
        return f"{self.marca} {self.modelo} ({self.user_profile.user.username})"
    
#modificacion del 07/06/2025 
class Infraccion(models.Model):
    placa = models.CharField(max_length=20)
    latitud = models.FloatField()
    longitud = models.FloatField()
    fecha_hora = models.DateTimeField(auto_now_add=True)
    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    pagado = models.BooleanField(default=False)  # Nuevo campo

    def __str__(self):
        return f"Infracción {self.id} - Placa: {self.placa}"