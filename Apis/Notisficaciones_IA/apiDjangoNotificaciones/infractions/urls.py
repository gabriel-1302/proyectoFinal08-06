from rest_framework.routers import DefaultRouter
from .views import InfractionViewSet
from rest_framework.routers import DefaultRouter
from .views import InfractionViewSet, ParqueoViewSet

router = DefaultRouter()
router.register('infractions', InfractionViewSet, basename='infraction')
router.register('parqueos', ParqueoViewSet, basename='parqueo')

urlpatterns = router.urls
