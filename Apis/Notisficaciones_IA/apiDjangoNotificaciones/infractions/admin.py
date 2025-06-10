from django.contrib import admin
from django.utils.html import format_html
from .models import Infraction, Parqueo

@admin.register(Infraction)
class InfractionAdmin(admin.ModelAdmin):
    list_display = ('mensaje', 'timestamp', 'image_thumbnail')
    list_filter = ('timestamp',)
    search_fields = ('mensaje',)
    readonly_fields = ('timestamp', 'image_preview')

    def image_thumbnail(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 50px;"/>', obj.image.url)
        return "-"
    image_thumbnail.short_description = "Imagen"

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 200px;"/>', obj.image.url)
        return "-"
    image_preview.short_description = "Previsualización"

    fieldsets = (
        (None, {
            'fields': ('mensaje', 'image', 'timestamp', 'image_preview')
        }),
    )

@admin.register(Parqueo)
class ParqueoAdmin(admin.ModelAdmin):
    list_display = ('descripcion', 'espacio_disponible', 'latitud_uno', 'longitud_uno', 'latitud_dos', 'longitud_dos')
    list_filter = ('espacio_disponible',)
    search_fields = ('descripcion',)
    fieldsets = (
        (None, {
            'fields': ('descripcion', 'latitud_uno', 'longitud_uno', 'latitud_dos', 'longitud_dos', 'espacio_disponible')
        }),
    )