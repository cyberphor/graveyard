"""Tests definitions for the login service."""

from django.contrib.auth.models import User
from django.test import RequestFactory
from django.test import TestCase
from datetime import timedelta
from unittest.mock import patch
from ..settings import SIMPLE_JWT
from ..login.tests import unittest_private_key
from ..login.tests import unittest_public_key
from ..login.views import MyTokenObtainPairView


# test the "MyTokenObtainPairView" class
class MyTokenObtainPairViewTest(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        # add some bogus credentials to a temporary database so we can test authentication
        self.user = User.objects.create_user(
            username="buzz", password="2infinity&beyond"
        )

    # test the "post" method of the "MyTokenObtainPairView" class
    def test_post(self):
        # create a mock of the SIMPLE_JWT dict
        mock_SIMPLE_JWT = {
            "ALGORITHM": "RS256",
            "SIGNING_KEY": unittest_private_key,
            "VERIFYING_KEY": unittest_public_key,
            "ACCESS_TOKEN_LIFETIME": timedelta(hours=3),
        }
        # patch the original SIMPLE_JWT dict with the mock above
        # if "clear=True", the SIMPLE_JWT original will be cleared before it's new values are set
        with patch.dict(SIMPLE_JWT, mock_SIMPLE_JWT, clear=True):
            # simulate a HTTP request similar to below:
            #   curl -H 'Content-Type: application/json' -d '{"username":"admin", "password":"asdasd" }' -X POST http://4.156.66.247/v1/logintoken
            request = self.factory.post(
                path="api/token/",
                data={"username": "buzz", "password": "2infinity&beyond"},
            )
            response = MyTokenObtainPairView.as_view()(request)
            self.assertEqual(response.status_code, 200)
