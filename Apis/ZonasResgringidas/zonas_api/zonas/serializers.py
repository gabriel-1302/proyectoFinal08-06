from rest_framework import serializers
from .models import ZonaRestringida

class ZonaRestringidaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZonaRestringida
        fields = '__all__'