from django.db import models

from django.db import models

class Infraction(models.Model):
    mensaje = models.CharField(max_length=255)
    timestamp = models.DateTimeField(auto_now_add=True)
    image = models.ImageField(upload_to='infractions/', blank=True, null=True)

    def __str__(self):
        return f"{self.timestamp}: {self.mensaje}"
    
class Parqueo(models.Model):
    descripcion = models.CharField(max_length=255)
    latitud_uno = models.FloatField()
    longitud_uno = models.FloatField()
    latitud_dos = models.FloatField()
    longitud_dos = models.FloatField()
    espacio_disponible = models.IntegerField()

    def __str__(self):
        return f"{self.descripcion}: {self.espacio_disponible} spaces"