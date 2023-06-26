from backend_starter_app.models import Hat
from rest_framework import serializers


class HatSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Hat
        fields = ['name', 'color']
