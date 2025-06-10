from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from .models import Infraction
from .serializers import InfractionSerializer
from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from .models import Infraction, Parqueo
from .serializers import InfractionSerializer, ParqueoSerializer

class InfractionViewSet(viewsets.ModelViewSet):
    queryset = Infraction.objects.all().order_by('-timestamp')
    serializer_class = InfractionSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        inf = serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
class ParqueoViewSet(viewsets.ModelViewSet):
    queryset = Parqueo.objects.all()
    serializer_class = ParqueoSerializer
    http_method_names = ['get', 'post', 'patch']

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        parqueo = serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        parqueo = serializer.save()
        return Response(serializer.data)