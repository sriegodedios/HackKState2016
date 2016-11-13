from django.shortcuts import render
from django.shortcuts import render_to_response
from django.shortcuts import redirect
from django.http import HttpResponseRedirect
from django.contrib import auth
# from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_exempt
from array import array
import os
import sys
# Create your views here.
from django.conf.urls import include, url
from django.contrib import admin
from django.views.decorators.csrf import csrf_protect
from patient_data.models import Info
from twilio.rest import TwilioRestClient
import csv

import sqlite3





def index(request):

   # return render_to_response('index.html', {'obj': Info.objects.all()})
   # patients = Info.patient_nbr.order_by('name')
    conn = sqlite3.connect('db.sqlite3')

    c = conn.cursor()



    object1 = []




    for row in c.execute('SELECT patient_nbr FROM {tn} LIMIT 100'.format(tn="patient_data_info")):
        object1.append(row)



    return render_to_response('index.html', {'objectp': object1})

    #return render(request, 'index.html');


def patient_connect(request):









    return render(request, 'edit_patient.html')

@csrf_exempt
def processForm(request):
    arr = {}

    encounter_id = request.POST.get('encounter_id', '')
    patient_nbr = request.POST.get('patient_nbr', '')
    race = request.POST.get('race', '')
    gender = request.POST.get('gender', '')
    age = request.POST.get('age', '')
    weight = request.POST.get('weight', '')
    admission_type_id = request.POST.get('admission_type_id', '')
    discharge_disposition_id = request.POST.get('discharge_disposition_id', '')
    admission_source_id = request.POST.get('admission_source_id', '')
    time_in_hospital = request.POST.get('time_in_hospital', '')
    payer_code = request.POST.get('payer_code', '')
    medical_specialty = request.POST.get('medical_specialty', '')
    num_lab_procedures = request.POST.get('num_lab_procedures', '')
    num_procedures = request.POST.get('num_procedures', '')
    num_medications = request.POST.get('num_medications', '')
    number_outpatient = request.POST.get('number_outpatient', '')
    number_emergency = request.POST.get('number_emergency', '')
    number_inpatient = request.POST.get('number_inpatient', '')
    diag_1 = request.POST.get('diag_1', '')
    diag_2 = request.POST.get('diag_2', '')
    diag_3 = request.POST.get('diag_3', '')
    number_diagnoses = request.POST.get('number_diagnoses', '')
    max_glu_serum = request.POST.get('max_glu_serum', '')
    A1Cresult = request.POST.get('A1Cresult', '')
    metformin = request.POST.get('metformin', '')
    repaglinide = request.POST.get('repaglinide', '')
    nateglinide = request.POST.get('nateglinide', '')
    chlorpropamide = request.POST.get('chlorpropamide', '')
    glimepiride = request.POST.get('glimepiride', '')
    acetohexamide = request.POST.get('acetohexamide', '')
    glipizide = request.POST.get('glipizide', '')
    glyburide = request.POST.get('glyburide', '')
    tolbutamide = request.POST.get('tolbutamide', '')
    pioglitazone = request.POST.get('pioglitazone', '')
    rosiglitazone = request.POST.get('rosiglitazone', '')
    acarbose = request.POST.get('acarbose', '')
    miglitol = request.POST.get('miglitol', '')
    troglitazone = request.POST.get('troglitazone', '')
    tolazamide = request.POST.get('tolazamide', '')
    examide = request.POST.get('examide', '')
    citoglipton = request.POST.get('citoglipton', '')
    insulin = request.POST.get('insulin', '')
    glyburidemetformin = request.POST.get('glyburide.metformin', '')
    glipizidemetformin = request.POST.get('glipizide.metformin', '')
    glimepiridepioglitazone = request.POST.get('glimepiride.pioglitazone', '')
    metforminrosiglitazone = request.POST.get('metformin.rosiglitazone', '')
    metforminpioglitazone = request.POST.get('metformin.pioglitazone', '')
    change = request.POST.get('change', '')
    diabetesMed = request.POST.get('diabetesMed', '')
    readmitted = request.POST.get('readmitted', '')






    conn = sqlite3.connect('db.sqlite3')
    cursor = conn.cursor()
    cursor.execute('select * from patient_data_info')
    with open('out.csv', "w") as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow([i[0] for i in cursor.description])
        csv_writer.writerows(cursor)


    sql = 'INSERT INTO patient_data_info (patient_nbr) VALUES(?)'
    cursor.execute(sql, [(patient_nbr)])
    print('done')
    send_sms()



    object1 = []




    for row in cursor.execute('SELECT patient_nbr FROM {tn} LIMIT 100'.format(tn="patient_data_info")):
        object1.append(row)



    return render_to_response('index.html', {'objectp': object1})
    return redirect('http://betterdai.tech')
   # return render(request, 'index.html')





def send_sms():
    # put your own credentials here
    ACCOUNT_SID = "AC4629bd5abeac87277b0af95696ad71c4"
    AUTH_TOKEN = "47a27b0261a843a6f7b7652cf854395b"

    client = TwilioRestClient(ACCOUNT_SID, AUTH_TOKEN)

    client.messages.create(
        to="+16207673336",
        from_="+17855306418",
        body="BetterDAI patient records have been updated.",
    )

@csrf_exempt
def getData(request):

    patient = request.POST.get('patient_selection', '')

    conn = sqlite3.connect('db.sqlite3')
    print(patient)
    c = conn.cursor()

    sql = "SELECT readmitted FROM patient_data_info WHERE patient_nbr=?"
    c.execute(sql, [(patient)])

    value = c.fetchone()
    print(value)
    conn.close()
    boolean = ''

    if "<" in str(value):
        return render(request, 'failed.html', {})
    else:
        return render(request, 'success.html', {})
    #Condition for readmitting (caution)




