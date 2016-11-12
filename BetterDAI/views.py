from django.shortcuts import render
from django.shortcuts import render_to_response
from django.http import HttpResponseRedirect
from django.contrib import auth
# from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_exempt


# Create your views here.



def index(request):
    return render('index.html');
