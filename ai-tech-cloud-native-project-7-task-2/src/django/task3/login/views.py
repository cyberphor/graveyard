"""Login Views."""

import jwt
from rest_framework import permissions, status, viewsets
from rest_framework.response import Response
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
)

from django.contrib.auth.models import User
from task3.login.serializers import UserSerializer
from task3.settings import SIMPLE_JWT


class UserViewSet(viewsets.ModelViewSet):
    """API endpoint that allows users to be viewed or edited."""

    queryset = User.objects.all().order_by("-date_joined")
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]


class MyTokenObtainPairView(TokenObtainPairView):
    """Simple Token View."""

    def post(self, request: str, *args, **kwargs):
        """Edits the post request to make it usable with KrakenD.

        Args:
            request (str): Request input
            *args: Unused.
            **kwargs: Unused.

        Raises:
            InvalidToken: Error thrown is Token is invalid.


        Returns:
            Response: Some response object.
        """
        serializer = self.get_serializer(data=request.data)

        try:
            serializer.is_valid(raise_exception=True)
        except TokenError as e:  # pragma: no cover
            raise InvalidToken(e.args[0])

        # re-write the access token to make KrakenD happy.
        def add_kid_header(mat: str):
            """Add docstr to mat.

            Args:
                mat (str): Encoded headers.

            Returns:
                jwt: Encoded new jwt.
            """
            payload = jwt.decode(mat, SIMPLE_JWT["VERIFYING_KEY"], algorithms=["RS256"])
            return jwt.encode(
                payload,
                SIMPLE_JWT["SIGNING_KEY"],
                algorithm="RS256",
                headers={"kid": "yourcoolkid"},
            )

        serializer.validated_data["access"] = add_kid_header(
            serializer.validated_data["access"],
        )
        serializer.validated_data["refresh"] = add_kid_header(
            serializer.validated_data["refresh"],
        )

        return Response(serializer.validated_data, status=status.HTTP_200_OK)
