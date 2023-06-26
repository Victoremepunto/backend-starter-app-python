from django.db import models


class Hat(models.Model):

    name: models.CharField(max_length=30)
    color: models.CharField(max_length=15)
