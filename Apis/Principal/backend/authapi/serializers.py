from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, Vehicle

class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username')
    email = serializers.EmailField(source='user.email')
    first_name = serializers.CharField(source='user.first_name')
    last_name = serializers.CharField(source='user.last_name')

    class Meta:
        model = UserProfile
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'role',
            'telefono',
            'ci',
            'direccion',
            'fecha_nacimiento'
        ]
        read_only_fields = ['id', 'username']

class VehicleSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user_profile.user.username', read_only=True)

    class Meta:
        model = Vehicle
        fields = ['id', 'marca', 'modelo', 'color', 'placa', 'username']  # Reemplaza año por placa
        read_only_fields = ['id', 'username']
        
        
    
#modificacion del 07/06/2025 
from rest_framework import serializers
from .models import Infraccion

from rest_framework import serializers
from .models import Infraccion

class InfraccionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Infraccion
        fields = ['id', 'placa', 'latitud', 'longitud', 'fecha_hora', 'usuario', 'pagado']
        read_only_fields = ['id', 'fecha_hora', 'usuario', 'pagado']
    
    def update(self, instance, validated_data):
        # Imprimir para debugging
        print(f"Datos validados para actualizar: {validated_data}")
        
        # Actualizar manualmente el campo pagado
        if 'pagado' in validated_data:
            instance.pagado = validated_data['pagado']
            print(f"Actualizando pagado a: {validated_data['pagado']}")
        
        # Actualizar otros campos excepto usuario si no queremos que se cambie
        for attr, value in validated_data.items():
            if attr != 'usuario':  # No actualizar usuario
                setattr(instance, attr, value)
        
        instance.save()
        print(f"Instancia guardada, pagado ahora es: {instance.pagado}")
        return instance