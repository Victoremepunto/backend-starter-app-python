from rest_framework import viewsets
from rest_framework import permissions
from backend_starter_app.serializers import HatSerializer
from backend_starter_app.models import Hat


class HatViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = Hat.objects.all().order_by('-name')
    serializer_class = HatSerializer
    permission_classes = [permissions.AllowAny]
