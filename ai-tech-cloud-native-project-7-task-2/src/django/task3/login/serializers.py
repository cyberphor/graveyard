"""Serializer for User List Route."""

from rest_framework import serializers

from django.contrib.auth.models import User


class UserSerializer(serializers.HyperlinkedModelSerializer):
    """Simple User Serializer."""

    class Meta:
        """Removed some fields of User."""

        model = User
        fields = ["url", "username", "email", "groups"]
