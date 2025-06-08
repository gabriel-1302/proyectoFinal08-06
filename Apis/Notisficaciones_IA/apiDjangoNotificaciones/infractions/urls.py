from rest_framework.routers import DefaultRouter
from .views import InfractionViewSet

router = DefaultRouter()
router.register('infractions', InfractionViewSet, basename='infraction')

urlpatterns = router.urls
