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


def processForm(request):
    encounter_id = request.POST.get('encounter_id', '')
    patient_num = request.POST.get('patient_num', '')
    race =  request.POST.get('race', '')
    gender = request.POST.get('gender', '')
    age = request.POST.get('age', '')
    admission_type = request.POST.get('weight', '')
    discharge_postition = request.POST.get('discharge_position', '')
    admission_type = request.POST.get('admission_type', '')
    discharge_dispostition = request.POST.get('discharge_disposition', '')
    admission_source = request.POST.get('admission_source', '')
    time_in_hospital = request.POST.get('time_in_hospital', '')
    payer_code = request.POST.get('payer_code', '')
    medical_specialty = request.POST.get('medical_specialty', '')
    num_of_outpatient_visits = request.POST.get('num_of_outpatient_visits', '')
    num_of_emergency_visits = request.POST.get('num_of_emergency_visits' '')
    num_of_impatient_visits = request.POST.get('num_of_impatient_visits', '')
    diagnosis_1 = request.POST.get('diagnosis_1', '')
    diagnosis_2 =  request.POST.get('diagnosis_2', '')
    diagnosis_3 = request.POST.get('diagnosis_3', '')
    name_of_diagnosis = request.POST.get('name_of_diagnosis', '')
    gluc_ser_test_res = request.POST.get('gluc_ser_test_res', '')
    alc_test_result = request.POST.get('alc_test_result', '')
    features_of_med = request.POST.get('features_of_med', '')
    change_of_med = request.POST.get('change_of_med', '')
    diabetes_med = request.POST.get('diabetes_med', '')

    return HttpResponseRedirect('works')
