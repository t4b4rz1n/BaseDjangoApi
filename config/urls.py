from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
   openapi.Info(
      title="Ali Fathi API",
      default_version='v1',
      description="API documentation for Ali Fathi"
   ),
   public=True,
   permission_classes=[permissions.AllowAny],
)

urlpatterns = [
   path("admin/", admin.site.urls),

   path('api/v1/auth/', include('authentication.urls')),
   path('api/v1/accounts/', include('accounts.urls')),

   re_path(r'^swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
   path('', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
   path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)