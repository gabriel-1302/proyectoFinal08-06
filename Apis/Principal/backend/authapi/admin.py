from django.contrib import admin

# Register your models here.
from django.contrib import admin
from .models import UserProfile , Vehicle, Infraccion

admin.site.register(UserProfile)
admin.site.register(Vehicle)
admin.site.register(Infraccion)
