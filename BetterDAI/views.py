from django.shortcuts import render
from django.shortcuts import render_to_response
from django.http import HttpResponseRedirect
from django.contrib import auth
# from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_exempt

import os
import sys
# Create your views here.
from django.conf.urls import include, url
from django.contrib import admin


def index(request):
    return render(request, 'index.html');
