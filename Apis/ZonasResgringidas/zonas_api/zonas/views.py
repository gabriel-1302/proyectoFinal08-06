from rest_framework import viewsets
from .models import ZonaRestringida
from .serializers import ZonaRestringidaSerializer

class ZonaRestringidaViewSet(viewsets.ModelViewSet):
    queryset = ZonaRestringida.objects.all()
    serializer_class = ZonaRestringidaSerializer