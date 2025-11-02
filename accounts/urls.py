from django.urls import path
from .views import UserProfileUpdateView

urlpatterns = [
    path('profile/update/', UserProfileUpdateView.as_view(), name='profile-update'),
]