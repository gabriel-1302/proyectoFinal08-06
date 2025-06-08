from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from .models import Infraction
from .serializers import InfractionSerializer

class InfractionViewSet(viewsets.ModelViewSet):
    queryset = Infraction.objects.all().order_by('-timestamp')
    serializer_class = InfractionSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        inf = serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)