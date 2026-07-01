from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class UserProfileUpdateViewTestCase(APITestCase):
    def setUp(self):
        self.url = reverse("profile-update")
        self.user_password = "strongpassword123"
        self.user = User.objects.create_user(
            username="testuser",
            email="testuser@example.com",
            password=self.user_password,
            first_name="Test",
            last_name="User",
        )

    def test_unauthenticated_user_cannot_update_profile(self):
        response = self.client.patch(self.url, {"first_name": "NewName"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_can_update_profile_fields(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.patch(
            self.url, {"first_name": "UpdatedFirst", "last_name": "UpdatedLast"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Reload user from DB
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "UpdatedFirst")
        self.assertEqual(self.user.last_name, "UpdatedLast")

    def test_user_can_change_password(self):
        self.client.force_authenticate(user=self.user)
        new_password = "newstrongpassword456"
        response = self.client.patch(
            self.url, {"password": new_password, "password_confirm": new_password}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify old password no longer works
        self.assertFalse(self.user.check_password(self.user_password))

        # Reload user from DB and verify new password works
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password(new_password))

    def test_password_change_validation_fails_on_mismatch(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.patch(
            self.url, {"password": "newpassword1", "password_confirm": "newpassword2"}
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        # Parse JSON from fully rendered response content
        json_data = response.json()
        self.assertFalse(json_data["status"])
        self.assertIn("password", json_data["errors"])


from django.db import IntegrityError
from rest_framework.exceptions import ValidationError

from config.exception_handler import custom_exception_handler


class CustomExceptionHandlerTestCase(APITestCase):
    def test_drf_standard_exception_is_handled(self):
        # We raise a DRF ValidationError and verify the central handler captures it
        exc = ValidationError({"field": ["Some field error"]})
        response = custom_exception_handler(exc, {})
        self.assertIsNotNone(response)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("field", response.data)

    def test_database_integrity_error_returns_409_conflict(self):
        # Raise standard IntegrityError
        exc = IntegrityError("UNIQUE CONSTRAINT failed: accounts_user.username")
        response = custom_exception_handler(exc, {})
        self.assertIsNotNone(response)
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(response.data["detail"], "Database constraint violation or conflict.")

    def test_generic_python_exception_returns_500_server_error(self):
        # Raise generic python exception
        exc = ValueError("Fatal conversion error")
        response = custom_exception_handler(exc, {})
        self.assertIsNotNone(response)
        self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        self.assertIn("A server error occurred", response.data["detail"])
