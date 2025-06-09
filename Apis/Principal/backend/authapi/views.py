from django.contrib.auth import authenticate
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import UserProfile, Vehicle
from .serializers import UserProfileSerializer, VehicleSerializer
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Infraccion, UserProfile
from .serializers import InfraccionSerializer
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from datetime import datetime
from .models import Infraccion
from .serializers import InfraccionSerializer

class LoginView(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            try:
                profile = UserProfile.objects.get(user=user)
                refresh = RefreshToken.for_user(user)
                user_data = {
                    'id': profile.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'role': profile.role,
                    'telefono': profile.telefono,
                    'ci': profile.ci,
                    'direccion': profile.direccion,
                    'fecha_nacimiento': str(profile.fecha_nacimiento) if profile.fecha_nacimiento else None,
                }
                return Response({
                    'token': str(refresh.access_token),
                    'role': profile.role,
                    'user': user_data,
                    'message': 'Inicio de sesión exitoso'
                })
            except UserProfile.DoesNotExist:
                return Response({'message': 'Perfil de usuario no encontrado'}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'message': 'Credenciales inválidas'}, status=status.HTTP_401_UNAUTHORIZED)

class VehicleListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            vehicles = Vehicle.objects.filter(user_profile=request.user.profile)
            serializer = VehicleSerializer(vehicles, many=True)
            return Response(serializer.data)
        except UserProfile.DoesNotExist:
            return Response({'error': 'Perfil de usuario no encontrado'}, status=status.HTTP_400_BAD_REQUEST)

    def post(self, request):
        try:
            serializer = VehicleSerializer(data=request.data)
            if serializer.is_valid():
                # Asignar user_profile del usuario autenticado al guardar
                serializer.save(user_profile=request.user.profile)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except UserProfile.DoesNotExist:
            return Response({'error': 'Perfil de usuario no encontrado'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class VehicleDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, pk):
        try:
            return Vehicle.objects.get(pk=pk, user_profile=request.user.profile)
        except Vehicle.DoesNotExist:
            return None

    def get(self, request, pk):
        vehicle = self.get_object(request, pk)
        if not vehicle:
            return Response({'message': 'Vehículo no encontrado'}, status=status.HTTP_404_NOT_FOUND)
        serializer = VehicleSerializer(vehicle)
        return Response(serializer.data)

    def put(self, request, pk):
        vehicle = self.get_object(request, pk)
        if not vehicle:
            return Response({'message': 'Vehículo no encontrado'}, status=status.HTTP_404_NOT_FOUND)
        serializer = VehicleSerializer(vehicle, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        vehicle = self.get_object(request, pk)
        if not vehicle:
            return Response({'message': 'Vehículo no encontrado'}, status=status.HTTP_404_NOT_FOUND)
        vehicle.delete()
        return Response({'message': 'Vehículo eliminado'}, status=status.HTTP_204_NO_CONTENT)
    
#modificacion del 07/06/2025
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Infraccion, UserProfile
from .serializers import InfraccionSerializer
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Infraccion, UserProfile
from .serializers import InfraccionSerializer
from django.utils import timezone
from django.db.models import Q
from datetime import datetime
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Infraccion, Vehicle
from .serializers import InfraccionSerializer
from datetime import datetime

class InfraccionListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.profile.role == 'ciudadano':
            # Obtener las placas de los vehículos del usuario
            user_vehicles = Vehicle.objects.filter(user_profile=request.user.profile)
            user_plates = user_vehicles.values_list('placa', flat=True)
            # Filtrar infracciones por las placas del usuario y pagado=False
            infracciones = Infraccion.objects.filter(placa__in=user_plates, pagado=False)
            
            # Permitir filtro opcional por fecha
            fecha = request.query_params.get('fecha', None)
            if fecha:
                try:
                    fecha_dt = datetime.strptime(fecha, '%Y-%m-%d').date()
                    infracciones = infracciones.filter(fecha_hora__date=fecha_dt)
                except ValueError:
                    return Response({'message': 'Formato de fecha inválido (use YYYY-MM-DD)'}, status=status.HTTP_400_BAD_REQUEST)
        else:  # Para policías
            infracciones = Infraccion.objects.all()
            
            # Filtro por fecha
            fecha = request.query_params.get('fecha', None)
            if fecha:
                try:
                    fecha_dt = datetime.strptime(fecha, '%Y-%m-%d').date()
                    infracciones = infracciones.filter(fecha_hora__date=fecha_dt)
                except ValueError:
                    return Response({'message': 'Formato de fecha inválido (use YYYY-MM-DD)'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Filtro por pagado
            pagado = request.query_params.get('pagado', None)
            if pagado is not None:
                pagado_bool = pagado.lower() == 'true'
                infracciones = infracciones.filter(pagado=pagado_bool)
            
            # Filtro por placa
            placa = request.query_params.get('placa', None)
            if placa:
                placas_list = placa.split(',')
                infracciones = infracciones.filter(placa__in=placas_list)
        
        serializer = InfraccionSerializer(infracciones, many=True)
        return Response(serializer.data)

    def post(self, request):
        if request.user.profile.role != 'policia':
            return Response({'message': 'Acceso denegado'}, status=status.HTTP_403_FORBIDDEN)
        serializer = InfraccionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(usuario=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    def patch(self, request):
        if request.user.profile.role != 'policia':
            return Response({'message': 'Acceso denegado'}, status=status.HTTP_403_FORBIDDEN)
        
        # Obtener el ID de la infracción a actualizar
        infraccion_id = request.data.get('id')
        if not infraccion_id:
            return Response({'message': 'ID de infracción requerido'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            infraccion = Infraccion.objects.get(id=infraccion_id)
        except Infraccion.DoesNotExist:
            return Response({'message': 'Infracción no encontrada'}, status=status.HTTP_404_NOT_FOUND)
        
        # Agregar logs para debugging
        print(f"ID recibido: {infraccion_id}")
        print(f"Datos recibidos: {request.data}")
        print(f"Estado actual de pagado: {infraccion.pagado}")
        
        # PRUEBA: Actualizar directamente sin serializer
        if 'pagado' in request.data:
            infraccion.pagado = request.data['pagado']
            infraccion.save()
            print(f"Actualización directa - Estado después de guardar: {infraccion.pagado}")
            
            # Recargar desde la base de datos para verificar
            infraccion.refresh_from_db()
            print(f"Estado después de refresh_from_db: {infraccion.pagado}")
            
            # Crear response con serializer
            serializer = InfraccionSerializer(infraccion)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        # Si no hay campo pagado, usar el método normal
        data_to_update = request.data.copy()
        if 'usuario' in data_to_update:
            del data_to_update['usuario']
        
        serializer = InfraccionSerializer(infraccion, data=data_to_update, partial=True)
        if serializer.is_valid():
            serializer.save()
            print(f"Estado después de guardar con serializer: {infraccion.pagado}")
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            print(f"Errores del serializer: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)