
from django.db import models

class ZonaRestringida(models.Model):
    coordenada1_lat = models.FloatField()
    coordenada1_lon = models.FloatField()
    coordenada2_lat = models.FloatField()
    coordenada2_lon = models.FloatField()
    
    def __str__(self):
        return f"Zona: ({self.coordenada1_lat}, {self.coordenada1_lon}) - ({self.coordenada2_lat}, {self.coordenada2_lon})"