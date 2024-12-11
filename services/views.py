from django.db.models import Count

from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from .models import Service, OilChange
from .serializers import ServiceSerializer, UpdateServiceSerializer, OilChangeSerializer, UpdateOilChangeSerializer


class ServiceViewSet(ModelViewSet):
    def get_serializer_class(self):
        if self.request.method == 'PUT':
            return UpdateServiceSerializer
        return ServiceSerializer
    queryset = Service.objects.prefetch_related('oil_change').annotate(
        oil_change_count=Count('oil_change')).all()

    def get_serializer_context(self):
        return {'request': self.request}

    def destroy(self, request, *args, **kwargs):
        if OilChange.objects.filter(service_id=kwargs['pk']).count() > 0:
            return Response({'error': 'Cannot delete service with oil changes'}, status=status.HTTP_400_BAD_REQUEST)
        return super().destroy(request, *args, **kwargs)


class OilChangeViewSet(ModelViewSet):
    def get_serializer_class(self):
        if self.request.method == 'PUT':
            return UpdateOilChangeSerializer
        return OilChangeSerializer

    def get_queryset(self):
        return OilChange.objects.filter(service_id=self.kwargs['service_pk'])

    def get_serializer_context(self):
        return {'request': self.request}