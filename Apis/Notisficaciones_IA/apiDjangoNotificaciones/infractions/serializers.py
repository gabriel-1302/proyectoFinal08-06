from rest_framework import serializers
from .models import Infraction
from rest_framework import serializers
from .models import Infraction
from rest_framework import serializers
from .models import Infraction, Parqueo

class InfractionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Infraction
        fields = ['id', 'mensaje', 'timestamp', 'image']
        
class ParqueoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Parqueo
        fields = ['id', 'descripcion', 'latitud_uno', 'longitud_uno', 'latitud_dos', 'longitud_dos', 'espacio_disponible']